# Project Rules — Poultry Accounting

> Auto-generated from actual codebase patterns. Every rule has a concrete reason.

---

## 1. Tech Stack & Versions

| Technology | Version | Purpose |
|---|---|---|
| Flutter / Dart | SDK ≥3.0.0 <4.0.0 | Framework & language |
| Drift | ^2.14.0 | SQLite ORM (local DB) |
| flutter_riverpod | ^2.4.0 | State management |
| riverpod_annotation | ^2.3.0 | Code-gen for providers |
| Google Fonts (Cairo) | ^6.1.0 | Arabic-first typography |
| fl_chart | ^0.65.0 | Charts & dashboards |
| pdf / printing | ^3.10.0 / ^5.11.0 | Report PDF generation |
| intl | ^0.20.2 | Number/date formatting |
| crypto / encrypt | ^3.0.3 / ^5.0.3 | Password hashing |
| uuid | ^4.2.0 | Unique ID generation |
| equatable | any | Value equality |
| shared_preferences | ^2.5.4 | Key-value local storage |
| **Target platforms** | Windows, macOS, Web | Desktop-first app |

---

## 2. Folder Structure Conventions

```
lib/
├── main.dart                         # App entry, ProviderScope, MaterialApp
├── backend/
│   ├── accounting/                   # NestJS-style module (service, controller, dto, sub-modules)
│   ├── data/
│   │   ├── database/                 # Drift AppDatabase definition
│   │   │   └── database.dart
│   │   ├── repositories/             # Repository implementations (*_impl.dart)
│   │   │   └── repositories.dart     # Barrel export for ALL impls
│   │   └── data.dart                 # Barrel: exports database + repositories
│   └── domain/
│       ├── entities/                 # Pure Dart domain entities
│       ├── repositories/             # Abstract repository interfaces
│       └── domain.dart               # Barrel: exports entities + repo interfaces
├── core/
│   ├── constants/
│   │   ├── app_constants.dart        # App-wide constants + enums (UserRole, InvoiceStatus, etc.)
│   │   └── enums.dart                # Additional enums (PaymentType, ProcessingStatus, etc.)
│   ├── errors/
│   │   ├── exceptions.dart           # Exception class hierarchy (AppException → typed children)
│   │   └── failures.dart             # Failure class hierarchy  (Failure → typed children)
│   ├── providers/
│   │   ├── database_providers.dart   # All Riverpod providers (repos, streams, futures)
│   │   ├── auth_provider.dart        # AuthState + AuthNotifier + StateNotifierProvider
│   │   └── accounting_provider.dart  # Accounting-specific providers
│   ├── services/
│   │   ├── pdf_service.dart          # PDF generation logic
│   │   └── sms_service.dart          # SMS integration
│   └── utils/
│       ├── date_utils.dart           # AppDateUtils static utility class
│       ├── number_utils.dart         # NumberUtils static utility class
│       ├── validation_utils.dart     # ValidationUtils + FormValidators
│       ├── security_utils.dart       # Password hashing utils
│       ├── logger.dart               # App logger config
│       └── session_timeout_listener.dart
└── frontend/
    ├── config/
    │   ├── routes.dart               # AppRoutes static route constants
    │   └── theme.dart                # AppTheme with static color constants + lightTheme
    └── presentation/
        ├── home/                     # HomeScreen (dashboard + drawer navigation)
        ├── auth/                     # LoginScreen
        ├── accounting/               # 8 accounting screens
        ├── customers/                # customer_management/list/form screens
        ├── suppliers/                # supplier_management/list/form screens
        ├── sales/                    # sales_invoice_form/list/management screens
        ├── purchases/                # purchase_list/form screens
        ├── payments/                 # payment screens
        ├── expenses/                 # expense_list/form screens
        ├── products/                 # product_list/form screens
        ├── inventory/                # stock_dashboard screen
        ├── processing/               # raw_meat_processing + stock_conversion
        ├── pricing/                  # daily_pricing screens
        ├── employees/                # employee_list/form screens
        ├── salaries/                 # salary_list/statement screens
        ├── reports/                  # reports + central_debt_register screens
        ├── annual_returns/           # annual_inventories screen
        ├── partnership/              # partnership screen
        ├── admin/                    # settings screen
        └── settings/                 # reset_database screen
```

