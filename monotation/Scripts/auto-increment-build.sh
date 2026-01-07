#!/bin/bash

# Auto-increment build number based on git commit count
# This script runs before each build to set CURRENT_PROJECT_VERSION

# Get git commit count
GIT_COMMIT_COUNT=$(git rev-list --count HEAD 2>/dev/null)

if [ $? -eq 0 ]; then
    echo "✅ Setting build number to git commit count: $GIT_COMMIT_COUNT"
    
    # Update Info.plist for iOS target
    if [ -f "${PROJECT_DIR}/monotation/Info.plist" ]; then
        /usr/libexec/PlistBuddy -c "Set :CFBundleVersion $GIT_COMMIT_COUNT" "${PROJECT_DIR}/monotation/Info.plist" 2>/dev/null || true
    fi
    
    # Use agvtool to set build number (works with xcodeproj settings)
    xcrun agvtool new-version -all "$GIT_COMMIT_COUNT" 2>/dev/null || true
    
    echo "✅ Build number set to: $GIT_COMMIT_COUNT"
else
    echo "⚠️ Not a git repository or git not available. Using existing build number."
fi

