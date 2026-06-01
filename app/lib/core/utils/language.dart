import 'package:flutter/material.dart';

//* Fallback when the device language isn't supported by the geo API
const _kDefaultApiLanguage = 'en';
//* Languages the geo API accepts
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

//* Device language if the geo API supports it, else the default
String resolveApiLanguage(String languageCode) =>
    _kSupportedApiLanguages.contains(languageCode)
    ? languageCode
    : _kDefaultApiLanguage;

//* The device's current language code
String get deviceLanguageCode =>
    WidgetsBinding.instance.platformDispatcher.locale.languageCode;
