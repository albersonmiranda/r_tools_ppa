#!/bin/bash

set -e
set -o pipefail

# --- Dependency checks ---
for cmd in jq dpkg-scanpackages createrepo_c curl grep sort head gzip; do
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

RSTUDIO_DEB_URL=$(echo "$RSTUDIO_PAGE" | grep -oE 'https://.*rstudio-.*-amd64.deb' | head -n1)
RSTUDIO_RPM_URL=$(echo "$RSTUDIO_PAGE" | grep -oE 'https://.*rstudio-.*-x86_64.rpm' | head -n1)

echo "Downloading RStudio .deb amd64..."
curl -L -o "$DEB_DIR/$(basename $RSTUDIO_DEB_URL)" "$RSTUDIO_DEB_URL"

# --- Quarto ---
echo "Fetching Quarto release info..."

QUARTO_API="https://api.github.com/repos/quarto-dev/quarto-cli/releases/latest"
QUARTO_VERSION=$(curl -s "$QUARTO_API" | jq -r '.tag_name')
QUARTO_VERSION_NO_V=${QUARTO_VERSION#v}

echo "Quarto latest version: $QUARTO_VERSION"

for ARCH in "amd64" "arm64"; do
    QUARTO_DEB="quarto-${QUARTO_VERSION_NO_V}-linux-${ARCH}.deb"
    URL="https://github.com/quarto-dev/quarto-cli/releases/download/${QUARTO_VERSION}/${QUARTO_DEB}"
    DEST="$DEB_DIR/$QUARTO_DEB"

    echo "Downloading Quarto $ARCH from $URL..."

    TMP_FILE=$(mktemp)
    curl -fL -o "$TMP_FILE" "$URL"
    if [ ! -s "$TMP_FILE" ]; then
        echo "Error: Downloaded Quarto file is empty!"
        exit 1
    fi
    mv "$TMP_FILE" "$DEST"
done

# --- Positron ---
echo "Fetching Positron download URLs..."

POSITRON_PAGE=$(curl -s "https://positron.posit.co/download.html")

for TYPE in deb; do
  for ARCH in x86_64 arm64; do
    PATTERN="https://cdn.posit.co/positron/prereleases/deb/${ARCH}/Positron-[^\" ]+\.deb"
    DEST_DIR="$DEB_DIR"

    URL=$(echo "$POSITRON_PAGE" | grep -oE "$PATTERN" | head -n1)
    FILE=$(basename "$URL")
    DEST="$DEST_DIR/$FILE"

    echo "Downloading Positron .${TYPE} $ARCH from $URL..."
    TMP_FILE=$(mktemp)
    curl -fL -o "$TMP_FILE" "$URL"
    if [ ! -s "$TMP_FILE" ]; then
      echo "Error: Downloaded Positron file is empty!"
      exit 1
    fi
    mv "$TMP_FILE" "$DEST"
  done
done

# --- Generate Debian Metadata ---
echo "Generating APT metadata..."

for ARCH in "binary-amd64" "binary-arm64"; do
    mkdir -p "deb/dists/stable/main/${ARCH}"
    dpkg-scanpackages --multiversion "$DEB_DIR" /dev/null | gzip -9c > "deb/dists/stable/main/${ARCH}/Packages.gz"
done

# --- Create Release file ---
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

# --- Generate checksums for Release file ---
echo "Generating checksums..."

# Function to generate checksums
generate_checksums() {
    local hash_cmd=$1
    local hash_name=$2
    
    echo "${hash_name}:" >> deb/dists/stable/Release
    find deb/dists/stable -name "Packages.gz" -type f | while read file; do
        local rel_path=${file#deb/dists/stable/}
        local hash=$(${hash_cmd} "$file" | cut -d' ' -f1)
        local size=$(stat -c%s "$file")
        printf " %s %8d %s\n" "$hash" "$size" "$rel_path" >> deb/dists/stable/Release
    done
}

# Generate MD5Sum and SHA256 checksums
generate_checksums "md5sum" "MD5Sum"
generate_checksums "sha256sum" "SHA256"

echo "✅ All packages downloaded and metadata generated successfully."