### Rules:
- **One feature = one folder** under `presentation/`. No shared component folder exists — all UI is colocated in its feature folder.
- **Backend follows Clean Architecture**: `domain/entities` → `domain/repositories` (interface) → `data/repositories` (implementation). Never break this boundary.
- **Barrel exports** exist at `domain.dart`, `data.dart`, and `repositories.dart`. Always update them when adding new files.
- **`core/`** holds cross-cutting concerns only — providers, utils, errors, constants. It is NOT domain logic.

---

## 3. Naming Conventions

### Files
| Type | Convention | Example |
|---|---|---|
| Entity | `snake_case.dart` | `customer.dart`, `journal_entry.dart` |
| Abstract repo | `snake_case_repository.dart` | `customer_repository.dart` |
| Repo impl | `snake_case_repository_impl.dart` | `customer_repository_impl.dart` |
| Screen | `snake_case_screen.dart` | `customer_management_screen.dart` |
| Utility | `snake_case_utils.dart` | `date_utils.dart`, `number_utils.dart` |
| Provider file | `snake_case_provider.dart` | `auth_provider.dart` |
| Barrel export | short noun `.dart` | `domain.dart`, `data.dart`, `repositories.dart` |
| Interface repo (some) | `i_snake_case_repository.dart` | `i_cash_repository.dart` |

> **Inconsistency ⚠️**: Some abstract repos use `I` prefix (`i_cash_repository.dart`, `i_partner_repository.dart`, `i_price_repository.dart`, `i_processing_repository.dart`) while most don't (`customer_repository.dart`, `invoice_repository.dart`). The majority pattern is **no prefix** — prefer it for new repos.

### Classes
| Type | Convention | Example |
|---|---|---|
| Entity | `PascalCase` | `Customer`, `JournalEntry` |
| Abstract repo | `PascalCase + Repository` | `CustomerRepository` |
| Repo impl | `PascalCase + RepositoryImpl` | `CustomerRepositoryImpl` |
| Screen widget | `PascalCase + Screen` | `CustomerManagementScreen` |
| State class | `PascalCase + State` (or similar) | `AuthState` |
| Notifier | `PascalCase + Notifier` | `AuthNotifier` |
| Utility class | `PascalCase + Utils` | `NumberUtils`, `AppDateUtils` |
| Constants class | `AppConstants` | — |
| Theme class | `AppTheme` | — |
| Routes class | `AppRoutes` | — |

### Variables & Providers
| Type | Convention | Example |
|---|---|---|
| Riverpod Provider | `camelCaseProvider` | `customerRepositoryProvider` |
| Stream Provider | `camelCaseStreamProvider` | `customersStreamProvider` |
| Future Provider | `camelCaseProvider` | `dashboardMetricsProvider` |
| Private fields | `_camelCase` | `_userRepository` |
| DB instance | `database` | `this.database` in repo impls |

### Enums
- `PascalCase` enum name, `camelCase` values
- Every enum value has `code` (English) + `nameAr` (Arabic label)
- Every enum has a `fromCode(String)` static factory method

---

## 4. Import Order & Aliasing

### Import Order (observed pattern):
```dart
// 1. Dart/Flutter SDK imports
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// 2. Third-party packages
import 'package:drift/drift.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';

// 3. Package-absolute imports for cross-layer references
import 'package:poultry_accounting/core/providers/auth_provider.dart';
import 'package:poultry_accounting/backend/domain/entities/customer.dart';

// 4. Relative imports for same-layer references
import 'database_providers.dart';
```

### Aliasing Rules:
- **Database module** is aliased as `db` when imported in repository impls:
  ```dart
  import 'package:poultry_accounting/backend/data/database/database.dart' as db;
  ```
