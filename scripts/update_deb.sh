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

for cmd in jq dpkg-scanpackages curl grep head gzip xz; do
    command -v $cmd >/dev/null 2>&1 || { echo >&2 "$cmd is required but not installed. Aborting."; exit 1; }
done

DEB_DIR="deb/pool/main"
mkdir -p "$DEB_DIR"

echo "Fetching RStudio download URLs..."

RSTUDIO_PAGE=$(curl -fsSL "https://live-rstudio.pantheonsite.io/download/rstudio-desktop/?posit_iframe=1")

RSTUDIO_DEB_URL=$(echo "$RSTUDIO_PAGE" | grep -oE 'https://[^" ]+rstudio-[^" ]+-amd64\.deb' | head -n1)
[ -n "$RSTUDIO_DEB_URL" ] || die "Could not find RStudio amd64 .deb URL"

download_to "$RSTUDIO_DEB_URL" "$DEB_DIR/$(basename "$RSTUDIO_DEB_URL")" "RStudio .deb amd64"

echo "Fetching Quarto release info..."

QUARTO_API="https://api.github.com/repos/quarto-dev/quarto-cli/releases/latest"
QUARTO_VERSION=$(curl -s "$QUARTO_API" | jq -r '.tag_name')
QUARTO_VERSION_NO_V=${QUARTO_VERSION#v}

[ -n "$QUARTO_VERSION" ] || die "Could not read Quarto latest version"

echo "Quarto latest version: $QUARTO_VERSION"

for ARCH in "amd64" "arm64"; do
    QUARTO_DEB="quarto-${QUARTO_VERSION_NO_V}-linux-${ARCH}.deb"
    URL="https://github.com/quarto-dev/quarto-cli/releases/download/${QUARTO_VERSION}/${QUARTO_DEB}"
    DEST="$DEB_DIR/$QUARTO_DEB"

    download_to "$URL" "$DEST" "Quarto $ARCH"
done

echo "Fetching Positron download URLs..."

POSITRON_PAGE=$(curl -s "https://positron.posit.co/download.html")

for ARCH in x86_64 arm64; do
    PATTERN="https://cdn.posit.co/positron/releases/deb/${ARCH}/Positron-[^\" ]+\.deb"
    URL=$(echo "$POSITRON_PAGE" | grep -oE "$PATTERN" | head -n1)
    [ -n "$URL" ] || die "Could not find Positron .deb URL for $ARCH"
    download_to "$URL" "$DEB_DIR/$(basename "$URL")" "Positron .deb $ARCH"
done

echo "Generating APT metadata..."

for ARCH in "amd64" "arm64"; do
    mkdir -p "deb/dists/stable/main/binary-${ARCH}"

    TEMP_DIR=$(mktemp -d)

    if [ "$ARCH" = "amd64" ]; then
        find "$DEB_DIR" -name "*.deb" \( -name "*-amd64.deb" -o -name "*-x64.deb" \) -exec cp {} "$TEMP_DIR/" \;
    else
        find "$DEB_DIR" -name "*-arm64.deb" -exec cp {} "$TEMP_DIR/" \;
    fi

    PACKAGES_CONTENT=$(dpkg-scanpackages --multiversion "$TEMP_DIR" /dev/null | \
    sed "s|Filename: ${TEMP_DIR}/|Filename: pool/main/|g")

    echo "$PACKAGES_CONTENT" | gzip -9c > "deb/dists/stable/main/binary-${ARCH}/Packages.gz"
    echo "$PACKAGES_CONTENT" | xz -9c > "deb/dists/stable/main/binary-${ARCH}/Packages.xz"
    echo "$PACKAGES_CONTENT" > "deb/dists/stable/main/binary-${ARCH}/Packages"

    rm -rf "$TEMP_DIR"
done

cat <<EOF > deb/dists/stable/Release
Origin: r_tools_ppa
Label: r_tools_ppa
Suite: stable
Codename: stable
Date: $(date -R)
Architectures: amd64 arm64
Components: main
Description: RStudio, Quarto, and Positron Linux packages
EOF

echo "Generating checksums..."

generate_checksums() {
    local hash_cmd=$1
    local hash_name=$2
    
    echo "${hash_name}:" >> deb/dists/stable/Release
    find deb/dists/stable -name "Packages.gz" -o -name "Packages.xz" -o -name "Packages" | while read file; do
        local rel_path=${file#deb/dists/stable/}
        local hash=$(${hash_cmd} "$file" | cut -d' ' -f1)
        local size=$(stat -c%s "$file")
        printf " %s %8d %s\n" "$hash" "$size" "$rel_path" >> deb/dists/stable/Release
    done
}

# Generate MD5Sum and SHA256 checksums
generate_checksums "md5sum" "MD5Sum"
generate_checksums "sha256sum" "SHA256"

echo "Signing APT metadata..."

GPG_SIGN_ARGS=(--default-key "albersonmiranda@hotmail.com")
if [ -n "${GPG_PASSPHRASE:-}" ]; then
    GPG_SIGN_ARGS+=(--batch --yes --pinentry-mode loopback --passphrase "$GPG_PASSPHRASE")
fi

gpg "${GPG_SIGN_ARGS[@]}" \
    --clearsign \
    --output deb/dists/stable/InRelease \
    deb/dists/stable/Release

gpg "${GPG_SIGN_ARGS[@]}" \
    --detach-sign --armor \
    --output deb/dists/stable/Release.gpg \
    deb/dists/stable/Release

echo "All packages downloaded and metadata generated successfully."