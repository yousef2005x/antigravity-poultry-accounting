# تقرير إصلاح أخطاء المشروع (Fixes Report)

تم تحليل 272 مشكلة متبقية وتصنيف أسبابها الجذرية وتوفير الحلول لها. فيما يلي ملخص التعديلات المطلوبة:

## 1. تحديث الإعدادات (Analysis Options)
- **الملف:** `analysis_options.yaml`
- **التعديل:** تعطيل القواعد المهجورة التي تسبب تحذيرات في الإصدارات الحديثة من Dart/Flutter.
    - `avoid_returning_null_for_future`
    - `avoid_returning_null`
    - `package_api_docs`
    - `no_default_cases_in_switch`

## 2. تصحيح الثيم (Theme Configuration)
- **الملف:** `lib/config/theme.dart`
- **التعديل:** تغيير `cardTheme: CardTheme(...)` إلى `cardTheme: CardThemeData(...)`.

## 3. إصلاح الـ Repositories (Drift Manual Fixes)
- **الملف:** `lib/data/repositories/customer_repository_impl.dart`
    - تغيير `CustomerTableCompanion` إلى `CustomersCompanion`.
- **الملف:** `lib/data/repositories/invoice_repository_impl.dart`
    - تغيير `isAtLeastValue(fromDate)` إلى `isAtLeast(fromDate)`.
    - تغيير `isAtMostValue(toDate)` إلى `isAtMost(toDate)`.
    - تصحيح أسماء الـ Companions لـ `SalesInvoicesCompanion` و `SalesInvoiceItemsCompanion`.

## 4. إصلاح الـ Providers
- **الملف:** `lib/core/providers/database_providers.dart`
    - إضافة استيراد: `import 'package:poultry_accounting/domain/repositories/invoice_repository.dart';`
    - تحديث `ref.onDispose(() => db.close())` إلى `ref.onDispose(db.close)`.

# 5. حل مشكلة قفل المجلد (Directory Lock)
إذا ظهر خطأ "Access is denied" عند تشغيل `build_runner`:
1. أغلق الـ IDE (VS Code/Android Studio).
2. تأكد من أن التطبيق ليس قيد التشغيل.
3. قم بحذف مجلد `.dart_tool` يدوياً إذا لزم الأمر قبل إعادة القائمة.

---

## الخطوات والتحسينات المطلوبة (Terminal Commands):

نفذ الأوامر التالية بالترتيب في التيرمينال:

```powershell
# 1. تحديث الحزم لتحسين توافق الـ Analyzer
flutter packages upgrade

# 2. تطبيق الإصلاحات التلقائية للـ Lints
dart fix --apply

# 3. إعادة توليد الكود (Drift & Riverpod)
dart run build_runner build --delete-conflicting-outputs

# 4. مراجعة النتيجة النهائية
flutter analyze
```
