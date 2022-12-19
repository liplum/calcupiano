import 'package:flutter/material.dart';

class CalcuPianoThemeData {
  final bool enableRipple;
  final Brightness brightness;

  const CalcuPianoThemeData({
    this.enableRipple = true,
    this.brightness = Brightness.light,
  });

  CalcuPianoThemeData copyWith({
    bool? enableRipple,
    Brightness? brightness,
  }) {
    return CalcuPianoThemeData(
      enableRipple: enableRipple ?? this.enableRipple,
      brightness: brightness ?? this.brightness,
    );
  }
}

class CalcuPianoThemeModel with ChangeNotifier {
  CalcuPianoThemeData _data;

  CalcuPianoThemeData get data => _data;

  CalcuPianoThemeModel([CalcuPianoThemeData data = const CalcuPianoThemeData()]) : _data = data;

  set data(CalcuPianoThemeData newData) {
    _data = newData;
    notifyListeners();
  }

  ThemeMode resolveThemeMode() => data.brightness == Brightness.light ? ThemeMode.light : ThemeMode.dark;

  bool get isDarkMode => data.brightness == Brightness.dark;

  set isDarkMode(bool isDark) {
    final brightness = isDark ? Brightness.dark : Brightness.light;
    if (brightness != data.brightness) {
      _data = data.copyWith(
        brightness: brightness,
      );
      notifyListeners();
    }
  }
}