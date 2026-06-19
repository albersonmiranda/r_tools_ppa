#!/bin/bash

set -e
set -o pipefail

die() {
    echo "Error: $1" >&2
    exit 1
}

download_to() {
    local url=$1
    local dest=$2
    local label=$3
    local tmp_file

    echo "Downloading $label from $url..."
    tmp_file=$(mktemp)
    curl -fL -o "$tmp_file" "$url"
    [ -s "$tmp_file" ] || die "Downloaded $label file is empty"
    mv "$tmp_file" "$dest"
}

download_tmp() {
    local url=$1
    local label=$2
    local tmp_file

    echo "Downloading $label from $url..." >&2
    tmp_file=$(mktemp)
    curl -fL -o "$tmp_file" "$url"
    [ -s "$tmp_file" ] || die "Downloaded $label file is empty"
    printf '%s\n' "$tmp_file"
}

for cmd in jq createrepo_c curl grep head rpmbuild gpg rpm; do
    command -v $cmd >/dev/null 2>&1 || { echo >&2 "$cmd is required but not installed. Aborting."; exit 1; }
done

GPG_KEY_ID="albersonmiranda@hotmail.com"

configure_rpm_signing() {
    install -d -m 700 ~/.gnupg

    if [ -n "${GPG_PASSPHRASE:-}" ]; then
        grep -q '^pinentry-mode loopback$' ~/.gnupg/gpg.conf 2>/dev/null \
            || echo "pinentry-mode loopback" >> ~/.gnupg/gpg.conf
        grep -q '^allow-loopback-pinentry$' ~/.gnupg/gpg-agent.conf 2>/dev/null \
            || echo "allow-loopback-pinentry" >> ~/.gnupg/gpg-agent.conf
    fi

    cat > ~/.rpmmacros <<EOF
%_signature gpg
%_gpg_path ${HOME}/.gnupg
%_gpg_name ${GPG_KEY_ID}
EOF

    if [ -n "${GPG_PASSPHRASE:-}" ]; then
        cat >> ~/.rpmmacros <<EOF
%_gpg_sign_cmd_extra_args --batch --no-tty --pinentry-mode loopback --passphrase ${GPG_PASSPHRASE}
EOF
    fi
}

RPM_X86_DIR="rpm/x86_64"
RPM_ARM_DIR="rpm/aarch64"

mkdir -p "$RPM_X86_DIR" "$RPM_ARM_DIR"

echo "Fetching RStudio download URLs..."

RSTUDIO_PAGE=$(curl -fsSL "https://live-rstudio.pantheonsite.io/download/rstudio-desktop/?posit_iframe=1")

RSTUDIO_RPM_URL=$(echo "$RSTUDIO_PAGE" | grep -oE 'https://[^" ]+rhel[0-9]*/x86_64/rstudio-[^" ]+\.rpm' | head -n1)
[ -n "$RSTUDIO_RPM_URL" ] || die "Could not find RStudio x86_64 .rpm URL"

download_to "$RSTUDIO_RPM_URL" "$RPM_X86_DIR/$(basename "$RSTUDIO_RPM_URL")" "RStudio x86_64"

echo "Fetching Quarto release info..."

