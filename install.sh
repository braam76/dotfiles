#!/bin/sh

# Define the source (dotfiles) and target (.config) directories
DOTFILES_DIR="$HOME/dotfiles"
CONFIG_DIR="$HOME/.config"

# Ensure the target directory exists
mkdir -p "$CONFIG_DIR"

# Iterate over each file/directory in the dotfiles directory
for item in "$DOTFILES_DIR"/*; do
    # Extract the base name of the file/directory
    base_name=$(basename "$item")

    # Define the target symlink path
    target="$CONFIG_DIR/$base_name"

    # Check if a file or symlink already exists at the target location
    if [ -e "$target" ] || [ -L "$target" ]; then
        echo "Removing existing file or symlink: $target"
        rm -rf "$target"
    fi

    # Create the symbolic link
    echo "Creating symlink: $target -> $item"
    ln -s "$item" "$target"
    echo ""
done

echo "Symlinks created successfully!"

