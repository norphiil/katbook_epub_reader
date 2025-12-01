# Contributing to Katbook EPUB Reader

Thank you for your interest in contributing to Katbook EPUB Reader! We welcome contributions from the community and are grateful for any help you can provide.

## Table of Contents

- [Contributing to Katbook EPUB Reader](#contributing-to-katbook-epub-reader)
  - [Table of Contents](#table-of-contents)
  - [Code of Conduct](#code-of-conduct)
  - [Getting Started](#getting-started)
  - [How to Contribute](#how-to-contribute)
    - [Types of Contributions](#types-of-contributions)
  - [Development Setup](#development-setup)
  - [Pull Request Process](#pull-request-process)
  - [Coding Guidelines](#coding-guidelines)
    - [Dart Style](#dart-style)
    - [Code Structure](#code-structure)
    - [Documentation](#documentation)
  - [Reporting Bugs](#reporting-bugs)
  - [Suggesting Features](#suggesting-features)
  - [Questions?](#questions)

## Code of Conduct

By participating in this project, you agree to maintain a respectful and inclusive environment for everyone. Please be kind and courteous to other contributors.

## Getting Started

1. Fork the repository on GitHub
2. Clone your fork locally:
   ```bash
   git clone https://github.com/YOUR_USERNAME/katbook_epub_reader.git
   ```
3. Add the upstream repository as a remote:
   ```bash
   git remote add upstream https://github.com/norphiil/katbook_epub_reader.git
   ```

## How to Contribute

### Types of Contributions

- **Bug fixes**: Help us squash bugs and improve stability
- **New features**: Add new functionality to the reader
- **Documentation**: Improve README, add examples, or fix typos
- **Tests**: Add or improve test coverage
- **Performance**: Optimize parsing or rendering

## Development Setup

1. Ensure you have Flutter installed (latest stable version recommended)
2. Install dependencies:
   ```bash
   flutter pub get
   ```
3. Run the example app to test your changes:
   ```bash
   cd example
   flutter run
   ```
4. Run analysis to check for issues:
   ```bash
   dart analyze
   ```

## Pull Request Process

1. Create a new branch for your feature or fix:
   ```bash
   git checkout -b feature/your-feature-name
   ```
   or
   ```bash
   git checkout -b fix/your-bug-fix
   ```

2. Make your changes and commit them with clear, descriptive messages:
   ```bash
   git commit -m "feat: add support for EPUB 3 navigation"
   ```
   
   We follow [Conventional Commits](https://www.conventionalcommits.org/) format:
   - `feat:` for new features
   - `fix:` for bug fixes
   - `docs:` for documentation changes
   - `refactor:` for code refactoring
   - `test:` for adding tests
   - `chore:` for maintenance tasks

3. Push your branch to your fork:
   ```bash
   git push origin feature/your-feature-name
   ```

4. Open a Pull Request against the `main` branch

5. Ensure your PR:
   - Has a clear title and description
   - References any related issues
   - Passes all CI checks
   - Has no merge conflicts

## Coding Guidelines

### Dart Style

- Follow the official [Dart Style Guide](https://dart.dev/guides/language/effective-dart/style)
- Run `dart format .` before committing
- Ensure `dart analyze` passes with no issues

### Code Structure

- Keep files focused and single-purpose
- Use meaningful variable and function names
- Add documentation comments for public APIs
- Follow the existing project structure:
  ```
  lib/
  ├── src/
  │   ├── controller/    # State management
  │   ├── models/        # Data models
  │   ├── parser/        # EPUB parsing logic
  │   └── widgets/       # UI components
  ```

### Documentation

- Add dartdoc comments to all public classes and methods
- Include examples in documentation when helpful
- Update README.md if adding new features

## Reporting Bugs

When reporting bugs, please include:

1. **Description**: A clear and concise description of the bug
2. **Steps to Reproduce**: Numbered steps to reproduce the issue
3. **Expected Behavior**: What you expected to happen
4. **Actual Behavior**: What actually happened
5. **Environment**:
   - Flutter version (`flutter --version`)
   - Platform (iOS, Android, Web, Desktop)
   - Package version
6. **EPUB Sample**: If possible, provide a sample EPUB that reproduces the issue (or describe its structure)

Use the GitHub Issues template if available.

## Suggesting Features

We love hearing ideas for new features! When suggesting a feature:

1. Check existing issues to avoid duplicates
2. Clearly describe the feature and its use case
3. Explain why it would be valuable to other users
4. If possible, outline how it might be implemented

## Questions?

If you have questions about contributing, feel free to:
- Open a GitHub Discussion
- Create an issue with the `question` label

Thank you for contributing to Katbook EPUB Reader! 🎉
