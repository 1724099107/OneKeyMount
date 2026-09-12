# Contributing to OneKeyMount

Thanks for your interest in improving OneKeyMount! This document outlines the
workflow and conventions used by the project.

## Getting Started

1. Fork the repository on GitHub.
2. Clone your fork:

   ```bash
   git clone https://github.com/<your-username>/OneKeyMount.git
   cd OneKeyMount
   ```

3. Create a feature branch:

   ```bash
   git checkout -b feature/my-feature
   ```

## Development Guidelines

### Code style

- POSIX-friendly `bash` where possible
- Quote all variable expansions: `"$var"`
- Prefer `[[ ]]` over `[ ]`
- Use `set -euo pipefail` at the top of every script
- Keep functions small and self-documenting
- No trailing whitespace; use LF line endings

### Testing

Before submitting a PR, please verify:

1. `shellcheck OneKeyMount.sh` runs clean.
2. The script runs on a fresh VM or container without errors.
3. Both **English** and **Chinese** prompts render correctly.
4. Both **Mode 1** (mount existing) and **Mode 2** (wipe & format) work as expected on a test disk.
5. `/etc/fstab` is correctly updated and `mount -a` exits cleanly.

### Commit messages

Use clear, imperative commit messages:

```
Add xfs support for Mode 2
Fix fstab backup path on SELinux systems
```

### Localization

The script currently supports `en` and `zh`. To add a new locale:

1. Add a `MSG_XX` associative array in `OneKeyMount.sh`.
2. Add the language to the `select_language` menu.
3. Update the `t()` function to recognize the new locale.
4. Update `README.md` and `CREADME.md` if necessary.

## Submitting a Pull Request

1. Push your branch: `git push origin feature/my-feature`
2. Open a Pull Request against `main`.
3. Fill in the PR template describing:
   - What you changed and why
   - How you tested it
   - Any known limitations or follow-ups

## Reporting Issues

When filing a bug, please include:

- Distribution and version (`cat /etc/os-release`)
- Bash version (`bash --version`)
- Output of `lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINT`
- The full script output (redact UUIDs if desired)
- What you expected vs. what happened

## Code of Conduct

Be respectful. This project follows the
[Contributor Covenant](https://www.contributor-covenant.org/version/2/1/code_of_conduct/)
in spirit. Harassment or discriminatory behavior will not be tolerated.
