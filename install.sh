#!/bin/sh

DOTFILES_DIR="$HOME/dotfiles"
CONFIG_DIR="$HOME/.config"

# Ensure the target directory exists
mkdir -p "$CONFIG_DIR"

echo "[_] Creating symlinks"

for item in "$DOTFILES_DIR"/*; do
    base_name=$(basename "$item")

    target="$CONFIG_DIR/$base_name"

    if [ -e "$target" ] || [ -L "$target" ]; then
        echo "Removing existing file or symlink: $target"
        rm -rf "$target"
    fi

    echo "Creating symlink: $target -> $item"
    ln -s "$item" "$target"
    echo ""
done

echo "[X] Symlinks created successfully!"

echo "[_] Setting up Git configuration..."
git config --global user.name "braam76"
git config --global user.email "ilgargamidov968@gmail.com"
git config --global init.defaultBranch main

echo "[X] Git configuration applied!"
