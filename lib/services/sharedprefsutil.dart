import 'package:shared_preferences/shared_preferences.dart';

class SharedPrefsUtil {
  static const String cur_theme = 'isDark';
  static const String cur_locale = 'cur_locale';
  static const String cur_tab = 'cur_tab';
  static const String cur_fbtoken = 'cur_fbtoken';
  static const String tech_acc = 'tech_acc';
  static const String tech_pass = 'tech_pass';
  static const String tech_lgn = 'tech_lgn';
  static const String tech_stk = 'tech_stk';
  
  // For plain-text data
  Future<void> set(String key, value) async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    if (value is bool) {
      sharedPreferences.setBool(key, value);
    } else if (value is String) {
      sharedPreferences.setString(key, value);
    } else if (value is double) {
      sharedPreferences.setDouble(key, value);
    } else if (value is int) {
      sharedPreferences.setInt(key, value);
    }
  }

  Future<dynamic> get(String key, {dynamic defaultValue}) async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    return sharedPreferences.get(key) ?? defaultValue;
  }

  Future<void> setTheme(bool value) async {
    return await set(cur_theme, value);
  }

  Future<bool> getTheme() async {
    return await get(cur_theme, defaultValue: true);
  }

  Future<void> setLocale(String value) async {
    return await set(cur_locale, value);
  }

  Future<String> getLocale() async {
    return await get(cur_locale, defaultValue: 'en');
  }

  Future<void> setTab(int value) async {
    return await set(cur_tab, value);
  }

  Future<int> getTab() async {
    return await get(cur_tab, defaultValue: 0);
  }

  Future<void> setFirebaseToken(String? value) async {
    return await set(cur_fbtoken, value);
  }

  Future<String> getFirebaseToken() async {
    return await get(cur_fbtoken, defaultValue: '');
  }

  Future<void> setTechcomAccount(String? value) async {
    return await set(tech_acc, value);
  }

  Future<String> getTechcomAccount() async {
    return await get(tech_acc, defaultValue: '');
  }

  Future<void> setTechcomPassword(String? value) async {
    return await set(tech_pass, value);
  }

  Future<String> getTechcomPassword() async {
    return await get(tech_pass, defaultValue: '');
  }

  Future<void> setIsLogTechcom(bool? value) async {
    return await set(tech_lgn, value);
  }

  Future<bool> getIsLogTechcom() async {
    return await get(tech_lgn, defaultValue: false);
  }

  Future<void> setTechcomSTK(String? value) async {
    return await set(tech_stk, value);
  }

  Future<String> getTechcomSTK() async {
    return await get(tech_stk, defaultValue: '');
  }
}