import 'package:flutter_riverpod/flutter_riverpod.dart';

// --- Language Provider ---
enum AppLanguage {
  english('English'),
  hindi('Hindi'),
  malayalam('Malayalam');

  final String displayName;
  const AppLanguage(this.displayName);
}

const _hindiMap = {
  'Home': 'होम',
  'Switches': 'स्विच',
  'Timers': 'टाइमर',
  'Settings': 'सेटिंग्स',
  'Help Center': 'सहायता केंद्र',
  'ESP32 Flasher': 'ईएसपी32 फ्लैशर',
  'Dashboard': 'डैशबोर्ड',
  'Schedule': 'शेड्यूल',
  'Language': 'भाषा',
  'Good Morning,': 'सुप्रभात,',
  'Good Afternoon,': 'नमस्कार,',
  'Good Evening,': 'शुभ संध्या,',
  'App Settings': 'ऐप सेटिंग्स',
  'Customize the app to your needs': 'ऐप को अपनी आवश्यकतानुसार अनुकूलित करें',
};

const _malayalamMap = {
  'Home': 'ഹോം',
  'Switches': 'സ്വിച്ചുകൾ',
  'Timers': 'ടൈമറുകൾ',
  'Settings': 'സജ്ജീകരണങ്ങൾ',
  'Help Center': 'സഹായ കേന്ദ്രം',
  'ESP32 Flasher': 'ഇഎസ്പി32 ഫ്ലാഷർ',
  'Dashboard': 'ഡാഷ്ബോർഡ്',
  'Schedule': 'ഷെഡ്യൂൾ',
  'Language': 'ഭാഷ',
  'Good Morning,': 'സുപ്രഭാതം,',
  'Good Afternoon,': 'നമസ്കാരം,',
  'Good Evening,': 'ശുഭ സായാഹ്നം,',
  'App Settings': 'ആപ്പ് സജ്ജീകരണങ്ങൾ',
  'Customize the app to your needs': 'ആപ്പ് നിങ്ങളുടെ ആവശ്യങ്ങൾക്കനുസരിച്ച് ക്രമീകരിക്കുക',
};

extension TranslationExt on String {
  String tr(AppLanguage lang) {
    if (lang == AppLanguage.hindi) {
      return _hindiMap[this] ?? this;
    } else if (lang == AppLanguage.malayalam) {
      return _malayalamMap[this] ?? this;
    }
    return this;
  }
}

class LanguageNotifier extends StateNotifier<AppLanguage> {
  LanguageNotifier() : super(AppLanguage.english);

  void setLanguage(AppLanguage language) {
    state = language;
  }
}

final languageProvider = StateNotifierProvider<LanguageNotifier, AppLanguage>((ref) {
  return LanguageNotifier();
});

// --- Time Format Provider ---
enum TimeFormat {
  h12('12h'),
  h24('24h');

  final String displayName;
  const TimeFormat(this.displayName);
}

class TimeFormatNotifier extends StateNotifier<TimeFormat> {
  TimeFormatNotifier() : super(TimeFormat.h12);

  void setTimeFormat(TimeFormat format) {
    state = format;
  }
}

final timeFormatProvider = StateNotifierProvider<TimeFormatNotifier, TimeFormat>((ref) {
  return TimeFormatNotifier();
});

// --- Notification Providers ---
final pushNotificationProvider = StateProvider<bool>((ref) => true);
final timerNotificationProvider = StateProvider<bool>((ref) => true);
