---
name: Poultry Accounting Codebase
description: How to work with the poultry accounting Flutter desktop app — adding features, pages, components, and handling data.
---

# Poultry Accounting — Agent Skill

## What This Project Does

Poultry Accounting is a **desktop-first Flutter application** (Windows/macOS/Web) for managing a poultry distribution business. It handles customer management, supplier tracking, sales invoicing, purchase orders, payments/receipts, expense tracking, salary management, stock processing (live chicken → slaughtered → cuts), daily pricing, annual inventory, partnership profit distribution, and a full double-entry accounting module (chart of accounts, journal entries, trial balance, balance sheet, income statement, ledger, credit notes, reconciliation). All data is stored locally in SQLite via Drift ORM, state is managed with Riverpod, and the UI is Arabic-first (Cairo font, RTL, locale `ar_AE`).

---

## How to Add a New Feature (Step-by-Step)

Use this checklist every time you add a new feature (e.g., "Wastage Tracking"):

### Step 1: Create the Domain Entity
**File**: `lib/backend/domain/entities/wastage.dart`

```dart
import 'package:meta/meta.dart';

@immutable
class Wastage {
  const Wastage({
    required this.productId,
    required this.quantity,
    required this.wastageDate,
    this.id,
    this.reason,
    this.createdBy,
    this.createdAt,
  });

  final int? id;
  final int productId;
  final double quantity;
  final DateTime wastageDate;
  final String? reason;
  final int? createdBy;
  final DateTime? createdAt;

  Wastage copyWith({...}) { ... }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Wastage && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
```

### Step 2: Create the Abstract Repository
**File**: `lib/backend/domain/repositories/wastage_repository.dart`

```dart
import 'package:poultry_accounting/backend/domain/entities/wastage.dart';

abstract class WastageRepository {
  Future<List<Wastage>> getAllWastages();
  Stream<List<Wastage>> watchAllWastages();
  Future<int> createWastage(Wastage wastage);
  Future<void> deleteWastage(int id);
}
```

### Step 3: Add Drift Table (if new table needed)
**File**: `lib/backend/data/database/database.dart`

Add a new table class and include it in the `@DriftDatabase(tables: [...])` annotation. Run `dart run build_runner build` to regenerate.

### Step 4: Create the Repository Implementation
**File**: `lib/backend/data/repositories/wastage_repository_impl.dart`

```dart
import 'package:poultry_accounting/backend/data/database/database.dart' as db;
import 'package:poultry_accounting/backend/domain/entities/wastage.dart';
import 'package:poultry_accounting/backend/domain/repositories/wastage_repository.dart';

class WastageRepositoryImpl implements WastageRepository {
  WastageRepositoryImpl(this.database);
  final db.AppDatabase database;

  // ... implement methods using database.select(), database.into(), etc.

  // Private mappers at the bottom:
  Wastage _mapToEntity(db.WastageTableData row) { ... }
}
```

### Step 5: Update Barrel Exports
1. **`lib/backend/domain/domain.dart`** — add:
   ```dart
   export 'entities/wastage.dart';
   export 'repositories/wastage_repository.dart';
   ```
2. **`lib/backend/data/repositories/repositories.dart`** — add:
   ```dart
   export 'wastage_repository_impl.dart';
   ```

### Step 6: Register the Riverpod Provider
**File**: `lib/core/providers/database_providers.dart`

```dart
final wastageRepositoryProvider = Provider<WastageRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return WastageRepositoryImpl(db);
});

final wastagesStreamProvider = StreamProvider<List<Wastage>>((ref) {
  final repo = ref.watch(wastageRepositoryProvider);
  return repo.watchAllWastages();
});
```

### Step 7: Create the Screen(s)
**File**: `lib/frontend/presentation/wastage/wastage_list_screen.dart`

(See "How to Add a New Page" below)

### Step 8: Add Navigation
In `lib/frontend/presentation/home/home_screen.dart`, add a drawer item or expansion tile child pointing to the new screen.

---

## How to Add a New Page/Route

1. **Create a new folder** under `lib/frontend/presentation/<feature_name>/`
2. **Create the screen file**: `<feature_name>_screen.dart`
3. **Use `ConsumerWidget`** (or `ConsumerStatefulWidget` if local state needed):
   ```dart
   import 'package:flutter/material.dart';
   import 'package:flutter_riverpod/flutter_riverpod.dart';

   class WastageListScreen extends ConsumerWidget {
     const WastageListScreen({super.key});

     @override
     Widget build(BuildContext context, WidgetRef ref) {
       final wastagesAsync = ref.watch(wastagesStreamProvider);

       return Scaffold(
         appBar: AppBar(
           title: const Text('سجل الهدر'),      // Arabic title
           backgroundColor: Colors.orange,       // Feature-specific color
         ),
         body: wastagesAsync.when(
           loading: () => const Center(child: CircularProgressIndicator()),
           error: (err, stack) => Center(child: Text('خطأ: $err')),
           data: (wastages) {
             if (wastages.isEmpty) {
               return const Center(child: Text('لا توجد سجلات'));
             }
             return ListView.builder(...);
           },
         ),
       );
     }
   }
   ```
4. **Add navigation** from `HomeScreen` drawer:
   ```dart
   _buildDrawerItem(Icons.delete_outline, 'سجل الهدر', () {
     Navigator.pop(context);
     Navigator.push(context, MaterialPageRoute(builder: (_) => const WastageListScreen()));
   }, color: Colors.orange),
   ```
5. **Do NOT** use `Navigator.pushNamed()` or register in `AppRoutes` — the codebase doesn't use named routing.

---

## How to Add a New Component (Screen Sub-Widget)

