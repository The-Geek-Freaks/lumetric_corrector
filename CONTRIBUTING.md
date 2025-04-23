# Contributing to Lumetric Corrector

We love your input! We want to make contributing to Lumetric Corrector as easy and transparent as possible, whether it's:

- Reporting a bug
- Discussing the current state of the code
- Submitting a fix
- Proposing new features
- Becoming a maintainer

## Development Process

We use GitHub to host code, to track issues and feature requests, as well as accept pull requests.

### Pull Requests

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Add your changes and commit them (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Lua Style Guide

When contributing code, please follow these Lua style guidelines:

- Use local variables whenever possible
- Use 4 spaces for indentation (not tabs)
- Variables and functions in snake_case
- Constants in UPPER_CASE
- Add comments for complex functionality
- Follow OBS Lua API conventions for callbacks and data structures

### Testing

Before submitting your code, please test it thoroughly with OBS Studio:
- Test with different resolutions and frame rates
- Verify behavior with various source types
- Check for any performance impacts during streaming/recording

## Bug Reports and Feature Requests

We use GitHub issues to track public bugs and feature requests. Report a bug or suggest a feature by opening a new issue.

### Bug Reports

When reporting bugs, please include:
- A clear description of the issue
- Steps to reproduce the behavior
- Expected behavior
- Screenshots if applicable
- Your environment (OS, OBS version, etc.)

### Feature Requests

When suggesting features, please include:
- A clear description of what you want to happen
- Justification for why this would be useful to most users
- Any relevant examples from other software

## Localization Contributions

If you'd like to contribute translations:
- Add the new language code to the translations table
- Provide translations for all existing keys
- Test the new language in OBS Studio
- Follow the existing format for language code naming (e.g., "en-US", "de-DE")

***Note:*** When implementing file handling for localization, avoid using `os_enumerate_files` as it may cause loading errors in OBS. Instead, manually specify known localization files and check them individually.

## License

By contributing, you agree that your contributions will be licensed under the project's GPLv3 License.
