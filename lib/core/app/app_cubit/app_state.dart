part of 'app_cubit.dart';

class AppState extends Equatable {
  final Locale locale;
  final int sessionExpiryRevision;

  const AppState({
    this.locale = const Locale('en', 'US'),
    this.sessionExpiryRevision = 0,
  });

  factory AppState.initState() => const AppState();

  AppState copyWith({Locale? locale, int? sessionExpiryRevision}) {
    return AppState(
      locale: locale ?? this.locale,
      sessionExpiryRevision:
          sessionExpiryRevision ?? this.sessionExpiryRevision,
    );
  }

  @override
  List<Object?> get props => [locale, sessionExpiryRevision];
}