This project does **not** have a shared components folder. Widgets are defined as:
- **Private methods** within the screen class (most common):
  ```dart
  Widget _buildSummaryCard(String title, String value, Color color) { ... }
  ```
- **Private widget classes** in the same file for stateful sub-sections.
- **Separate files** in the same feature folder for complex forms:
  `customer_form_screen.dart` alongside `customer_management_screen.dart`

### Rules:
- If the widget is used only in one screen → private method (prefix `_build`)
- If the widget is a full-page form → separate `*_form_screen.dart` in same folder
- If the widget needs its own state → `StatefulWidget` or `ConsumerStatefulWidget`
- No shared/global widget library exists — repeat code in each feature if needed

---

## How to Handle Data Operations

### Reading Data (Streams — Real-Time)
```dart
// In provider file:
final itemsStreamProvider = StreamProvider<List<Item>>((ref) {
  final repo = ref.watch(itemRepositoryProvider);
  return repo.watchAllItems();
});

// In screen:
ref.watch(itemsStreamProvider).when(
  loading: () => const CircularProgressIndicator(),
  error: (err, _) => Text('خطأ: $err'),
  data: (items) => ListView.builder(...),
);
```

### Reading Data (One-Shot)
```dart
final repo = ref.read(itemRepositoryProvider);
final items = await repo.getAllItems();
```

### Creating / Updating / Deleting
```dart
// Wrapped in try-catch, show SnackBar on success/failure:
try {
  final repo = ref.read(itemRepositoryProvider);
  await repo.createItem(newItem);
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تمت الإضافة بنجاح')),
    );
    Navigator.pop(context);
  }
} catch (e) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('خطأ: $e')),
  );
}
```

### Transactions (Multi-Step Writes)
```dart
return database.transaction(() async {
  final id = await database.into(database.items).insert(...);
  await database.into(database.cashTransactions).insert(...);
  // Accounting integration:
  final accountingRepo = AccountingRepositoryImpl(database);
  await accountingRepo.createSomeJournalEntry(...);
  return id;
});
```

---

## Common Pitfalls to Avoid

| # | Pitfall | Why It's a Problem | What to Do Instead |
|---|---|---|---|
| 1 | Using `AppTheme.lightTheme` for theme changes | `main.dart` does NOT use it — your changes will be invisible | Modify the `ThemeData(...)` directly in `main.dart` line 38–42 |
| 2 | Adding routes to `AppRoutes` expecting them to work | No screen uses named routing — `AppRoutes` is dead code | Use `Navigator.push(context, MaterialPageRoute(builder: ...))` |
| 3 | Creating `Failure` objects for error handling | The `Failure` class hierarchy exists but nothing catches or creates them | Throw typed `AppException` subclasses and catch in screens |
| 4 | Importing `enums.dart` for `ProductType` | There's a duplicate `ProductType` in `app_constants.dart` — import collision | Check which `ProductType` is used by the calling code and import that one |
| 5 | Using `ref.read()` inside `StreamProvider` body | This won't rebuild when the repo's dependencies change | Use `ref.watch()` for the repo inside `StreamProvider` |
| 6 | Forgetting to update barrel export files | New entities/repos won't be discoverable via `domain.dart`/`repositories.dart` | Always add export lines to `domain.dart` and `repositories.dart` |
| 7 | Adding English UI text | App is Arabic-only with Cairo font and `ar_AE` locale | Use Arabic strings for all user-facing text |
| 8 | Creating a `shared/` or `common/` widgets folder | The project doesn't use one — you'll be the only one following that pattern | Put reusable widgets as private methods or in the feature folder |
| 9 | Using `Equatable` mixin on entities | Despite `equatable` being in `pubspec.yaml`, no entity uses it | Use manual `==` and `hashCode` overrides (based on `id`) |
| 10 | Forgetting `database.transaction()` for multi-step writes | Partial writes corrupt data (e.g., expense without cash transaction) | Wrap related inserts/updates/deletes in a transaction |

---

## File Location Reference

| What | Where |
|---|---|
| **Entry point** | `lib/main.dart` |
| **Domain entities** | `lib/backend/domain/entities/*.dart` |
| **Abstract repositories** | `lib/backend/domain/repositories/*.dart` |
| **Repository implementations** | `lib/backend/data/repositories/*_impl.dart` |
| **Drift database** | `lib/backend/data/database/database.dart` |
| **Accounting module** | `lib/backend/accounting/` (NestJS-style: service, controller, DTO, sub-modules) |
| **Riverpod providers** | `lib/core/providers/database_providers.dart` (main), `auth_provider.dart`, `accounting_provider.dart` |
| **Constants & enums** | `lib/core/constants/app_constants.dart`, `lib/core/constants/enums.dart` |
| **Errors (exceptions)** | `lib/core/errors/exceptions.dart` |
| **Errors (failures)** | `lib/core/errors/failures.dart` (⚠️ unused) |
| **Utilities** | `lib/core/utils/` — `date_utils.dart`, `number_utils.dart`, `validation_utils.dart`, `security_utils.dart`, `logger.dart`, `session_timeout_listener.dart` |
| **Services** | `lib/core/services/pdf_service.dart`, `sms_service.dart` |
| **Theme** | `lib/frontend/config/theme.dart` (⚠️ unused in main.dart) |
| **Routes** | `lib/frontend/config/routes.dart` (⚠️ unused in navigation) |
| **Screen files** | `lib/frontend/presentation/<feature>/*_screen.dart` |
| **Barrel exports** | `lib/backend/domain/domain.dart`, `lib/backend/data/data.dart`, `lib/backend/data/repositories/repositories.dart` |
