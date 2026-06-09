# Rule: Model Files Must Not Import Drift

**Why:** Models live in `shared/models/{domain}/` and are used across all layers.
Importing Drift (a database library) into a Model file couples the shared data class
to a specific persistence implementation. Drift table definitions and mapping logic
belong in `core/database/`, and the mapping between Models and Drift companions
lives in `core/database/mappers/` as extension methods.

---

## Bad

```dart
// shared/models/transaction/transaction.dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:drift/drift.dart'; // BAD -- Drift in a model file

part 'transaction.freezed.dart';
part 'transaction.g.dart';

@freezed
abstract class Transaction with _$Transaction {
  const factory Transaction({
    required String id,
    required double amount,
  }) = _Transaction;

  factory Transaction.fromJson(Map<String, dynamic> json) =>
      _$TransactionFromJson(json);

  // BAD -- Drift mapping inside the model
  TransactionsCompanion toDriftCompanion() => TransactionsCompanion(
    id: Value(id),
    amount: Value(amount),
  );
}
```

---

## Good

```dart
// shared/models/transaction/transaction.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'transaction.freezed.dart';
part 'transaction.g.dart';

@freezed
abstract class Transaction with _$Transaction {
  const factory Transaction({
    required String id,
    required double amount,
  }) = _Transaction;

  factory Transaction.fromJson(Map<String, dynamic> json) =>
      _$TransactionFromJson(json);
}
```

```dart
// core/database/mappers/transaction_mapper.dart
import 'package:drift/drift.dart';
import '../tables/transactions_table.dart';
import '../../../shared/models/transaction/transaction.dart';

extension TransactionMapper on Transaction {
  TransactionsCompanion toDriftCompanion() => TransactionsCompanion(
    id: Value(id),
    amount: Value(amount),
  );
}

extension TransactionRowMapper on TransactionRow {
  Transaction toModel() => Transaction(
    id: id,
    amount: amount,
  );
}
```

---

## Summary

| Concern | Where it lives |
|---|---|
| Model class (`@freezed` + `fromJson`) | `shared/models/{domain}/` |
| Drift table definition | `core/database/tables/` |
| Model-to-Drift mapping | `core/database/mappers/` |
