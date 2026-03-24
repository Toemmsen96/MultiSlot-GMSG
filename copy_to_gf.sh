#!/bin/bash

# Copy directories to BeamNG mod folder
TARGET_DIR="/home/tom/.local/share/BeamNG/BeamNG.drive/current/mods/unpacked/gmsg"

# Create target directory if it doesn't exist
mkdir -p "$TARGET_DIR"

# Copy lua directory
if [ -d "lua" ]; then
    cp -r lua "$TARGET_DIR/"
    echo "Copied lua/ to $TARGET_DIR/"
else
    echo "Warning: lua/ directory not found"
fi

# Copy scripts directory
if [ -d "scripts" ]; then
    cp -r scripts "$TARGET_DIR/"
    echo "Copied scripts/ to $TARGET_DIR/"
else
    echo "Warning: scripts/ directory not found"
fi

# Copy ui directory
if [ -d "ui" ]; then
    cp -r ui "$TARGET_DIR/"
    echo "Copied ui/ to $TARGET_DIR/"
else
    echo "Warning: ui/ directory not found"
fi

# Create modslotgenerator directory and copy templates
if [ -d "modslotgeneratorexampletemplates" ]; then
    mkdir -p "$TARGET_DIR/modslotgenerator"
    cp modslotgeneratorexampletemplates/*.json "$TARGET_DIR/modslotgenerator/"
    echo "Copied templates to $TARGET_DIR/modslotgenerator/"
else
    echo "Warning: modslotgeneratorexampletemplates/ directory not found"
fi

echo "Copy completed!"