QUARTO_API="https://api.github.com/repos/quarto-dev/quarto-cli/releases/latest"
QUARTO_VERSION=$(curl -s "$QUARTO_API" | jq -r '.tag_name')
QUARTO_VERSION_NO_V=${QUARTO_VERSION#v}

[ -n "$QUARTO_VERSION" ] || die "Could not read Quarto latest version"

echo "Quarto latest version: $QUARTO_VERSION"

RPMBUILD_ROOT=$(mktemp -d)
mkdir -p "$RPMBUILD_ROOT"/{BUILD,BUILDROOT,RPMS,SOURCES,SPECS,SRPMS}

QUARTO_ARCH="amd64"
RPM_ARCH="x86_64"
QUARTO_TAR="quarto-${QUARTO_VERSION_NO_V}-linux-${QUARTO_ARCH}.tar.gz"
QUARTO_URL="https://github.com/quarto-dev/quarto-cli/releases/download/${QUARTO_VERSION}/${QUARTO_TAR}"
TMP_FILE=$(download_tmp "$QUARTO_URL" "Quarto ${RPM_ARCH} tarball")

cp "$TMP_FILE" "$RPMBUILD_ROOT/SOURCES/$QUARTO_TAR"

cat > "$RPMBUILD_ROOT/SPECS/quarto-${RPM_ARCH}.spec" <<EOF
%global debug_package %{nil}
%global _build_id_links none

Name:           quarto
Version:        ${QUARTO_VERSION_NO_V}
Release:        1%{?dist}
Summary:        An open-source scientific and technical publishing system
License:        GPL-2.0
URL:            https://quarto.org
Source0:        %{name}-%{version}-linux-${QUARTO_ARCH}.tar.gz
BuildArch:      ${RPM_ARCH}
AutoReqProv:    no

%description
Quarto is an open-source scientific and technical publishing system built on Pandoc.

%prep
%setup -q -n quarto-%{version}

%install
mkdir -p %{buildroot}/opt/quarto
cp -r * %{buildroot}/opt/quarto/
mkdir -p %{buildroot}/usr/local/bin
ln -s /opt/quarto/bin/quarto %{buildroot}/usr/local/bin/quarto

%files
/opt/quarto/
/usr/local/bin/quarto

%changelog
* $(date '+%a %b %d %Y') R Tools PPA <albersonmiranda@hotmail.com> - ${QUARTO_VERSION_NO_V}-1
- Updated to ${QUARTO_VERSION}
EOF

echo "Building Quarto RPM for ${RPM_ARCH}..."
rpmbuild --define "_topdir $RPMBUILD_ROOT" --target ${RPM_ARCH} -ba "$RPMBUILD_ROOT/SPECS/quarto-${RPM_ARCH}.spec"

RPM_FILE=$(find "$RPMBUILD_ROOT/RPMS/${RPM_ARCH}/" -name "quarto-*.rpm" | head -1)
[ -f "$RPM_FILE" ] || die "Failed to build Quarto RPM for ${RPM_ARCH}"
cp "$RPM_FILE" "$RPM_X86_DIR/"
rm -f "$TMP_FILE"

rm -rf "$RPMBUILD_ROOT"

echo "Fetching Positron download URLs..."

POSITRON_PAGE=$(curl -s "https://positron.posit.co/download.html")

for ARCH in x86_64 arm64; do
    PATTERN="https://cdn.posit.co/positron/releases/rpm/${ARCH}/Positron-[^\" ]+\.rpm"
    if [ "$ARCH" = "x86_64" ]; then
      DEST_DIR="$RPM_X86_DIR"
    else
      DEST_DIR="$RPM_ARM_DIR"
    fi

    URL=$(echo "$POSITRON_PAGE" | grep -oE "$PATTERN" | head -n1)
    [ -n "$URL" ] || die "Could not find Positron .rpm URL for $ARCH"
    FILE=$(basename "$URL")
    DEST="$DEST_DIR/$FILE"

    download_to "$URL" "$DEST" "Positron .rpm $ARCH"
done

echo "Re-signing RPM packages with repository key..."

configure_rpm_signing
gpg --list-secret-keys "$GPG_KEY_ID" >/dev/null 2>&1 \
    || die "GPG secret key '$GPG_KEY_ID' not found. Import it or set GPG_PRIVATE_KEY in CI."

unset GPG_TTY
rpm --resign "$RPM_X86_DIR"/*.rpm "$RPM_ARM_DIR"/*.rpm

echo "Generating RPM metadata..."

createrepo_c "$RPM_X86_DIR"
createrepo_c "$RPM_ARM_DIR"

echo "All packages downloaded and metadata generated successfully."
