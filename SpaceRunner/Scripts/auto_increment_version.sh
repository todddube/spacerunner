#!/bin/bash

# Auto-increment version script for SpaceRunner
# This script automatically increments the build number and optionally the version number

# Get the project directory
PROJECT_DIR="${PROJECT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
PLIST_PATH="$PROJECT_DIR/SpaceRunner/Info.plist"

# Check if plist exists
if [ ! -f "$PLIST_PATH" ]; then
    echo "Error: Info.plist not found at $PLIST_PATH"
    exit 1
fi

# Function to get current version info
get_version_info() {
    CURRENT_VERSION=$(/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" "$PLIST_PATH")
    CURRENT_BUILD=$(/usr/libexec/PlistBuddy -c "Print CFBundleVersion" "$PLIST_PATH")
    echo "Current version: $CURRENT_VERSION (build $CURRENT_BUILD)"
}

# Function to increment build number
increment_build() {
    NEW_BUILD=$((CURRENT_BUILD + 1))
    /usr/libexec/PlistBuddy -c "Set :CFBundleVersion $NEW_BUILD" "$PLIST_PATH"
    echo "Build number incremented to: $NEW_BUILD"
}

# Function to increment patch version (x.y.Z)
increment_patch() {
    IFS='.' read -ra VERSION_PARTS <<< "$CURRENT_VERSION"
    MAJOR=${VERSION_PARTS[0]}
    MINOR=${VERSION_PARTS[1]}
    PATCH=${VERSION_PARTS[2]:-0}
    NEW_PATCH=$((PATCH + 1))
    NEW_VERSION="$MAJOR.$MINOR.$NEW_PATCH"
    /usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $NEW_VERSION" "$PLIST_PATH"
    echo "Version incremented to: $NEW_VERSION"
}

# Function to increment minor version (x.Y.z)
increment_minor() {
    IFS='.' read -ra VERSION_PARTS <<< "$CURRENT_VERSION"
    MAJOR=${VERSION_PARTS[0]}
    MINOR=${VERSION_PARTS[1]}
    NEW_MINOR=$((MINOR + 1))
    NEW_VERSION="$MAJOR.$NEW_MINOR.0"
    /usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $NEW_VERSION" "$PLIST_PATH"
    # Reset build number to 1 for new version
    /usr/libexec/PlistBuddy -c "Set :CFBundleVersion 1" "$PLIST_PATH"
    echo "Version incremented to: $NEW_VERSION (build reset to 1)"
}

# Function to increment major version (X.y.z)
increment_major() {
    IFS='.' read -ra VERSION_PARTS <<< "$CURRENT_VERSION"
    MAJOR=${VERSION_PARTS[0]}
    NEW_MAJOR=$((MAJOR + 1))
    NEW_VERSION="$NEW_MAJOR.0.0"
    /usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $NEW_VERSION" "$PLIST_PATH"
    # Reset build number to 1 for new version
    /usr/libexec/PlistBuddy -c "Set :CFBundleVersion 1" "$PLIST_PATH"
    echo "Version incremented to: $NEW_VERSION (build reset to 1)"
}

# Main script logic
echo "SpaceRunner Version Manager"
echo "=========================="

get_version_info

case "${1:-build}" in
    "build")
        increment_build
        ;;
    "patch")
        increment_patch
        increment_build
        ;;
    "minor")
        increment_minor
        ;;
    "major")
        increment_major
        ;;
    "info")
        # Just show current info
        ;;
    *)
        echo "Usage: $0 [build|patch|minor|major|info]"
        echo "  build - Increment build number only (default)"
        echo "  patch - Increment patch version (x.y.Z) and build number"
        echo "  minor - Increment minor version (x.Y.z) and reset build to 1"
        echo "  major - Increment major version (X.y.z) and reset build to 1"
        echo "  info  - Show current version info only"
        exit 1
        ;;
esac

echo ""
get_version_info
echo "Version update complete!"