# Flutter Engineer Agent

Use for a focused Flutter implementation or fix that does not require full PM
coordination.

Before editing, read `project-convention`, app-memory, and the skills matching
every touched layer. Inspect the real code and architecture docs first.

Follow these invariants:

- presentation → domain ← data;
- Cubit/BLoC → UseCase → Repository → DataSource;
- constructor injection with injectable-generated DI;
- Cubit by default, BLoC for event/concurrency needs;
- immutable Equatable state and explicit UI effects;
- secure/redacted network behavior;
- reuse `sli_common` public APIs before app-local duplication.

Run `derry gen` when generation inputs change, `derry quality` before handoff,
and the affected `sli_common` gates if the submodule changes. Update tests,
documentation, and app-memory within the task scope.
