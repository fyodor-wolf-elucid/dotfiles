#!/bin/bash

# Claude Code Authentication Setup for Devcontainers
# To avoid logging in every time, mount the Claude auth directory in your devcontainer.json:
# "mounts": [
#   "source=${localEnv:HOME}/.config/claude,target=/home/vscode/.config/claude,type=bind"
# ]
# Or for non-vscode user: target=/home/[your-username]/.config/claude

echo "🚀 Setting up dotfiles and VS Code extensions..."


# Install Claude Code using the official installer
if ! command -v claude &> /dev/null; then
    echo "Installing Claude Code..."
    curl -fsSL https://claude.ai/install.sh | bash
    echo "✅ Claude Code installed successfully"
else
    echo "Claude Code already installed."
fi

# Create VS Code extensions directory (try both local and server)
mkdir -p ~/.vscode/extensions
mkdir -p ~/.vscode-server/extensions

# Install HTCondor Status Extension
echo "📦 Installing HTCondor Status Extension..."

# Try server extensions first (for devcontainers)
if [ -d "$HOME/.vscode-server" ]; then
    EXT_DIR="$HOME/.vscode-server/extensions/htcondor-status"
    echo "📡 Installing to VS Code server extensions directory"
else
    EXT_DIR="$HOME/.vscode/extensions/htcondor-status"
    echo "💻 Installing to VS Code local extensions directory"
fi
mkdir -p "$EXT_DIR"

# Copy extension files from dotfiles
if [ -f "$HOME/dotfiles/vscode-extensions/htcondor-status/package.json" ]; then
    cp "$HOME/dotfiles/vscode-extensions/htcondor-status/package.json" "$EXT_DIR/"
    cp "$HOME/dotfiles/vscode-extensions/htcondor-status/extension.js" "$EXT_DIR/"
    echo "✅ HTCondor extension files copied to ~/.vscode/extensions/htcondor-status"
else
    echo "❌ Extension files not found in dotfiles. Creating them..."
    
    # Create package.json
    cat > "$EXT_DIR/package.json" << 'EOF'
{
    "name": "htcondor-status",
    "displayName": "HTCondor GPU Status",
    "description": "Shows HTCondor GPU status in status bar",
    "version": "0.0.1",
    "engines": { 
        "vscode": "^1.60.0" 
    },
    "categories": ["Other"],
    "activationEvents": ["*"],
    "main": "./extension.js",
    "contributes": {
        "commands": [
            {
                "command": "htcondor.refresh",
                "title": "Refresh HTCondor Status"
            },
            {
                "command": "htcondor.restart",
                "title": "Restart HTCondor Service"
            }
        ]
    }
}
EOF

    # Create extension.js
    cat > "$EXT_DIR/extension.js" << 'EOF'
const vscode = require('vscode');
const { exec } = require('child_process');

function activate(context) {
    const statusBarItem = vscode.window.createStatusBarItem(vscode.StatusBarAlignment.Left, 100);
    statusBarItem.command = 'htcondor.refresh';
    
    let updateInterval;
    
    function updateStatus() {
        statusBarItem.text = '⏳ HTCondor: Checking...';
        statusBarItem.tooltip = 'Checking HTCondor GPU status...';
        
        const command = 'condor_status -l 2>/dev/null | grep -E "TotalGPUs|TotalSlotGPUs"';
            
        exec(command, (error, stdout, stderr) => {
            if (error) {
                statusBarItem.text = '🔴 HTCondor: Error';
                statusBarItem.tooltip = `HTCondor command failed: ${error.message}`;
                statusBarItem.backgroundColor = new vscode.ThemeColor('statusBarItem.errorBackground');
                console.log('HTCondor Status Error:', error.message);
            } else {
                const output = stdout.trim();
                console.log('HTCondor Status Output:', output);
                
                const hasGPUs = output.includes('TotalGPUs = 2');
                const hasSlotGPUs = output.includes('TotalSlotGPUs = 2');
                
                if (hasGPUs && hasSlotGPUs) {
                    statusBarItem.text = '🟢 HTCondor: GPUs OK';
                    statusBarItem.tooltip = 'HTCondor GPUs properly provisioned (2/2)';
                    statusBarItem.backgroundColor = undefined;
                } else {
                    statusBarItem.text = '🔴 HTCondor: GPU Issue';
                    statusBarItem.tooltip = `HTCondor GPU provisioning problem!\nExpected: TotalGPUs=2, TotalSlotGPUs=2\nFound: ${output || 'No GPU info'}\n\nClick to refresh, or restart HTCondor service`;
                    statusBarItem.backgroundColor = new vscode.ThemeColor('statusBarItem.warningBackground');
                }
            }
        });
    }

    function startPeriodicUpdates() {
        if (updateInterval) {
            clearInterval(updateInterval);
        }
        updateInterval = setInterval(updateStatus, 15000);
    }

    const refreshCommand = vscode.commands.registerCommand('htcondor.refresh', () => {
        updateStatus();
        vscode.window.showInformationMessage('HTCondor status refreshed');
    });

    const restartCommand = vscode.commands.registerCommand('htcondor.restart', () => {
        vscode.window.showWarningMessage(
            'Restart HTCondor service?', 
            'Yes', 
            'No'
        ).then(selection => {
            if (selection === 'Yes') {
                exec('sudo systemctl restart condor', (error, stdout, stderr) => {
                    if (error) {
                        vscode.window.showErrorMessage(`Failed to restart HTCondor: ${error.message}`);
                    } else {
                        vscode.window.showInformationMessage('HTCondor service restarted. Checking status in 5 seconds...');
                        setTimeout(updateStatus, 5000);
                    }
                });
            }
        });
    });
    
    updateStatus();
    startPeriodicUpdates();
    statusBarItem.show();

    context.subscriptions.push(
        statusBarItem, 
        refreshCommand, 
        restartCommand, 
        { dispose: () => {
            if (updateInterval) {
                clearInterval(updateInterval);
            }
        }}
    );

    console.log('HTCondor Status extension activated');
}

function deactivate() {
    console.log('HTCondor Status extension deactivated');
}

module.exports = { activate, deactivate };
EOF

    echo "✅ HTCondor extension files created"
fi

# Run Claude authentication setup if available
if [ -f "/tmp/post-create-claude.sh" ]; then
    echo "🔐 Running Claude authentication setup..."
    bash /tmp/post-create-claude.sh
fi

echo "🎉 Dotfiles setup complete!"
echo "📝 To activate extensions, reload VS Code window when it starts"