- **Domain payment** is aliased as `domain` to avoid Drift type collision:
  ```dart
  import 'package:poultry_accounting/backend/domain/entities/payment.dart' as domain;
  ```
- Only alias when there is a genuine name conflict. Don't alias preemptively.

---

## 5. State Management Patterns

### Pattern: Riverpod (flutter_riverpod)

**Provider Types Used:**
| Type | When to Use | Example |
|---|---|---|
| `Provider<T>` | Repository singletons | `customerRepositoryProvider` |
| `StreamProvider<T>` | Real-time lists from DB | `customersStreamProvider` |
| `FutureProvider<T>` | One-shot async computations | `dashboardMetricsProvider` |
| `FutureProvider.family<T, P>` | Parameterized async queries | `incomeStatementProvider` |
| `StateNotifierProvider` | Auth state with actions | `authProvider` |

**Rules:**
1. **All repository providers inject `databaseProvider`** via `ref.watch(databaseProvider)` and return the abstract interface type.
2. **StreamProviders return domain entity lists**, never Drift table rows.
3. **FutureProviders that depend on data freshness `ref.watch()` a related StreamProvider** to trigger refresh:
   ```dart
   final trialBalanceProvider = FutureProvider<List<TrialBalanceRow>>((ref) {
     ref.watch(journalEntriesStreamProvider); // refresh trigger
     final repo = ref.read(accountingRepositoryProvider);
     return repo.getTrialBalance();
   });
   ```
4. **StateNotifier pattern for auth**: State class with `copyWith()`, Notifier with async methods, provider at file bottom.
5. **No `ChangeNotifierProvider`** — this project does not use `ChangeNotifier` anywhere.
6. **Top-level `ProviderScope`** in `main()` wrapping `MyApp`.

> **Inconsistency ⚠️**: Some StreamProviders use `ref.watch()` to get repos, others use `ref.read()`. The correct pattern for stream providers is `ref.watch()` (used in `customersStreamProvider`, `suppliersStreamProvider`), but several others use `ref.read()` (`productsStreamProvider`, `purchasesStreamProvider`, etc.).

---

## 6. Styling Approach

### Theme:
- **Material 3** enabled (`useMaterial3: true`)
- **Primary seed**: `Colors.green` (from `ColorScheme.fromSeed`)
- **Font**: Cairo (via `GoogleFonts.cairoTextTheme()`) — Arabic-first
- **Locale**: Fixed to `ar_AE` (Arabic UAE)
- **RTL**: Auto from locale

