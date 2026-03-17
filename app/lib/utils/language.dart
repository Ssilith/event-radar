import 'package:flutter/material.dart';

const _kDefaultApiLanguage = 'en';
const _kSupportedApiLanguages = {
  'en',
  'es',
  'pt',
  'it',
  'fr',
  'de',
  'ru',
  'uk',
};

String resolveApiLanguage(String languageCode) =>
    _kSupportedApiLanguages.contains(languageCode)
    ? languageCode
    : _kDefaultApiLanguage;

String get deviceLanguageCode =>
    WidgetsBinding.instance.platformDispatcher.locale.languageCode;
