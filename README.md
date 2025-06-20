# Dotfiles with HTCondor VS Code Extension

This repository contains dotfiles and a custom VS Code extension for monitoring HTCondor GPU status across all devcontainers.

## 🎯 What This Does

- **Automatically installs** a custom HTCondor status extension in all VS Code devcontainers
- **Shows real-time GPU status** in the VS Code status bar
- **Auto-refreshes every 15 seconds** to detect HTCondor issues
- **Visual indicators**: 🟢 HTCondor: GPUs OK or 🔴 HTCondor: GPU Issue

## 📁 Repository Structure

```
dotfiles/
├── README.md                           # This file
├── install.sh                          # Auto-installation script
└── vscode-extensions/
    └── htcondor-status/
        ├── package.json                # Extension manifest
        └── extension.js                # Extension code
```

## 🚀 Setup (One-Time)

### 1. Configure VS Code User Settings

Open VS Code and configure dotfiles integration:

1. Press `Ctrl+Shift+P`
2. Type: "Preferences: Open User Settings (JSON)"
3. Add this configuration:

```json
{
    "dotfiles.repository": "https://github.com/yourusername/dotfiles",
    "dotfiles.installCommand": "install.sh"
}
```

Replace `yourusername` with your actual GitHub username.

### 2. That's it! 

Now **every new devcontainer** will automatically:
- Clone this dotfiles repository
- Run the `install.sh` script  
- Install the HTCondor status extension
- Show the status indicator in the VS Code status bar

## 🔧 Manual Installation (If Needed)

If you need to install the extension manually in an existing devcontainer:

```bash
# Clone dotfiles (if not already done)
git clone https://github.com/yourusername/dotfiles.git ~/dotfiles

# Run installation script
~/dotfiles/install.sh

# Reload VS Code window
# Ctrl+Shift+P → "Developer: Reload Window"
```

## 📊 Using the Extension

### Status Bar Indicators

- `⏳ HTCondor: Checking...` - Extension is checking status
- `🟢 HTCondor: GPUs OK` - HTCondor GPUs properly provisioned (2/2)
- `🔴 HTCondor: GPU Issue` - HTCondor needs restart (click for details)

### Available Commands

Press `Ctrl+Shift+P` and type:

- **"Refresh HTCondor Status"** - Manually refresh the status
- **"Restart HTCondor Service"** - Restart HTCondor with confirmation

### Click Actions

- **Click the status bar indicator** to manually refresh
- **Hover over the indicator** to see detailed tooltip information

## 🛠 How It Works

The extension monitors HTCondor by running:
```bash
condor_status -l | grep -E "TotalGPUs|TotalSlotGPUs"
```

It expects to find:
- `TotalGPUs = 2`
- `TotalSlotGPUs = 2`

If these values are missing or incorrect, it shows a warning that HTCondor may need to be restarted.

## 🐛 Troubleshooting

### Extension Not Showing Up

1. **Check if dotfiles ran**: Look for installation output during devcontainer creation
2. **Manual installation**: Run `~/dotfiles/install.sh` inside the container
3. **Reload VS Code**: `Ctrl+Shift+P` → "Developer: Reload Window"
4. **Check extensions**: `Ctrl+Shift+P` → "Developer: Show Running Extensions"

### HTCondor Commands Failing

- Ensure HTCondor is installed in your devcontainer
- Test manually: `condor_status -l | grep -i gpu`
- Check if HTCondor service is running: `systemctl status condor`

### Status Shows Error

- Verify HTCondor is running: `condor_status`
- Check HTCondor configuration
- Try restarting HTCondor: `sudo systemctl restart condor`

## 📝 Customization

### Changing GPU Count Expectations

Edit `vscode-extensions/htcondor-status/extension.js` and modify these lines:

```javascript
const hasGPUs = output.includes('TotalGPUs = 2');        // Change the 2
const hasSlotGPUs = output.includes('TotalSlotGPUs = 2'); // Change the 2
```

### Changing Refresh Interval

Edit the `setInterval` value in `extension.js`:

```javascript
updateInterval = setInterval(updateStatus, 15000); // 15000 = 15 seconds
```

## 🔄 Updating the Extension

1. Make changes to files in `vscode-extensions/htcondor-status/`
2. Commit and push to this repository
3. In any devcontainer, run: `~/dotfiles/install.sh`
4. Reload VS Code window

## 📋 Requirements

- VS Code with Dev Containers extension
- Devcontainer with HTCondor installed
- Node.js in devcontainer (auto-installed by script if missing)
- Git access to this repository

---

**💡 Pro Tip**: This setup works great with any HTCondor-based development workflow. You'll immediately know when HTCondor GPU provisioning has issues without manually checking!
