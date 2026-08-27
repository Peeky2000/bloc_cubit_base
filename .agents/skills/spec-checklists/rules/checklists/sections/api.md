# Rules — API / DataSource Checklist

Create when spec §6.4 contains an in-scope endpoint or local persistence change.
Verify paths under `lib/data/datasource/`. Document ApiHandler method, endpoint,
request/response models, parser, errors, DI annotation, redaction/security, and
unit tests. Do not specify Retrofit or a presentation-layer data path.
