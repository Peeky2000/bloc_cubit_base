# Choose Cubit or BLoC

Use the smallest state machine that makes behavior explicit.

| Signal | Cubit | Classic BLoC |
|---|---:|---:|
| Button/form methods and linear async flow | ✓ | |
| A few commands from one screen | ✓ | |
| Named events from several producers | | ✓ |
| Debounce, restartable, droppable, sequential semantics | | ✓ |
| Audit/replay vocabulary matters | | ✓ |
| Simple CRUD screen | ✓ | |

Both extend the base primitives, receive UseCases through constructors, emit
immutable Equatable state, and remain independent of BuildContext/navigation.

Do not choose BLoC because it looks more “enterprise,” and do not force Cubit
when concurrent events would otherwise require fragile flags. Record the reason
in the feature spec or a short code comment when it is not obvious.
