import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zero_type/core/constants/app_constants.dart';
import 'package:zero_type/core/di/injection.dart';
import 'package:zero_type/features/prompt/presentation/controllers/prompt_controller.dart';

final speechLanguageProvider = StateNotifierProvider<SpeechLanguageNotifier, String>((ref) {
  return SpeechLanguageNotifier(ref: ref);
});

class SpeechLanguageNotifier extends StateNotifier<String> {
  SpeechLanguageNotifier({required this.ref}) : super('zh') {
    _load();
  }

  final Ref ref;

  void _load() {
    final prefs = getIt<SharedPreferences>();
    state = prefs.getString(AppConstants.speechLanguageKey) ?? 'zh';
  }

  Future<void> setLanguage(String lang) async {
    final prefs = getIt<SharedPreferences>();
    await prefs.setString(AppConstants.speechLanguageKey, lang);
    state = lang;
    // 讓提示詞控制器失效以重新載入該語系的提示詞範本
    ref.invalidate(speechPromptControllerProvider);
  }
}
