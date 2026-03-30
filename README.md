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

### Option A (recommended, easiest)
1. Double-click `Run-GameBoost-Admin.bat`
2. Pick one menu option:
   - `1` apply safe tweaks
   - `2` apply safe tweaks + HAGS
   - `3` revert from backup

> You do **not** need to open `GameBoost.ps1` separately when using the `.bat` launcher.

### Option B (PowerShell, advanced)
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


## How to verify it worked

- The launcher now keeps the elevated PowerShell window open so you can read the final status and validation summary.
- Look for `Done. Applied safe gaming tweaks...` and `Validation summary:` in that window.
- A run log is written to `gameboost-last-run.log` in the same folder as the script.
- A backup file is written to `gameboost-backup.json` for revert operations.
