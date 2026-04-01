# Contributing to SteamPhone

Thank you for your interest in contributing to SteamPhone!

## Project Overview

SteamPhone transforms Samsung Galaxy S20 FE devices into SteamOS-powered ARM gaming devices. This is a complex project involving:

- Linux kernel customization
- ARM device tree development
- Root filesystem construction
- Gamescope compositor integration
- Steam client porting

## How to Contribute

### 1. Reporting Issues

Before creating an issue, please:
- Search existing issues first
- Specify your device model (SM-G780F, SM-G780G, SM-G781N)
- Include kernel logs and dmesg output
- Describe steps to reproduce

### 2. Code Contributions

#### Fork and Clone
```bash
git clone https://github.com/YOUR_USERNAME/steamphone.git
cd steamphone
git remote add upstream https://github.com/jihwanahn/steamphone.git
```

#### Create a Branch
```bash
git checkout -b feature/your-feature-name
# or
git checkout -b fix/issue-description
```

#### Development Setup
```bash
# Install build dependencies
./scripts/build/setup-host.sh

# Build kernel
./scripts/build/build-kernel.sh --device sd865

# Build rootfs
./scripts/build/build-rootfs.sh --device sd865
```

#### Testing
- Test on actual hardware when possible
- Use QEMU for basic testing: `qemu-aarch64-static`
- Verify kernel boots in emulator before submitting

#### Commit Rules
- Use clear, descriptive commit messages
- Reference issues: `Fixes #123` or `Closes #456`
- Sign off your commits: `git commit -s`
- One logical change per commit

### 3. Documentation

Documentation improvements are always welcome:
- Update `docs/` files
- Fix typos and unclear explanations
- Add examples and tutorials
- Translate to other languages

### 4. Hardware Testing

If you have a Galaxy S20 FE:
- Test build artifacts on your device
- Report testing results (success/failure)
- Provide debug logs and dmesg output
- Share performance benchmarks

## Code Style

### Shell Scripts
- Use `#!/usr/bin/env bash`
- Enable `set -euo pipefail`
- Use descriptive variable names
- Add comments for complex logic

### C/Kernel Code
- Follow Linux kernel coding style
- Use `checkpatch.pl` before submitting kernel patches
- Reference upstream kernel patterns

### Documentation
- Use Markdown format
- Keep lines under 80 characters
- Include code blocks with language tags

## Pull Request Process

1. **Fork** the repository
2. **Create** a feature branch
3. **Make** your changes
4. **Test** thoroughly
5. **Update** documentation
6. **Submit** pull request

### PR Description Template
```markdown
## Description
Brief description of changes

## Motivation
Why is this change needed?

## Testing
How was this tested?
- [ ] Built successfully
- [ ] Tested on hardware

## Screenshots/Logs
If applicable
```

## Project Structure

```
SteamPhone/
├── kernel/          # Kernel configs, DTBs, patches
├── rootfs/          # Root filesystem components
├── drivers/         # Hardware driver documentation
├── gamescope/       # Gamescope compositor port
├── steam/           # Steam client integration
├── input/           # Touchscreen gamepad overlay
├── tools/           # Flashing and utility tools
├── scripts/         # Build and install scripts
└── docs/            # Project documentation
```

## Communication

- GitHub Issues: Bug reports and feature requests
- GitHub Discussions: Questions and community support
- Discord: Real-time chat (link in README)

## License

By contributing, you agree that your contributions will be licensed:
- Kernel components: GPL-2.0
- Userspace tools and scripts: MIT

## Thank You!

Every contribution helps make SteamPhone better for everyone.
