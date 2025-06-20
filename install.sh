#!/bin/bash

echo "🚀 Setting up dotfiles and VS Code extensions..."

# Install Node.js and vsce if not available
if ! command -v npm &> /dev/null; then
    echo "Installing Node.js..."
    curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
    sudo apt-get install -y nodejs
fi

if ! command -v vsce &> /dev/null; then
    echo "Installing vsce (VS Code Extension CLI)..."
    npm install -g vsce
fi

# Create VS Code extensions directory
mkdir -p ~/.vscode/extensions

# Install HTCondor Status Extension
echo "📦 Installing HTCondor Status Extension..."

# Create extension directory
EXT_DIR="$HOME/.vscode/extensions/htcondor-status"
mkdir -p "$EXT_DIR"

# Copy extension files from dotfiles
cp "$HOME/dotfiles/vscode-extensions/htcondor-status/package.json" "$EXT_DIR/"
cp "$HOME/dotfiles/vscode-extensions/htcondor-status/extension.js" "$EXT_DIR/"

# Alternative: Package as VSIX and install
cd "$EXT_DIR"
if vsce package --out htcondor-status.vsix 2>/dev/null; then
    echo "✅ Packaged extension as VSIX"
    if command -v code &> /dev/null; then
        code --install-extension htcondor-status.vsix
        echo "✅ Installed HTCondor extension via VSIX"
    else
        echo "ℹ️  VS Code not available yet, extension files copied to ~/.vscode/extensions/"
    fi
else
    echo "ℹ️  VSIX packaging failed, using direct file copy method"
fi

echo "🎉 Dotfiles setup complete!"
echo "📝 To activate extensions, reload VS Code window when it starts"