### Static Color Constants (in `AppTheme`):
- `primaryColor`: `#2E7D32` (Green)
- `secondaryColor`: `#FFA726` (Orange)
- `errorColor`: `#D32F2F`
- `warningColor`, `successColor`, `infoColor` — semantic colors
- Text: `textPrimary` (#212121), `textSecondary` (#757575), `textDisabled` (#BDBDBD)

### Screen-Level Styling:
- **AppBars** set `backgroundColor` directly per-screen (e.g., `Colors.green`, `Colors.blueAccent`), NOT relying on theme
- **Cards** use `elevation: 4`, `borderRadius: 12`
- **Buttons** use `RoundedRectangleBorder(borderRadius: 8)`
- **All strings are hardcoded Arabic** — no i18n key system
- **No CSS or external stylesheets** — all styling is inline Flutter widget properties

> **Inconsistency ⚠️**: `AppTheme` defines a complete `lightTheme` getter, but `main.dart` builds its own `ThemeData` from scratch instead of using `AppTheme.lightTheme`. The `theme.dart` file is essentially unused.

---

## 7. Error Handling Patterns

### Two Parallel Hierarchies:
```
AppException (implements Exception)     Failure (abstract)
├── DatabaseException                   ├── DatabaseFailure
├── AuthenticationException             ├── AuthenticationFailure
├── AuthorizationException              ├── AuthorizationFailure
├── ValidationException                 ├── ValidationFailure
├── BusinessRuleException               ├── BusinessRuleFailure
├── NotFoundException                   ├── NotFoundFailure
├── BackupException                     ├── BackupFailure
├── FileException                       ├── FileFailure
├── CacheException                      └── UnexpectedFailure
└── ServerException
```

### Rules:
1. **Exceptions** are thrown in repository implementations on unexpected errors.
2. **Failures** are the presentation-safe counterpart (designed for UI consumption), but in practice **repo impls throw raw exceptions** and screens catch with generic `try-catch` or rely on Riverpod's `.when(error:)`.
3. **Screens show errors inline** using `AsyncValue.when(error: (err, stack) => Text('خطأ: $err'))`.
4. **SnackBar for user feedback** on actions (create, update, delete):
   ```dart
   ScaffoldMessenger.of(context).showSnackBar(
     const SnackBar(content: Text('تمت العملية بنجاح')),
   );
   ```
5. **No global error handler** — each screen handles its own errors.

> **Inconsistency ⚠️**: The `Failure` classes exist but are **not actively used** anywhere in the codebase. Repo impls throw `Exception`s directly, not wrap them in `Failure`. This is dead code that was planned but never integrated.

---

## 8. Entity Patterns

Every domain entity follows this structure:
```dart
@immutable
class EntityName {
  const EntityName({
    required this.requiredField,
    this.id,                    // nullable int? for new entities
    this.optionalField,
    this.isActive = true,       // soft-delete/status defaults
    this.createdAt,
    this.updatedAt,
    this.deletedAt,             // soft-delete marker
  });

  final int? id;
  final String requiredField;
  // ... fields

  bool get isDeleted => deletedAt != null;  // computed properties

  EntityName copyWith({...}) { ... }        // always present

  @override
  String toString() => '...';

  @override
  bool operator ==(Object other) => identical(this, other) || (other is EntityName && id == other.id);

  @override
  int get hashCode => id.hashCode;
}
```

### Rules:
- Always `@immutable` + `const` constructor
- `id` is `int?` (nullable for unsaved entities)
- Include `copyWith()` in every entity
- Override `==` based on `id` only
- Timestamps: `createdAt`, `updatedAt`, `deletedAt` (all nullable `DateTime?`)

---

## 9. Repository Patterns

### Abstract (in `domain/repositories/`):
```dart
abstract class XxxRepository {
  Future<List<Entity>> getAllEntities();
  Stream<List<Entity>> watchAllEntities();  // real-time via Drift
  Future<Entity?> getEntityById(int id);
  Future<int> createEntity(Entity entity);  // returns new ID
  Future<void> updateEntity(Entity entity);
  Future<void> deleteEntity(int id);        // soft or hard delete
}
```

### Implementation (in `data/repositories/`):
```dart
class XxxRepositoryImpl implements XxxRepository {
  XxxRepositoryImpl(this.database);         // constructor injection
  final db.AppDatabase database;            // aliased as db

  // Private mapper methods at the bottom:
  Entity _mapToEntity(db.TableRow row) { ... }
  Entity _mapJoinToEntity(TypedResult result) { ... }
}
```

### Rules:
- Repo impl constructor takes `AppDatabase` only — no other deps
- Use Drift `database.transaction()` for multi-step writes
- Mapper methods are private, prefixed with `_map`
- Accounting integration is done directly in repo impls by creating `AccountingRepositoryImpl(database)` inline

---

## 10. Navigation Patterns

- **`MaterialPageRoute` + `Navigator.push`** for all screen-to-screen navigation
- **Drawer** in `HomeScreen` as the main navigation hub
- **`ExpansionTile`** groups related items in the drawer
- **No named routes or router package** — all navigation is imperative
- **`AppRoutes`** class exists with static route strings, but is **not used by any screen** — navigation uses direct widget constructors instead
- **Auth flow**: `SplashScreen` → `AuthWrapper` (checks `authProvider`) → `LoginScreen` or `HomeScreen`

> **Inconsistency ⚠️**: `AppRoutes` defines route paths (e.g., `/customers`, `/invoices/:id`) but no screen uses `Navigator.pushNamed()`. The routes file is dead code.

---

## 11. DO and DON'T List

### ✅ DO
| Rule | Reason |
|---|---|
| Create entity in `domain/entities/` with `@immutable`, `copyWith`, `==` based on `id` | All 21 entities follow this pattern |
| Create abstract repo in `domain/repositories/` then impl in `data/repositories/` | Clean Architecture boundary — 19 repos follow this |
| Register new repo provider in `database_providers.dart` | Central provider registry — all 16 repo providers are here |
| Update barrel exports (`domain.dart`, `repositories.dart`) when adding files | 2 barrel files aggregate all exports |
| Use `database.transaction()` for multi-step write operations | All create methods with side-effects use transactions |
| Use `ConsumerWidget` / `ConsumerStatefulWidget` for screens | Every screen extends `ConsumerWidget` |
| Use `AsyncValue.when()` for loading/error/data states | Every screen with async data uses this pattern |
| Use private `_mapToEntity()` methods at the bottom of repo impls | All 20 repo impls follow this mapper pattern |
| Use private constructor `ClassName._()` for utility/constant classes | `AppConstants._()`, `AppTheme._()`, `NumberUtils._()`, etc. |
| Keep all UI strings in Arabic (hardcoded) | App is Arabic-only, no i18n system |
| Use Drift `Companion` objects for inserts/updates | All repo impls use this Drift pattern |
| Wrap password hashing with crypto utils, not raw | `security_utils.dart` handles this |

### ❌ DON'T
| Rule | Reason |
|---|---|
| Don't create a Use Cases / Interactors layer | Commented out in `domain.dart` — project removed this layer |
| Don't use `Navigator.pushNamed()` or named routes | Despite `AppRoutes` existing, all nav uses direct `MaterialPageRoute` |
| Don't use `ChangeNotifier` or `StateProvider` | Project is Riverpod-only with `StateNotifier` for complex state |
| Don't put business logic in screens | Repo impls contain all logic, screens only call providers |
| Don't create a shared/common widget folder | No shared component folder exists — each feature is self-contained |
| Don't use `AppTheme.lightTheme` (currently unused) | `main.dart` builds its own `ThemeData` — the theme file is disconnected |
| Don't add English UI strings | All user-facing text is Arabic. Keep it consistent |
| Don't use `int` for new entity IDs | IDs are `int?` (nullable) — the DB generates the actual `int` on insert |
| Don't import Drift types in domain layer | Domain entities are pure Dart; Drift stays in `data/` |
| Don't add API/HTTP calls | This is an offline-first desktop app with local SQLite only |

---

## 12. Detected Inconsistencies

| # | Issue | Location | Impact |
|---|---|---|---|
| 1 | `AppTheme.lightTheme` exists but `main.dart` creates its own `ThemeData` | `theme.dart` vs `main.dart` | Dead code; theme changes in `theme.dart` have zero effect |
| 2 | `AppRoutes` defines named routes but no screen uses `pushNamed()` | `routes.dart` | Dead code; route strings are unused |
| 3 | `Failure` hierarchy mirrors `Exception` hierarchy but is never instantiated | `failures.dart` | Dead code; screens catch `Exception` directly |
| 4 | Some abstract repos use `I` prefix, most don't | `i_cash_repository.dart` vs `customer_repository.dart` | Inconsistent naming; majority is no-prefix |
| 5 | `StreamProvider` refs mix `ref.watch()` and `ref.read()` for repo access | `database_providers.dart` | `ref.read()` is incorrect inside StreamProvider body — should be `ref.watch()` |
| 6 | `ProductType` enum is defined in BOTH `app_constants.dart` AND `enums.dart` | `core/constants/` | Duplicate enum — potential import conflicts |
| 7 | `home_screen.dart` imports itself | `home_screen.dart` L24 | Circular self-import (harmless but messy) |
| 8 | Accounting integration creates `AccountingRepositoryImpl(database)` directly instead of using the provider | `expense_repository_impl.dart` L150 | Bypasses DI, creates tight coupling |
