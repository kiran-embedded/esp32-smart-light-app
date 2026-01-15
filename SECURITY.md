# Security Policy

## 🔒 Supported Versions

Currently supported versions with security updates:

| Version | Supported          |
| ------- | ------------------ |
| 1.0.x   | :white_check_mark: |

## 🛡️ Reporting a Vulnerability

We take security seriously. If you discover a security vulnerability, please follow these steps:

### 1. **DO NOT** Open a Public Issue

Security vulnerabilities should **not** be reported through public GitHub issues.

### 2. Report Privately

Send an email to: **kiran.cybergrid@gmail.com**

Include:
- Description of the vulnerability
- Steps to reproduce
- Potential impact
- Suggested fix (if any)

### 3. Response Timeline

- **Initial Response**: Within 48 hours
- **Status Update**: Within 7 days
- **Fix Timeline**: Depends on severity
  - **Critical**: 1-3 days
  - **High**: 1-2 weeks
  - **Medium**: 2-4 weeks
  - **Low**: Next release cycle

### 4. Disclosure Policy

- We will acknowledge your report within 48 hours
- We will provide regular updates on our progress
- We will notify you when the vulnerability is fixed
- We will credit you in the security advisory (unless you prefer to remain anonymous)

## 🔐 Security Best Practices

### For Users

#### Firebase Configuration
- **Never commit** `google-services.json` to public repositories
- Use **Firebase Security Rules** to restrict database access:
  ```json
  {
    "rules": {
      "devices": {
        "$deviceId": {
          "commands": {
            ".read": true,
            ".write": true
          },
          "telemetry": {
            ".read": true,
            ".write": true
          },
          "relayNames": {
            ".read": true,
            ".write": true
          }
        }
      }
    }
  }
  ```
- Enable **App Check** in Firebase Console for production
- Rotate **Firebase API keys** regularly

#### Authentication
- Use **strong passwords** for Google accounts
- Enable **2-factor authentication** on GitHub and Google
- Don't share **Personal Access Tokens**
- Use **environment variables** for sensitive data

#### ESP32 Security
- Change **default WiFi credentials** in firmware
- Use **Firebase Database Secrets** (not API keys in firmware)
- Enable **HTTPS/TLS** for all communications
- Update **ESP32 firmware** regularly

### For Developers

#### Code Security
- Run `flutter analyze` before committing
- Use **const constructors** to prevent runtime modifications
- Validate **all user inputs**
- Sanitize **data from Firebase**
- Use **try-catch** blocks for error handling

#### Dependency Security
```bash
# Check for vulnerable dependencies
flutter pub outdated

# Update dependencies
flutter pub upgrade
```

#### Secrets Management
- Use **flutter_dotenv** for local development
- Never hardcode:
  - API keys
  - Database URLs
  - OAuth client secrets
  - Firebase credentials
- Use **GitHub Secrets** for CI/CD

## 🚨 Known Security Considerations

### Current Limitations

1. **Single Device ID**: App currently defaults to `79215788`
   - **Mitigation**: Configure unique device IDs in `app_constants.dart`
   
2. **No User Management**: All users share same Firebase database
   - **Mitigation**: Implement Firebase Security Rules based on auth.uid
   
3. **Test Mode Database**: Default Firebase rules allow all read/write
   - **Mitigation**: Update rules before production deployment

### Recommended Production Setup

```json
// Firebase Realtime Database Rules
{
  "rules": {
    "devices": {
      "$deviceId": {
        "commands": {
          ".read": true,
          ".write": true
        },
        "telemetry": {
          ".read": true,
          ".write": true
        },
        "relayNames": {
          ".read": true,
          ".write": true
        }
      }
    }
  }
}
```

## 📋 Security Checklist

Before deploying to production:

- [ ] Update Firebase Security Rules
- [ ] Enable Firebase App Check
- [ ] Remove debug logging
- [ ] Obfuscate code: `flutter build apk --obfuscate --split-debug-info=build/debug-info`
- [ ] Enable ProGuard (Android)
- [ ] Use release signing keys
- [ ] Implement rate limiting
- [ ] Add input validation
- [ ] Enable HTTPS only
- [ ] Review third-party dependencies
- [ ] Conduct security audit

## 🔍 Security Audit History

| Date       | Auditor | Findings | Status |
|------------|---------|----------|--------|
| 2025-12-27 | Internal | Initial release | ✅ Resolved |

## 📞 Contact

For security concerns: **kiran.cybergrid@gmail.com**

For general questions: [GitHub Discussions](https://github.com/kiran-embedded/esp32-smart-light-app/discussions)

---

**Thank you for helping keep Nebula Core secure!** 🛡️
