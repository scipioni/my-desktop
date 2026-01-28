#!/bin/bash

# Script to update PKGBUILD with the latest version from npm registry

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Checking for latest version of qwen-code...${NC}"

# Get the latest version info from npm registry
LATEST_VERSION=$(curl -s https://registry.npmjs.org/@qwen-code/qwen-code | jq -r '.["dist-tags"].latest')

if [ "$LATEST_VERSION" = "null" ] || [ -z "$LATEST_VERSION" ]; then
    echo -e "${RED}Error: Could not fetch latest version from npm registry${NC}"
    exit 1
fi

echo -e "${GREEN}Latest version found: $LATEST_VERSION${NC}"

# Function to convert npm version to Arch package version format
convert_version() {
    local npm_ver=$1
    # Convert "0.5.0-preview.0" to "0.5.0p0" format
    echo "$npm_ver" | sed 's/-preview\./p/g' | sed 's/-alpha\./a/g' | sed 's/-beta\./b/g' | sed 's/-rc\./rc/g' | sed 's/-/p/g'
}

# Get current version from PKGBUILD
CURRENT_PKGVER=$(grep '^pkgver=' PKGBUILD | cut -d'=' -f2)
CURRENT_PKGREL=$(grep '^pkgrel=' PKGBUILD | cut -d'=' -f2)
CURRENT_INTERNAL_VER=$(grep '^_pkgver=' PKGBUILD | cut -d'=' -f2)

echo -e "${GREEN}Current pkgver in PKGBUILD: $CURRENT_PKGVER${NC}"
echo -e "${GREEN}Current _pkgver in PKGBUILD: $CURRENT_INTERNAL_VER${NC}"
echo -e "${GREEN}Current pkgrel in PKGBUILD: $CURRENT_PKGREL${NC}"

# Convert latest version to Arch format
FORMATTED_LATEST_VERSION=$(convert_version "$LATEST_VERSION")

# Check if version changed
if [ "$CURRENT_INTERNAL_VER" = "$LATEST_VERSION" ]; then
    echo -e "${YELLOW}Version is already up to date. Incrementing pkgrel...${NC}"

    # Increment pkgrel
    NEW_PKGREL=$((CURRENT_PKGREL + 1))

    # Update pkgrel in PKGBUILD
    sed -i "s/^pkgrel=.*/pkgrel=$NEW_PKGREL/" PKGBUILD

    echo -e "${GREEN}Updated pkgrel to $NEW_PKGREL${NC}"
else
    echo -e "${GREEN}New version detected. Updating PKGBUILD...${NC}"

    # Update pkgver and _pkgver
    sed -i "s/^pkgver=.*/pkgver=$FORMATTED_LATEST_VERSION/" PKGBUILD
    sed -i "s/^_pkgver=.*/_pkgver=$LATEST_VERSION/" PKGBUILD

    # Reset pkgrel to 1 for new version
    sed -i "s/^pkgrel=.*/pkgrel=1/" PKGBUILD

    # Update source URL
    sed -i "s|https://registry.npmjs.org/@qwen-code/qwen-code/-/qwen-code-[^.]*\.tgz|https://registry.npmjs.org/@qwen-code/qwen-code/-/qwen-code-$LATEST_VERSION.tgz|" PKGBUILD

    # Update noextract line
    sed -i "s|qwen-code-[^.]*\.tgz|qwen-code-$LATEST_VERSION.tgz|" PKGBUILD

    echo -e "${GREEN}Updated pkgver to $FORMATTED_LATEST_VERSION${NC}"
    echo -e "${GREEN}Updated _pkgver to $LATEST_VERSION${NC}"
    echo -e "${GREEN}Reset pkgrel to 1${NC}"
fi

# Download the new source to get the new checksum
echo -e "${GREEN}Downloading new source to calculate checksum...${NC}"

# Since the PKGBUILD uses variables in the source URL, we need to construct it manually
PKGNAME=$(grep '^pkgname=' PKGBUILD | cut -d'=' -f2)
INTERNAL_VER=$(grep '^_pkgver=' PKGBUILD | cut -d'=' -f2)

# Construct the source URL
SOURCE_URL="https://registry.npmjs.org/@qwen-code/$PKGNAME/-/$PKGNAME-$INTERNAL_VER.tgz"

# Download the new source file
SOURCE_FILE=$(basename "$SOURCE_URL")
if [ ! -f "$SOURCE_FILE" ]; then
    wget "$SOURCE_URL"
fi

# Calculate new checksum
NEW_CHECKSUM=$(sha256sum "$SOURCE_FILE" | cut -d' ' -f1)
echo -e "${GREEN}Calculated new checksum: $NEW_CHECKSUM${NC}"

# Update the sha256sums in PKGBUILD
sed -i "s/sha256sums=.*/sha256sums=('$NEW_CHECKSUM')/" PKGBUILD

echo -e "${GREEN}PKGBUILD updated successfully!${NC}"

# Show git diff if in a git repo
if [ -d ".git" ]; then
    echo -e "\n${YELLOW}Changes made:${NC}"
    git diff PKGBUILD || true
fi

echo -e "${GREEN}Update complete!${NC}"