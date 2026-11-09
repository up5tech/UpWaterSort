/// Localised UI strings (PLAN.md §21 Phase 5, decision 2026-11-08: a plain
/// string map in `lib/core`, no code generation).
///
/// Widgets read the current locale from `SettingsController` and call
/// [stringsFor]. The map lives here so both controllers and UI can share it
/// without importing Flutter localizations.
abstract class AppStrings {
  const AppStrings();

  String get locale;
  String get appName;
  String get continueGame;
  String get selectLevel;
  String get settings;
  String get sound;
  String get vibration;
  String get colorBlindMode;
  String get darkMode;
  String get language;
  String get resetData;
  String get resetConfirmTitle;
  String get resetConfirmBody;
  String get resetDone;
  String get cancel;
  String get reset;
  String get undo;
  String get restart;
  String get hint;
  String get addTube;
  String get noLevels;
  String get stuckTitle;
  String get stuckBody;
  String get hintUnavailable;
  String get allLevelsDone;
  String get menu;
  String get replay;
  String get nextLevel;

  String stars(int count);
  String levelTitle(int level);
  String moves(int count);
  String hintMove(int from, int to);
  String winTitle(int level);
  String winStats(int moves, int par);
  String tubeLabel(int number);

  static AppStrings forLocale(String locale) =>
      locale == 'vi' ? const _StringsVi() : const _StringsEn();
}

class _StringsEn extends AppStrings {
  const _StringsEn();

  @override
  String get locale => 'en';
  @override
  String get appName => 'UpWaterSort';
  @override
  String get continueGame => 'Continue';
  @override
  String get selectLevel => 'Select level';
  @override
  String get settings => 'Settings';
  @override
  String get sound => 'Sound effects';
  @override
  String get vibration => 'Vibration';
  @override
  String get colorBlindMode => 'Color-blind mode';
  @override
  String get darkMode => 'Dark theme';
  @override
  String get language => 'Language';
  @override
  String get resetData => 'Reset data';
  @override
  String get resetConfirmTitle => 'Reset all progress?';
  @override
  String get resetConfirmBody =>
      'Stars, unlocked levels and settings return to their defaults.';
  @override
  String get resetDone => 'Progress and settings were reset.';
  @override
  String get cancel => 'Cancel';
  @override
  String get reset => 'Reset';
  @override
  String get undo => 'Undo';
  @override
  String get restart => 'Restart';
  @override
  String get hint => 'Hint';
  @override
  String get addTube => 'Add tube';
  @override
  String get noLevels => 'No levels available.';
  @override
  String get stuckTitle => 'No moves left';
  @override
  String get stuckBody =>
      'Undo a move, add an extra tube, or restart this level.';
  @override
  String get hintUnavailable => 'No hint found, try Undo.';
  @override
  String get allLevelsDone => 'You finished all the bundled levels.';
  @override
  String get menu => 'Menu';
  @override
  String get replay => 'Replay';
  @override
  String get nextLevel => 'Next level';

  @override
  String stars(int count) => '$count stars';
  @override
  String levelTitle(int level) => 'Level $level';
  @override
  String moves(int count) => 'Moves $count';
  @override
  String hintMove(int from, int to) => 'Pour tube $from into tube $to';
  @override
  String winTitle(int level) => 'Level $level complete!';
  @override
  String winStats(int moves, int par) => 'Moves: $moves   Par: $par';
  @override
  String tubeLabel(int number) => 'Tube $number';
}

class _StringsVi extends AppStrings {
  const _StringsVi();

  @override
  String get locale => 'vi';
  @override
  String get appName => 'UpWaterSort';
  @override
  String get continueGame => 'Tiếp tục';
  @override
  String get selectLevel => 'Chọn màn';
  @override
  String get settings => 'Cài đặt';
  @override
  String get sound => 'Âm thanh';
  @override
  String get vibration => 'Rung';
  @override
  String get colorBlindMode => 'Chế độ mù màu';
  @override
  String get darkMode => 'Giao diện tối';
  @override
  String get language => 'Ngôn ngữ';
  @override
  String get resetData => 'Xoá dữ liệu';
  @override
  String get resetConfirmTitle => 'Xoá toàn bộ tiến trình?';
  @override
  String get resetConfirmBody =>
      'Sao, màn đã mở và cài đặt sẽ trở về mặc định.';
  @override
  String get resetDone => 'Đã xoá dữ liệu và cài đặt.';
  @override
  String get cancel => 'Huỷ';
  @override
  String get reset => 'Xoá';
  @override
  String get undo => 'Hoàn tác';
  @override
  String get restart => 'Chơi lại';
  @override
  String get hint => 'Gợi ý';
  @override
  String get addTube => 'Thêm ống';
  @override
  String get noLevels => 'Không có màn chơi.';
  @override
  String get stuckTitle => 'Hết nước đi';
  @override
  String get stuckBody => 'Hoàn tác, thêm ống hoặc chơi lại màn này.';
  @override
  String get hintUnavailable => 'Không tìm thấy gợi ý, thử hoàn tác.';
  @override
  String get allLevelsDone => 'Bạn đã hoàn thành toàn bộ màn có sẵn.';
  @override
  String get menu => 'Menu';
  @override
  String get replay => 'Chơi lại';
  @override
  String get nextLevel => 'Màn tiếp';

  @override
  String stars(int count) => '$count sao';
  @override
  String levelTitle(int level) => 'Màn $level';
  @override
  String moves(int count) => 'Lượt $count';
  @override
  String hintMove(int from, int to) => 'Rót ống $from sang ống $to';
  @override
  String winTitle(int level) => 'Hoàn thành màn $level!';
  @override
  String winStats(int moves, int par) => 'Lượt: $moves   Chuẩn: $par';
  @override
  String tubeLabel(int number) => 'Ống $number';
}

/// Convenience for the current locale code.
AppStrings stringsFor(String locale) => AppStrings.forLocale(locale);
