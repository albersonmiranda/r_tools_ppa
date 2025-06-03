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

RSTUDIO_RPM_URL=$(echo "$RSTUDIO_PAGE" | grep -oE 'https://.*rstudio-.*-x86_64.rpm' | head -n1)

echo "Downloading RStudio .rpm x86_64..."
curl -L -o "$RPM_X86_DIR/$(basename $RSTUDIO_RPM_URL)" "$RSTUDIO_RPM_URL"

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

for TYPE in rpm; do
    PATTERN="https://cdn.posit.co/positron/prereleases/rpm/${ARCH}/Positron-[^\" ]+\.rpm"
    if [ "$ARCH" = "x86_64" ]; then
      DEST_DIR="$RPM_X86_DIR"
    else
      DEST_DIR="$RPM_ARM_DIR"
    fi

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

# --- Generate RPM Metadata ---
echo "Generating RPM metadata..."

createrepo_c "$RPM_X86_DIR"
createrepo_c "$RPM_ARM_DIR"

echo "✅ All packages downloaded and metadata generated successfully."
