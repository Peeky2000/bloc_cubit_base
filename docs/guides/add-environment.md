# Add an Environment

1. Add a value to `AppEnvironment` only if it has a distinct deployment/config
   lifecycle—not merely a different developer URL.
2. Define defaults and validation in `lib/core/app/app_config.dart`.
3. Add a minimal `lib/main_<environment>.dart` that only selects the environment
   and calls `bootstrap()`.
4. Add matching Derry run/build commands and CI/release ownership if applicable.
5. Add Firebase/native configuration outside source control where secrets or
   signing material are involved.
6. Test invalid URL, production HTTPS, and inspector restrictions.

Use `--dart-define` for runtime values. Do not add asset `.env` files or read
configuration ad hoc from Widgets, Cubits, repositories, or data sources.
