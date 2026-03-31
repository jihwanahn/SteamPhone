# SteamPhone Package Lists

This directory contains package lists for different use cases.

## Files

- `gaming.txt` - Steam gaming and Windows game compatibility (Wine/DXVK)
- `desktop.txt` - Wayland desktop and graphics stack
- `network.txt` - Networking and Bluetooth packages
- `development.txt` - Development tools and compilers

## Usage

These lists are consumed by `build-rootfs.sh` during rootfs creation:

```bash
./scripts/build/build-rootfs.sh --device sd865
```

The build script installs packages from all lists automatically.

## Adding Packages

1. Edit the appropriate file
2. One package name per line
3. Use Arch Linux ARM package names (check with `pacman -Ss <package>`)
4. Avoid packages that don't support aarch64
