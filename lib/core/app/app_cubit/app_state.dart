part of 'app_cubit.dart';

class AppState with EquatableMixin {
  Locale locale;

  AppState({this.locale = const Locale('en', 'US')});

  factory AppState.initState() => AppState();

  AppState copyWith({
    Locale? locale,
  }) {
    return AppState(
      locale: locale ?? this.locale,
    );
  }

  @override
  List<Object?> get props => [
        locale,
      ];
}
