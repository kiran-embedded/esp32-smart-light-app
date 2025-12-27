# Contributing to Nebula Core

First off, thank you for considering contributing to Nebula Core! 🌌

## 🎯 How Can I Contribute?

### Reporting Bugs

Before creating bug reports, please check existing issues. When creating a bug report, include:

- **Clear title** describing the issue
- **Steps to reproduce** the behavior
- **Expected behavior** vs actual behavior
- **Screenshots** if applicable
- **Environment details**:
  - Flutter version (`flutter --version`)
  - Device/OS version
  - Firebase configuration (without credentials)

### Suggesting Enhancements

Enhancement suggestions are tracked as GitHub issues. When creating an enhancement suggestion:

- **Use a clear title** describing the enhancement
- **Provide detailed description** of the suggested enhancement
- **Explain why** this enhancement would be useful
- **List alternatives** you've considered

### Pull Requests

1. **Fork the repository** and create your branch from `main`
2. **Follow the code style**:
   - Run `dart format .` before committing
   - Run `flutter analyze` and fix any issues
   - Follow [Effective Dart](https://dart.dev/guides/language/effective-dart) guidelines
3. **Test your changes**:
   - Ensure the app builds: `flutter build apk --release`
   - Test on real hardware if possible
   - Add tests if applicable
4. **Update documentation** if needed
5. **Write clear commit messages**:
   ```
   Add feature: Brief description
   
   - Detailed point 1
   - Detailed point 2
   ```
6. **Submit the pull request**

## 🏗️ Development Setup

1. **Clone your fork**:
   ```bash
   git clone https://github.com/YOUR_USERNAME/esp32-smart-light-app.git
   cd esp32-smart-light-app
   ```

2. **Install dependencies**:
   ```bash
   flutter pub get
   ```

3. **Create a feature branch**:
   ```bash
   git checkout -b feature/amazing-feature
   ```

4. **Make your changes** and test

5. **Commit and push**:
   ```bash
   git add .
   git commit -m "Add amazing feature"
   git push origin feature/amazing-feature
   ```

## 📝 Code Style Guidelines

### Dart/Flutter
- Use **meaningful variable names**
- Add **comments** for complex logic
- Keep functions **small and focused**
- Use **const constructors** where possible
- Follow **Flutter widget naming conventions**

### File Organization
```
lib/
├── core/          # Constants, themes, utilities
├── models/        # Data models
├── providers/     # Riverpod state management
├── screens/       # UI screens
├── services/      # Business logic, API calls
└── widgets/       # Reusable widgets
```

## 🧪 Testing

```bash
# Run tests
flutter test

# Run with coverage
flutter test --coverage

# Analyze code
flutter analyze
```

## 🔍 Code Review Process

1. Maintainers will review your PR within **3-5 business days**
2. Address any requested changes
3. Once approved, your PR will be merged
4. Your contribution will be credited in the release notes

## 🌟 Recognition

Contributors will be:
- Listed in the project README
- Mentioned in release notes
- Added to the contributors graph

## 📞 Questions?

- Open a [GitHub Discussion](https://github.com/kiran-embedded/esp32-smart-light-app/discussions)
- Create an issue with the `question` label

## 📜 Code of Conduct

### Our Pledge

We pledge to make participation in our project a harassment-free experience for everyone.

### Our Standards

**Positive behavior includes**:
- Using welcoming and inclusive language
- Being respectful of differing viewpoints
- Gracefully accepting constructive criticism
- Focusing on what is best for the community

**Unacceptable behavior includes**:
- Trolling, insulting/derogatory comments
- Public or private harassment
- Publishing others' private information
- Other conduct which could reasonably be considered inappropriate

### Enforcement

Instances of abusive behavior may be reported to the project maintainers. All complaints will be reviewed and investigated.

---

**Thank you for contributing to Nebula Core!** 🚀
