# Contributing to vpnctl

## Commit Message Guidelines

This project uses [Conventional Commits](https://www.conventionalcommits.org/) for automated versioning and releases.

### Commit Message Format

```
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

### Types

- **feat**: A new feature (triggers MINOR version bump)
- **fix**: A bug fix (triggers PATCH version bump)
- **docs**: Documentation only changes
- **style**: Changes that do not affect the meaning of the code
- **refactor**: A code change that neither fixes a bug nor adds a feature
- **perf**: A code change that improves performance (triggers PATCH version bump)
- **test**: Adding missing tests or correcting existing tests
- **chore**: Changes to the build process or auxiliary tools

### Scopes

Common scopes for this project:
- **completion**: Bash completion related changes
- **backup**: Backup/restore functionality
- **config**: Configuration handling
- **install**: Installation/uninstallation scripts
- **test**: Test-related changes
- **ci**: CI/CD pipeline changes

### Examples

```bash
feat: add backup-stats command
fix(completion): handle missing config gracefully
docs: update installation instructions
test: add coverage for prepare_sudo function
chore(ci): update GitHub Actions to v4
```

### Breaking Changes

To trigger a MAJOR version bump, use one of these approaches:

1. Add `!` after the type/scope:
   ```
   feat!: remove deprecated backup format
   ```

2. Add `BREAKING CHANGE:` in the footer:
   ```
   feat: update backup format
   
   BREAKING CHANGE: old backup files are no longer compatible
   ```

### Setting up commit template

To use the provided commit message template:

```bash
git config commit.template .gitmessage
```

## Development Workflow

1. **Fork and clone** the repository
2. **Create a feature branch** from master
3. **Make your changes** following the code style
4. **Add tests** if applicable
5. **Run tests** locally: `./tests/run_tests.sh`
6. **Commit** using conventional commit format
7. **Push** and create a Pull Request

## Testing

Before submitting changes:

```bash
# Run all tests
./tests/run_tests.sh

# Run with coverage
./tests/coverage.sh run

# Run shellcheck
shellcheck bin/vpnctl tests/*.sh
```

## Release Process

Releases are automated via GitHub Actions when commits are pushed to master:

- **feat** commits → MINOR version bump (e.g., 2.1.0 → 2.2.0)
- **fix** commits → PATCH version bump (e.g., 2.1.0 → 2.1.1)
- **Breaking changes** → MAJOR version bump (e.g., 2.1.0 → 3.0.0)

The release workflow:
1. Runs all tests and quality checks
2. Analyzes commit messages since last release
3. Determines next version number
4. Generates changelog
5. Creates GitHub release with assets
6. Updates CHANGELOG.md

## Code Style

- Follow existing shell script conventions
- Use shellcheck for validation
- Add comments for complex logic
- Keep functions focused and testable
- Use meaningful variable names