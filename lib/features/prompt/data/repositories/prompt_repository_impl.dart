import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zero_type/core/constants/app_constants.dart';
import 'package:zero_type/features/prompt/domain/repositories/prompt_repository.dart';

class PromptRepositoryImpl implements PromptRepository {
  PromptRepositoryImpl({required SharedPreferences prefs}) : _prefs = prefs;

  final SharedPreferences _prefs;

  String _getLanguage() {
    return _prefs.getString(AppConstants.speechLanguageKey) ?? 'zh';
  }

  String _getPromptPrefsKey() {
    final lang = _getLanguage();
    return lang == 'vi' ? '${AppConstants.speechPromptKey}_vi' : AppConstants.speechPromptKey;
  }

  Future<File> _getCustomPromptFile() async {
    final dir = await getApplicationSupportDirectory();
    final lang = _getLanguage();
    final suffix = lang == 'vi' ? '_vi' : '';
    return File('${dir.path}/SpeechToText_Custom$suffix.prompt');
  }

  @override
  Future<String> getDefaultSpeechPrompt() async {
    final lang = _getLanguage();
    final assetPath = lang == 'vi' ? 'prompts/SpeechToText_vi.prompt' : 'prompts/SpeechToText.prompt';
    try {
      final content = await rootBundle.loadString(assetPath);
      return content.trim();
    } catch (e) {
      print('[PromptRepo] ERROR loading $assetPath from assets: $e');
    }
    return lang == 'vi'
        ? 'Hãy chuyển ngữ âm thành văn bản tiếng Việt chính xác và thêm dấu câu thích hợp.'
        : '請將語音精確轉換成繁體中文，並依語意加上適當的標點符號。';
  }

  @override
  Future<String> getSpeechPrompt() async {
    try {
      final file = await _getCustomPromptFile();
      if (await file.exists()) {
        final content = (await file.readAsString()).trim();
        if (content.isNotEmpty) return content;
      }
    } catch (e) {
      print('[PromptRepo] Error reading custom prompt: $e');
    }
    return await getDefaultSpeechPrompt();
  }

  @override
  Future<String> saveSpeechPrompt(String prompt) async {
    final cleaned = prompt.trim();
    try {
      final file = await _getCustomPromptFile();
      await file.writeAsString(cleaned, flush: true);
    } catch (e) {
      print('[PromptRepo] Error saving custom prompt: $e');
    }
    await _prefs.setString(_getPromptPrefsKey(), cleaned);
    return cleaned;
  }

  @override
  Future<String> resetSpeechPrompt() async {
    try {
      final file = await _getCustomPromptFile();
      if (await file.exists()) await file.delete();
    } catch (e) {
      print('[PromptRepo] Error deleting custom prompt: $e');
    }
    await _prefs.remove(_getPromptPrefsKey());
    return await getDefaultSpeechPrompt();
  }
}
