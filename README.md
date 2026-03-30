# GameBoost (Windows)

A small PowerShell-based executable-style utility to apply **safe** Windows gaming-performance tweaks (no overclocking, no BIOS edits, no voltage/fan changes).

## What it changes

- Sets power plan to **Ultimate Performance** (if present) or **High Performance**.
- Enables Windows **Game Mode**.
- Sets foreground app scheduling priority behavior for responsiveness.
- Reduces visual effects overhead.
- Disables GameDVR background capture features (can reduce overhead while gaming).
- Optional flag to enable **HAGS** (Hardware-accelerated GPU scheduling).

All registry values changed by the tool are backed up to `gameboost-backup.json`.

## Usage

### Option A (easy)
1. Right-click `Run-GameBoost-Admin.bat`
2. Click **Run as administrator**

### Option B (PowerShell)
Run in elevated PowerShell:

```powershell
./GameBoost.ps1
```

Optional HAGS toggle:

```powershell
./GameBoost.ps1 -EnableHags
```

Revert registry settings from backup:

```powershell
./GameBoost.ps1 -Revert
```

## Notes

- This script intentionally avoids risky changes (no overclocking, no undervolting, no disabling critical protections).
- A reboot is recommended after applying changes.
- If you want to switch power plans later, run `powercfg /L` and then `powercfg /S <GUID>`.
