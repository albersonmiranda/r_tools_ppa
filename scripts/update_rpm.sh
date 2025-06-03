#!/bin/bash

set -e
set -o pipefail

# --- Dependency checks ---
for cmd in jq createrepo_c curl grep sort head gzip rpmbuild rpmdev-setuptree; do
    command -v $cmd >/dev/null 2>&1 || { echo >&2 "$cmd is required but not installed. Aborting."; exit 1; }
done

# --- Directories ---
DEB_DIR="deb/pool/main"
RPM_X86_DIR="rpm/x86_64"
RPM_ARM_DIR="rpm/aarch64"

mkdir -p "$DEB_DIR" "$RPM_X86_DIR" "$RPM_ARM_DIR"

# --- RStudio ---
echo "Fetching RStudio download URLs..."

RSTUDIO_PAGE=$(curl -s "https://posit.co/download/rstudio-desktop/")

RSTUDIO_RPM_URL=$(echo "$RSTUDIO_PAGE" | grep -oE 'https://.*rstudio-.*-x86_64.rpm' | head -n1)

echo "Downloading RStudio .rpm x86_64..."
curl -L -o "$RPM_X86_DIR/$(basename $RSTUDIO_RPM_URL)" "$RSTUDIO_RPM_URL"

# --- Quarto ---
echo "Fetching Quarto release info..."

QUARTO_API="https://api.github.com/repos/quarto-dev/quarto-cli/releases/latest"
QUARTO_VERSION=$(curl -s "$QUARTO_API" | jq -r '.tag_name')
QUARTO_VERSION_NO_V=${QUARTO_VERSION#v}

echo "Quarto latest version: $QUARTO_VERSION"

# Create RPM build environment
rpmdev-setuptree

# I removed aarch64 support because I could not build it successfully
for ARCH in "x86_64"; do
    # Map architecture names for Quarto download
    if [ "$ARCH" = "x86_64" ]; then
        QUARTO_ARCH="amd64"
        DEST_DIR="$RPM_X86_DIR"
    else
        QUARTO_ARCH="arm64"
        DEST_DIR="$RPM_ARM_DIR"
    fi
    
    QUARTO_TAR="quarto-${QUARTO_VERSION_NO_V}-linux-${QUARTO_ARCH}.tar.gz"
    URL="https://github.com/quarto-dev/quarto-cli/releases/download/${QUARTO_VERSION}/${QUARTO_TAR}"
    
    echo "Downloading Quarto ${ARCH} tarball from $URL..."
    
    TMP_FILE=$(mktemp)
    curl -fL -o "$TMP_FILE" "$URL"
    if [ ! -s "$TMP_FILE" ]; then
        echo "Error: Downloaded Quarto tarball is empty!"
        exit 1
    fi
    
    # Copy tarball to RPM SOURCES
    cp "$TMP_FILE" ~/rpmbuild/SOURCES/"$QUARTO_TAR"
    
    # Create RPM spec file
    cat > ~/rpmbuild/SPECS/quarto-${ARCH}.spec <<EOF
%global debug_package %{nil}
%global _build_id_links none

Name:           quarto
Version:        ${QUARTO_VERSION_NO_V}
Release:        1%{?dist}
Summary:        An open-source scientific and technical publishing system
License:        GPL-2.0
URL:            https://quarto.org
Source0:        %{name}-%{version}-linux-${QUARTO_ARCH}.tar.gz
BuildArch:      ${ARCH}
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
    
    # Build RPM
    echo "Building Quarto RPM for ${ARCH}..."
    rpmbuild --target ${ARCH} -ba ~/rpmbuild/SPECS/quarto-${ARCH}.spec
    
    # Copy built RPM to destination
    RPM_FILE=$(find ~/rpmbuild/RPMS/${ARCH}/ -name "quarto-*.rpm" | head -1)
    if [ -f "$RPM_FILE" ]; then
        cp "$RPM_FILE" "$DEST_DIR/"
        echo "Quarto RPM for ${ARCH} built successfully"
    else
        echo "Error: Failed to build Quarto RPM for ${ARCH}"
        exit 1
    fi
    
    # Cleanup
    rm -f "$TMP_FILE"
done

# Cleanup RPM build directory
rm -rf ~/rpmbuild

# --- Positron ---
echo "Fetching Positron download URLs..."

POSITRON_PAGE=$(curl -s "https://positron.posit.co/download.html")

for ARCH in "x86_64" "aarch64"; do
    PATTERN="https://cdn.posit.co/positron/prereleases/rpm/${ARCH}/Positron-[^\" ]+\.rpm"
    if [ "$ARCH" = "x86_64" ]; then
      DEST_DIR="$RPM_X86_DIR"
    else
      DEST_DIR="$RPM_ARM_DIR"
    fi

    URL=$(echo "$POSITRON_PAGE" | grep -oE "$PATTERN" | head -n1)
    FILE=$(basename "$URL")
    DEST="$DEST_DIR/$FILE"

    echo "Downloading Positron .rpm $ARCH from $URL..."
    TMP_FILE=$(mktemp)
    curl -fL -o "$TMP_FILE" "$URL"
    if [ ! -s "$TMP_FILE" ]; then
      echo "Error: Downloaded Positron file is empty!"
      exit 1
    fi
    mv "$TMP_FILE" "$DEST"
done

# --- Generate RPM Metadata ---
echo "Generating RPM metadata..."

createrepo_c "$RPM_X86_DIR"
createrepo_c "$RPM_ARM_DIR"

echo "✅ All packages downloaded and metadata generated successfully."
