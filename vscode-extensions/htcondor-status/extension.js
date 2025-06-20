const vscode = require('vscode');
const { exec } = require('child_process');

function activate(context) {
    const statusBarItem = vscode.window.createStatusBarItem(vscode.StatusBarAlignment.Left, 100);
    statusBarItem.command = 'htcondor.refresh';
    
    let updateInterval;
    
    function updateStatus() {
        statusBarItem.text = '⏳ HTCondor: Checking...';
        statusBarItem.tooltip = 'Checking HTCondor GPU status...';
        
        // Check if we're in a container and use host script if available
        let command;
        if (process.env.REMOTE_CONTAINERS && require('fs').existsSync('/host-bin/check_htcondor.sh')) {
            command = 'bash /host-bin/check_htcondor.sh';
        } else {
            command = 'condor_status -l 2>/dev/null | grep -E "TotalGPUs|TotalSlotGPUs"';
        }
            
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
        // Clear existing interval if any
        if (updateInterval) {
            clearInterval(updateInterval);
        }
        
        // Update every 15 seconds
        updateInterval = setInterval(updateStatus, 15000);
    }

    // Register refresh command
    const refreshCommand = vscode.commands.registerCommand('htcondor.refresh', () => {
        updateStatus();
        vscode.window.showInformationMessage('HTCondor status refreshed');
    });

    // Register restart command (optional helper)
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
    
    // Initial setup
    updateStatus();
    startPeriodicUpdates();
    statusBarItem.show();

    // Cleanup on deactivation
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