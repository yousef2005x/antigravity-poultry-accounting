import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:poultry_accounting/core/constants/app_constants.dart';
import 'package:poultry_accounting/core/utils/security_utils.dart';

part 'database.g.dart';

// ============================================================================
// TABLE DEFINITIONS
// ============================================================================

/// Users table
@DataClassName('UserTable')
class Users extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get username => text().withLength(min: 3, max: 50).unique()();
  TextColumn get passwordHash => text()();
  TextColumn get fullName => text().withLength(max: 100)();
  TextColumn get phoneNumber => text().withLength(max: 20).nullable()();
  TextColumn get role => text()(); // UserRole enum code
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().nullable()();
  DateTimeColumn get deletedAt => dateTime().nullable()(); // Soft delete
}

/// Customers table
@DataClassName('CustomerTable')
class Customers extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get phone => text().withLength(max: 20).nullable()();
  TextColumn get address => text().withLength(max: 200).nullable()();
  RealColumn get creditLimit => real().withDefault(const Constant(10000))();
  TextColumn get notes => text().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().nullable()();
  DateTimeColumn get deletedAt => dateTime().nullable()(); // Soft delete
}

/// Suppliers table
@DataClassName('SupplierTable')
class Suppliers extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get phone => text().withLength(max: 20).nullable()();
  TextColumn get address => text().withLength(max: 200).nullable()();
  TextColumn get notes => text().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().nullable()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
}

/// Products table
@DataClassName('ProductTable')
class Products extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get unitType => text()(); // UnitType enum code (kg, piece, box)
  BoolColumn get isWeighted => boolean().withDefault(const Constant(true))();
  RealColumn get defaultPrice => real().withDefault(const Constant(0))();
  TextColumn get description => text().nullable()();
  TextColumn get productType => text().withDefault(Constant(ProductType.finalProduct.code))(); // raw, intermediate, final
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().nullable()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
}

/// Inventory Batches table (for FIFO costing)
@DataClassName('InventoryBatchTable')
class InventoryBatches extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get productId => integer().references(Products, #id)();
  IntColumn get purchaseInvoiceId => integer().nullable().references(PurchaseInvoices, #id, onDelete: KeyAction.cascade)();
  IntColumn get processingId => integer().nullable().references(RawMeatProcessings, #id, onDelete: KeyAction.cascade)();
  RealColumn get quantity => real()(); // Quantity in
  RealColumn get remainingQuantity => real()(); // Remaining (for FIFO)
  RealColumn get unitCost => real()(); // Cost at purchase
  DateTimeColumn get purchaseDate => dateTime()();
  DateTimeColumn get expiryDate => dateTime().nullable()();
  TextColumn get batchNumber => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// Sales Invoices table
@DataClassName('SalesInvoiceTable')
class SalesInvoices extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get invoiceNumber => text().unique()(); // Auto-generated
  IntColumn get customerId => integer().references(Customers, #id)();
  DateTimeColumn get invoiceDate => dateTime()();
  TextColumn get status => text()(); // InvoiceStatus enum (draft, confirmed, cancelled)
  RealColumn get subtotal => real().withDefault(const Constant(0))();
  RealColumn get discount => real().withDefault(const Constant(0))();
  RealColumn get tax => real().withDefault(const Constant(0))();
  RealColumn get total => real().withDefault(const Constant(0))();
  RealColumn get paidAmount => real().withDefault(const Constant(0))();
  TextColumn get notes => text().nullable()();
  @ReferenceName('salesInvoiceCreatedByUser')
  IntColumn get createdBy => integer().references(Users, #id)();
  DateTimeColumn get confirmedAt => dateTime().nullable()();
  @ReferenceName('salesInvoiceConfirmedByUser')
  IntColumn get confirmedBy => integer().nullable().references(Users, #id)();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().nullable()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
}

/// Sales Invoice Items table
@DataClassName('SalesInvoiceItemTable')
class SalesInvoiceItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get invoiceId => integer().references(SalesInvoices, #id, onDelete: KeyAction.cascade)();
  IntColumn get productId => integer().references(Products, #id)();
  RealColumn get quantity => real()();
  RealColumn get unitPrice => real()();
  RealColumn get costAtSale => real()(); // CRITICAL: for profit calculation
  RealColumn get discount => real().withDefault(const Constant(0))();
  RealColumn get total => real()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// Purchase Invoices table
@DataClassName('PurchaseInvoiceTable')
class PurchaseInvoices extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get invoiceNumber => text()();
  IntColumn get supplierId => integer().references(Suppliers, #id)();
  DateTimeColumn get invoiceDate => dateTime()();
  TextColumn get status => text()();
  RealColumn get subtotal => real().withDefault(const Constant(0))();
  RealColumn get discount => real().withDefault(const Constant(0))();
  RealColumn get tax => real().withDefault(const Constant(0))();
  RealColumn get total => real().withDefault(const Constant(0))();
  RealColumn get paidAmount => real().withDefault(const Constant(0))();
  RealColumn get additionalCosts => real().withDefault(const Constant(0))(); // Transport, etc.
  TextColumn get notes => text().nullable()();
  @ReferenceName('purchaseInvoiceCreatedByUser')
  IntColumn get createdBy => integer().references(Users, #id)();
  DateTimeColumn get confirmedAt => dateTime().nullable()();
  @ReferenceName('purchaseInvoiceConfirmedByUser')
  IntColumn get confirmedBy => integer().nullable().references(Users, #id)();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().nullable()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
}

/// Stock Conversions table (Whole -> Cuts)
@DataClassName('StockConversionTable')
class StockConversions extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get conversionDate => dateTime()();
  IntColumn get sourceProductId => integer().references(Products, #id)();
  RealColumn get sourceQuantity => real()();
  TextColumn get batchNumber => text().nullable()();
  TextColumn get notes => text().nullable()();
  @ReferenceName('stockConversionCreatedByUser')
  IntColumn get createdBy => integer().references(Users, #id)();
  RealColumn get operationalExpenses => real().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// Stock Conversion Items (Outputs)
@DataClassName('StockConversionItemTable')
class StockConversionItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get conversionId => integer().references(StockConversions, #id, onDelete: KeyAction.cascade)();
  IntColumn get productId => integer().references(Products, #id)();
  RealColumn get quantity => real()();
  RealColumn get yieldPercentage => real()();
  RealColumn get unitCost => real()(); // Calculated from source cost
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// Purchase Invoice Items table
@DataClassName('PurchaseInvoiceItemTable')
class PurchaseInvoiceItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get invoiceId => integer().references(PurchaseInvoices, #id, onDelete: KeyAction.cascade)();
  IntColumn get productId => integer().references(Products, #id)();
  RealColumn get quantity => real()();
  RealColumn get unitCost => real()();
  RealColumn get total => real()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// Payments table (Receipts and Payments)
@DataClassName('PaymentTable')
class Payments extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get paymentNumber => text().unique()(); // Auto-generated
  TextColumn get type => text()(); // 'receipt' or 'payment'
  IntColumn get customerId => integer().nullable().references(Customers, #id)();
  IntColumn get supplierId => integer().nullable().references(Suppliers, #id)();
  IntColumn get invoiceId => integer().nullable().references(SalesInvoices, #id, onDelete: KeyAction.cascade)();
  IntColumn get purchaseInvoiceId => integer().nullable().references(PurchaseInvoices, #id, onDelete: KeyAction.cascade)();
  RealColumn get amount => real()();
  TextColumn get method => text()(); // PaymentMethod enum (cash, bank, check)
  DateTimeColumn get paymentDate => dateTime()();
  TextColumn get referenceNumber => text().nullable()(); // Check number, transfer ref, etc.
  TextColumn get notes => text().nullable()();
  @ReferenceName('paymentCreatedByUser')
  IntColumn get createdBy => integer().references(Users, #id)();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().nullable()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
}

/// Expense Categories table
@DataClassName('ExpenseCategoryTable')
class ExpenseCategories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 100).unique()();
  TextColumn get description => text().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// Expenses table
@DataClassName('ExpenseTable')
class Expenses extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get categoryId => integer().references(ExpenseCategories, #id)();
  RealColumn get amount => real()();
  DateTimeColumn get expenseDate => dateTime()();
  TextColumn get description => text().withLength(max: 200)();
  TextColumn get notes => text().nullable()();
  @ReferenceName('expenseCreatedByUser')
  IntColumn get createdBy => integer().references(Users, #id)();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().nullable()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
}

/// Audit Logs table
@DataClassName('AuditLogTable')
class AuditLogs extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get userId => integer().references(Users, #id)();
  TextColumn get entityType => text()(); // table name
  IntColumn get entityId => integer()();
  TextColumn get action => text()(); // AuditAction enum (create, update, delete, etc.)
  TextColumn get oldValue => text().nullable()(); // JSON
  TextColumn get newValue => text().nullable()(); // JSON
  DateTimeColumn get timestamp => dateTime().withDefault(currentDateAndTime)();
}

/// Backups table (track backup history)
@DataClassName('BackupTable')
class Backups extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get fileName => text()();
  TextColumn get filePath => text()();
  IntColumn get fileSize => integer()(); // in bytes
  BoolColumn get isEncrypted => boolean().withDefault(const Constant(false))();
  TextColumn get notes => text().nullable()();
  @ReferenceName('backupCreatedByUser')
  IntColumn get createdBy => integer().references(Users, #id)();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// Product prices history table (for daily pricing)
@DataClassName('ProductPriceTable')
class ProductPrices extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get productId => integer().references(Products, #id)();
  RealColumn get price => real()();
  DateTimeColumn get date => dateTime()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// Raw meat processing table (for intake and tare calculation)
@DataClassName('RawMeatProcessingTable')
class RawMeatProcessings extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get batchNumber => text().unique()();
  
  // Stage 1: Live (Incoming)
  RealColumn get liveGrossWeight => real().withDefault(const Constant(0))();
  RealColumn get liveCrateWeight => real().withDefault(const Constant(0))();
  IntColumn get liveCrateCount => integer().withDefault(const Constant(0))();
  RealColumn get liveNetWeight => real().withDefault(const Constant(0))(); // Calculated: Gross - (Crate * Count)
  
  // Stage 2: Slaughtered (After processing)
  RealColumn get slaughteredGrossWeight => real().withDefault(const Constant(0))();
  RealColumn get slaughteredBasketWeight => real().withDefault(const Constant(0))();
  IntColumn get slaughteredBasketCount => integer().withDefault(const Constant(0))();
  RealColumn get slaughteredNetWeight => real().withDefault(const Constant(0))(); // Calculated: Gross - (Basket * Count)

  // Legacy field support (mapped from netWeight if needed)
  RealColumn get netWeight => real()(); 
  
  // Financials and Metadata
  RealColumn get totalCost => real().withDefault(const Constant(0))(); 
  RealColumn get operationalExpenses => real().withDefault(const Constant(0))();
  IntColumn get supplierId => integer().nullable().references(Suppliers, #id)();
  DateTimeColumn get processingDate => dateTime()();
  TextColumn get notes => text().nullable()();
  @ReferenceName('processingCreatedByUser')
  IntColumn get createdBy => integer().references(Users, #id)();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().nullable()();
}

/// Processing outputs table (for yield calculation)
@DataClassName('ProcessingOutputTable')
class ProcessingOutputs extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get processingId => integer().references(RawMeatProcessings, #id, onDelete: KeyAction.cascade)();
  IntColumn get productId => integer().references(Products, #id)();
  
  // Weighing details per item
  RealColumn get grossWeight => real().withDefault(const Constant(0))();
  RealColumn get basketWeight => real().withDefault(const Constant(0))();
  IntColumn get basketCount => integer().withDefault(const Constant(0))();
  RealColumn get quantity => real()(); // This is the Net Weight (Gross - (Basket * Count))
  
  RealColumn get yieldPercentage => real()(); // (quantity / slaughteredNetWeight) * 100
  DateTimeColumn get inventoryDate => dateTime().nullable()(); // Manual entry for surplus
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// Partners table
@DataClassName('PartnerTable')
class Partners extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  RealColumn get sharePercentage => real().withDefault(const Constant(50))();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// Partner transactions table (drawings and distributions)
@DataClassName('PartnerTransactionTable')
class PartnerTransactions extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get partnerId => integer().references(Partners, #id)();
  RealColumn get amount => real()();
  TextColumn get type => text()(); // 'drawing' or 'distribution'
  DateTimeColumn get transactionDate => dateTime()();
  TextColumn get notes => text().nullable()();
  @ReferenceName('partnerTransactionCreatedByUser')
  IntColumn get createdBy => integer().references(Users, #id)();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// Cash Transactions (Safe/Box)
@DataClassName('CashTransactionTable')
class CashTransactions extends Table {
  IntColumn get id => integer().autoIncrement()();
  RealColumn get amount => real()();
  TextColumn get type => text()(); // 'in' or 'out'
  TextColumn get description => text().withLength(max: 200)();
  DateTimeColumn get transactionDate => dateTime()();
  IntColumn get relatedPaymentId => integer().nullable().references(Payments, #id)();
  IntColumn get relatedExpenseId => integer().nullable().references(Expenses, #id)();
  @ReferenceName('cashTransactionCreatedByUser')
  IntColumn get createdBy => integer().references(Users, #id)();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// Salaries table
@DataClassName('SalaryTable')
class Salaries extends Table {
  IntColumn get id => integer().autoIncrement()();
  RealColumn get amount => real()();
  DateTimeColumn get salaryDate => dateTime()();
  TextColumn get employeeName => text().withLength(min: 1, max: 100)();
  IntColumn get employeeId => integer().nullable().references(Employees, #id)();
  TextColumn get notes => text().nullable()();
  @ReferenceName('salaryCreatedByUser')
  IntColumn get createdBy => integer().references(Users, #id)();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().nullable()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
}

/// Annual Inventory table
@DataClassName('AnnualInventoryTable')
class AnnualInventories extends Table {
  IntColumn get id => integer().autoIncrement()();
  RealColumn get amount => real()();
  DateTimeColumn get inventoryDate => dateTime()();
  TextColumn get description => text().withLength(max: 200)();
  @ReferenceName('annualInventoryCreatedByUser')
  IntColumn get createdBy => integer().references(Users, #id)();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().nullable()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
}

/// Employees table (for fixed monthly salary)
@DataClassName('EmployeeTable')
class Employees extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 100).unique()();
  TextColumn get phone => text().withLength(max: 20).nullable()();
  RealColumn get monthlySalary => real().withDefault(const Constant(0))();
  DateTimeColumn get hireDate => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().nullable()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
}

// ============================================================================
// ACCOUNTING TABLES
// ============================================================================

/// System Settings table (key-value store for feature flags)
@DataClassName('SystemSettingTable')
class SystemSettings extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get key => text().unique()();
  TextColumn get value => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().nullable()();
}

/// Chart of Accounts table
@DataClassName('AccountTable')
class Accounts extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get code => text().withLength(max: 20)();
  TextColumn get name => text().withLength(max: 200)();
  TextColumn get nameEn => text().withLength(max: 200).nullable()();
  TextColumn get accountType => text()(); // asset, liability, equity, revenue, expense
  TextColumn get rootType => text().nullable()(); // Asset, Liability, Equity, Income, Expense
  TextColumn get reportType => text().nullable()(); // Balance Sheet, Profit and Loss
  IntColumn get parentId => integer().nullable().references(Accounts, #id)();
  BoolColumn get isGroup => boolean().withDefault(const Constant(false))();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  IntColumn get lft => integer().withDefault(const Constant(0))();
  IntColumn get rgt => integer().withDefault(const Constant(0))();
  TextColumn get balanceMustBe => text().nullable()(); // Debit, Credit, or null
  TextColumn get accountCurrency => text().nullable()();
  BoolColumn get freezeAccount => boolean().withDefault(const Constant(false))();
  IntColumn get companyId => integer().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().nullable()();
}

/// Journal Entries table (header)
@DataClassName('JournalEntryTable')
class JournalEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get entryNumber => text().unique()();
  DateTimeColumn get entryDate => dateTime()();
  TextColumn get description => text().nullable()();
  TextColumn get sourceType => text().nullable()(); // sale, purchase, payment, expense, wastage, etc.
  IntColumn get sourceId => integer().nullable()();
  IntColumn get branchId => integer().nullable()();
  BoolColumn get isPosted => boolean().withDefault(const Constant(false))();
  BoolColumn get isReversed => boolean().withDefault(const Constant(false))();
  IntColumn get reversedByEntryId => integer().nullable()();
  @ReferenceName('journalEntryCreatedByUser')
  IntColumn get createdById => integer().references(Users, #id)();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// Journal Entry Lines table
@DataClassName('JournalEntryLineTable')
class JournalEntryLines extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get journalEntryId => integer().references(JournalEntries, #id, onDelete: KeyAction.cascade)();
  IntColumn get lineNumber => integer()();
  IntColumn get accountId => integer().references(Accounts, #id)();
  RealColumn get debitAmount => real().withDefault(const Constant(0))();
  RealColumn get creditAmount => real().withDefault(const Constant(0))();
  RealColumn get debitInAccountCurrency => real().nullable()();
  RealColumn get creditInAccountCurrency => real().nullable()();
  TextColumn get description => text().nullable()();
  TextColumn get partyType => text().nullable()(); // customer, supplier
  IntColumn get partyId => integer().nullable()();
  IntColumn get costCenterId => integer().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// Payment Ledger Entries table (subledger for receivables/payables)
@DataClassName('PaymentLedgerEntryTable')
class PaymentLedgerEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get partyType => text()(); // customer, supplier
  IntColumn get partyId => integer()();
  TextColumn get accountType => text()(); // receivable, payable
  IntColumn get accountId => integer().references(Accounts, #id)();
  TextColumn get voucherType => text()(); // sale, purchase, payment, credit_note
  IntColumn get voucherId => integer()();
  TextColumn get againstVoucherType => text().nullable()();
  IntColumn get againstVoucherId => integer().nullable()();
  RealColumn get amount => real()();
  DateTimeColumn get postingDate => dateTime()();
  DateTimeColumn get dueDate => dateTime().nullable()();
  BoolColumn get delinked => boolean().withDefault(const Constant(false))();
  TextColumn get remarks => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// Credit Notes table
@DataClassName('CreditNoteTable')
class CreditNotes extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get creditNoteNumber => text().unique()();
  DateTimeColumn get creditNoteDate => dateTime()();
  IntColumn get docstatus => integer().withDefault(const Constant(0))(); // 0=draft, 1=submitted
  TextColumn get originalInvoiceType => text()(); // sale, purchase
  IntColumn get originalInvoiceId => integer()();
  RealColumn get amount => real()();
  TextColumn get reason => text().nullable()();
  IntColumn get branchId => integer().nullable()();
  DateTimeColumn get submittedAt => dateTime().nullable()();
  @ReferenceName('creditNoteSubmittedByUser')
  IntColumn get submittedById => integer().nullable().references(Users, #id)();
  @ReferenceName('creditNoteCreatedByUser')
  IntColumn get createdById => integer().references(Users, #id)();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// Tax Templates table
@DataClassName('TaxTemplateTable')
class TaxTemplates extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(max: 100)();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  IntColumn get companyId => integer().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// Tax Template Rows table
@DataClassName('TaxTemplateRowTable')
class TaxTemplateRows extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get templateId => integer().references(TaxTemplates, #id, onDelete: KeyAction.cascade)();
  TextColumn get taxType => text()(); // e.g. VAT
  RealColumn get rate => real()(); // percentage (e.g. 16.0 for 16%)
  IntColumn get accountId => integer().references(Accounts, #id)();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// Payment Allocations table (many-to-many between payments and invoices)
@DataClassName('PaymentAllocationTable')
class PaymentAllocations extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get paymentId => integer().references(Payments, #id)();
  TextColumn get invoiceType => text()(); // sale, purchase
  IntColumn get invoiceId => integer()();
  RealColumn get amount => real()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

// ============================================================================
// DATABASE CLASS
// ============================================================================

@DriftDatabase(tables: [
  Users,
  Customers,
  Suppliers,
  Products,
  InventoryBatches,
  SalesInvoices,
  SalesInvoiceItems,
  PurchaseInvoices,
  PurchaseInvoiceItems,
  Payments,
  ExpenseCategories,
  Expenses,
  AuditLogs,
  Backups,
  ProductPrices,
  RawMeatProcessings,
  ProcessingOutputs,
  Partners,
  PartnerTransactions,
  CashTransactions,
  Salaries,
  AnnualInventories,
  StockConversions,
  StockConversionItems,
  Employees,
  // Accounting tables
  SystemSettings,
  Accounts,
  JournalEntries,
  JournalEntryLines,
  PaymentLedgerEntries,
  CreditNotes,
  TaxTemplates,
  TaxTemplateRows,
  PaymentAllocations,
],)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 15;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      
      // Seed default data
      await _seedDefaultData();
    },
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.addColumn(users, users.phoneNumber);
      }
      if (from < 3) {
        // Migration for Processing tables
        await m.createTable(rawMeatProcessings);
        await m.createTable(processingOutputs);
      }
      if (from < 4) {
        await m.addColumn(processingOutputs, processingOutputs.inventoryDate);
      }
      if (from < 5) {
        await m.createTable(salaries);
        await m.createTable(annualInventories);
      }
      if (from < 6) {
        // Reset admin password to ensure access
        final hashedPassword = SecurityUtils.hashPassword(AppConstants.defaultAdminPassword);
        
        // Check if admin exists
        final adminUser = await (select(users)..where((t) => t.username.equals(AppConstants.defaultAdminUsername))).getSingleOrNull();
        
        if (adminUser != null) {
          // Update existing admin
          await (update(users)..where((t) => t.username.equals(AppConstants.defaultAdminUsername))).write(
            UsersCompanion(passwordHash: Value(hashedPassword)),
          );
        } else {
          // Create admin if missing
          await into(users).insert(
            UsersCompanion.insert(
              username: AppConstants.defaultAdminUsername,
              passwordHash: hashedPassword,
              fullName: 'مدير النظام',
              role: UserRole.admin.code,
            ),
          );
        }
      }
      if (from < 7) {
        await m.createTable(stockConversions);
        await m.createTable(stockConversionItems);
      }
      if (from < 8) {
        await m.addColumn(products, (products as dynamic).productType);
        
        // Ensure system products exist after migration
        await _seedSystemProducts();
      }
      if (from < 9) {
        // Idempotent migration: Check actual database schema
        final columns = await customSelect('PRAGMA table_info(raw_meat_processings)').get();
        final existingNames = columns.map((row) => row.read<String>('name')).toList();

        // 1. Handle Orphaned 'gross_weight' column if it exists (remnant from old versions)
        if (existingNames.contains('gross_weight')) {
          try {
            // Attempt to drop the orphaned column (SQLite 3.35.0+)
            await customStatement('ALTER TABLE raw_meat_processings DROP COLUMN gross_weight');
          } catch (e) {
            // Fallback for older SQLite: Recreating table is complex, so we just log or ignore 
            // if we can't drop it. But on Windows/macOS, DROP COLUMN is usually supported.
          }
        }

        // 2. Add missing columns ONLY if they don't exist
        Future<void> addIfMissing(GeneratedColumn col) async {
          if (!existingNames.contains(col.name)) {
            await m.addColumn(rawMeatProcessings, col);
          }
        }

        await addIfMissing(rawMeatProcessings.liveGrossWeight);
        await addIfMissing(rawMeatProcessings.liveCrateWeight);
        await addIfMissing(rawMeatProcessings.liveCrateCount);
        await addIfMissing(rawMeatProcessings.liveNetWeight);
        await addIfMissing(rawMeatProcessings.slaughteredGrossWeight);
        await addIfMissing(rawMeatProcessings.slaughteredBasketWeight);
        await addIfMissing(rawMeatProcessings.slaughteredBasketCount);
        await addIfMissing(rawMeatProcessings.slaughteredNetWeight);
        await addIfMissing(rawMeatProcessings.totalCost);

        // 3. Data Reconciliation: Sync existing netWeight (legacy) with new slaughteredNetWeight
        await customStatement(
          'UPDATE raw_meat_processings SET slaughtered_net_weight = net_weight WHERE (slaughtered_net_weight = 0 OR slaughtered_net_weight IS NULL) AND net_weight > 0',
        );
      }
      if (from < 10) {
        // Migration 10: Rebuild raw_meat_processings table to properly remove gross_weight column
        // This is an idempotent migration that checks if rebuild is needed
        
        final columns = await customSelect('PRAGMA table_info(raw_meat_processings)').get();
        final existingNames = columns.map((row) => row.read<String>('name')).toList();
        
        // Only rebuild if the legacy gross_weight column still exists
        if (existingNames.contains('gross_weight')) {
          // Step 1: Rename old table
          await customStatement('ALTER TABLE raw_meat_processings RENAME TO raw_meat_processings_old');
          
          // Step 2: Create new table with correct schema using Drift's table definition
          await m.createTable(rawMeatProcessings);
          
          // Step 3: Copy data from old table to new table, mapping old columns to new
          await customStatement('''
            INSERT INTO raw_meat_processings (
              id, batch_number, 
              live_gross_weight, live_crate_weight, live_crate_count, live_net_weight,
              slaughtered_gross_weight, slaughtered_basket_weight, slaughtered_basket_count, slaughtered_net_weight,
              net_weight, total_cost, supplier_id, processing_date, notes, created_by, created_at, updated_at
            )
            SELECT 
              id, batch_number,
              0.0, 0.0, 0, 0.0,
              COALESCE(gross_weight, net_weight), 0.0, 0, net_weight,
              net_weight, COALESCE(total_cost, 0.0), supplier_id, processing_date, notes, created_by, created_at, updated_at
            FROM raw_meat_processings_old
          ''');
          
          // Step 4: Drop old table
          await customStatement('DROP TABLE raw_meat_processings_old');
        }
      }
      if (from < 11) {
        await m.addColumn(stockConversions, stockConversions.operationalExpenses);
      }
      if (from < 12) {
        await m.addColumn(rawMeatProcessings, rawMeatProcessings.operationalExpenses);
      }
      if (from < 13) {
        await m.addColumn(payments, payments.invoiceId);
        await m.addColumn(payments, payments.purchaseInvoiceId);
      }
      if (from < 14) {
        await m.createTable(employees);
        await m.addColumn(salaries, salaries.employeeId);
      }
      if (from < 15) {
        // Accounting module tables
        await m.createTable(systemSettings);
        await m.createTable(accounts);
        await m.createTable(journalEntries);
        await m.createTable(journalEntryLines);
        await m.createTable(paymentLedgerEntries);
        await m.createTable(creditNotes);
        await m.createTable(taxTemplates);
        await m.createTable(taxTemplateRows);
        await m.createTable(paymentAllocations);
        
        // Seed default chart of accounts
        await _seedDefaultChartOfAccounts();
        
        // Seed default system settings
        await _seedDefaultSystemSettings();
      }
    },
  );

  // Factory Reset
  Future<void> clearAllData() async {
    // Disable foreign keys to allow deleting in any order
    await customStatement('PRAGMA foreign_keys = OFF');
    
    try {
      await delete(salesInvoiceItems).go();
      await delete(salesInvoices).go();
      await delete(purchaseInvoiceItems).go();
      await delete(purchaseInvoices).go();
      await delete(inventoryBatches).go();
      await delete(processingOutputs).go();
      await delete(stockConversionItems).go();
      await delete(stockConversions).go();
      await delete(rawMeatProcessings).go();
      await delete(payments).go();
      await delete(cashTransactions).go();
      await delete(expenses).go();
      await delete(salaries).go();
      await delete(annualInventories).go();
      await delete(employees).go();
      await delete(partnerTransactions).go();
      await delete(partners).go();
      await delete(auditLogs).go();
      await delete(productPrices).go();
      await delete(products).go();
      await delete(customers).go();
      await delete(suppliers).go();
      await delete(expenseCategories).go();
      await delete(backups).go();
      await delete(users).go();
      
      // Re-enable foreign keys
      await customStatement('PRAGMA foreign_keys = ON');
      
      // Re-seed default data
      await _seedDefaultData();
    } catch (e) {
      // Ensure FKs are back on even if error
      await customStatement('PRAGMA foreign_keys = ON');
      rethrow;
    }
  }

  // Seed default data
  Future<void> _seedDefaultData() async {
    // Create default admin user
    final hashedPassword = SecurityUtils.hashPassword(AppConstants.defaultAdminPassword);
    
    await into(users).insert(
      UsersCompanion.insert(
        username: AppConstants.defaultAdminUsername,
        passwordHash: hashedPassword,
        fullName: 'مدير النظام',
        role: UserRole.admin.code,
      ),
    );

    // Create default expense categories
    final defaultCategories = [
      'وقود',
      'كهرباء',
      'صيانة',
      'تبريد',
      'نقل',
      'إيجار',
      'مصاريف إدارية',
    ];

    for (final category in defaultCategories) {
      await into(expenseCategories).insert(
        ExpenseCategoriesCompanion.insert(
          name: category,
        ),
      );
    }

    // Create default partners (50/50 split as requested)
    await into(partners).insert(
      PartnersCompanion.insert(
        name: 'الشريك الأول',
        sharePercentage: const Value(50),
      ),
    );
    
    await _seedSystemProducts();
    
    // Seed accounting data
    await _seedDefaultChartOfAccounts();
    await _seedDefaultSystemSettings();
  }

  Future<void> _seedSystemProducts() async {
    // 1. Live Chicken (Raw Material) - ID 1
    final liveExist = await (select(products)..where((t) => t.id.equals(AppConstants.liveChickenId))).getSingleOrNull();
    if (liveExist == null) {
      await into(products).insert(
        ProductsCompanion(
          id: const Value(AppConstants.liveChickenId),
          name: const Value('دجاج حي (ريش)'),
          unitType: Value(UnitType.kilogram.code),
          productType: Value(ProductType.raw.code),
          isActive: const Value(true),
        ),
      );
    }

    // 2. Whole Slaughtered Chicken (Intermediate) - ID 2
    final wholeExist = await (select(products)..where((t) => t.id.equals(AppConstants.wholeChickenId))).getSingleOrNull();
    if (wholeExist == null) {
      await into(products).insert(
        ProductsCompanion(
          id: const Value(AppConstants.wholeChickenId),
          name: const Value('دجاج مذبوح كامل'),
          unitType: Value(UnitType.kilogram.code),
          productType: Value(ProductType.intermediate.code),
          isActive: const Value(true),
        ),
      );
    }
  }

  /// Seed default system settings
  Future<void> _seedDefaultSystemSettings() async {
    final defaults = {
      'gl_engine_enabled': 'false',
      'tax_engine_enabled': 'false',
    };
    for (final entry in defaults.entries) {
      final existing = await (select(systemSettings)
            ..where((t) => t.key.equals(entry.key)))
          .getSingleOrNull();
      if (existing == null) {
        await into(systemSettings).insert(
          SystemSettingsCompanion.insert(
            key: entry.key,
            value: entry.value,
          ),
        );
      }
    }
  }

  /// Seed default chart of accounts (matching ACCOUNT_CODES from TypeScript)
  Future<void> _seedDefaultChartOfAccounts() async {
    // Check if accounts already exist
    final existingCount = await (select(accounts)..limit(1)).get();
    if (existingCount.isNotEmpty) return;

    const companyId = 1;

    // Group accounts (parents)
    final groupAccounts = [
      // Assets
      {'code': '1000', 'name': 'الأصول', 'nameEn': 'Assets', 'type': 'asset', 'rootType': 'Asset', 'reportType': 'Balance Sheet', 'isGroup': true},
      {'code': '1100', 'name': 'الأصول المتداولة', 'nameEn': 'Current Assets', 'type': 'asset', 'rootType': 'Asset', 'reportType': 'Balance Sheet', 'isGroup': true, 'parentCode': '1000'},
      {'code': '1110', 'name': 'النقد والبنوك', 'nameEn': 'Cash & Bank', 'type': 'asset', 'rootType': 'Asset', 'reportType': 'Balance Sheet', 'isGroup': true, 'parentCode': '1100'},
      {'code': '1130', 'name': 'المخزون', 'nameEn': 'Inventory', 'type': 'asset', 'rootType': 'Asset', 'reportType': 'Balance Sheet', 'isGroup': true, 'parentCode': '1100'},
      // Liabilities
      {'code': '2000', 'name': 'الخصوم', 'nameEn': 'Liabilities', 'type': 'liability', 'rootType': 'Liability', 'reportType': 'Balance Sheet', 'isGroup': true},
      {'code': '2100', 'name': 'الخصوم المتداولة', 'nameEn': 'Current Liabilities', 'type': 'liability', 'rootType': 'Liability', 'reportType': 'Balance Sheet', 'isGroup': true, 'parentCode': '2000'},
      // Equity
      {'code': '3000', 'name': 'حقوق الملكية', 'nameEn': 'Equity', 'type': 'equity', 'rootType': 'Equity', 'reportType': 'Balance Sheet', 'isGroup': true},
      // Revenue
      {'code': '4000', 'name': 'الإيرادات', 'nameEn': 'Revenue', 'type': 'revenue', 'rootType': 'Income', 'reportType': 'Profit and Loss', 'isGroup': true},
      {'code': '4100', 'name': 'إيرادات المبيعات', 'nameEn': 'Sales Revenue', 'type': 'revenue', 'rootType': 'Income', 'reportType': 'Profit and Loss', 'isGroup': true, 'parentCode': '4000'},
      // Expenses
      {'code': '5000', 'name': 'المصروفات', 'nameEn': 'Expenses', 'type': 'expense', 'rootType': 'Expense', 'reportType': 'Profit and Loss', 'isGroup': true},
    ];

    // Postable accounts (leaves)
    final postableAccounts = [
      // Assets - Cash & Bank
      {'code': '1111', 'name': 'الصندوق', 'nameEn': 'Cash in Drawer', 'type': 'asset', 'rootType': 'Asset', 'reportType': 'Balance Sheet', 'parentCode': '1110', 'balanceMustBe': 'Debit'},
      {'code': '1112', 'name': 'البنك', 'nameEn': 'Bank', 'type': 'asset', 'rootType': 'Asset', 'reportType': 'Balance Sheet', 'parentCode': '1110', 'balanceMustBe': 'Debit'},
      // Assets - Receivables
      {'code': '1120', 'name': 'ذمم مدينة', 'nameEn': 'Accounts Receivable', 'type': 'asset', 'rootType': 'Asset', 'reportType': 'Balance Sheet', 'parentCode': '1100', 'balanceMustBe': 'Debit'},
      {'code': '1125', 'name': 'ضريبة مدخلات', 'nameEn': 'VAT Receivable', 'type': 'asset', 'rootType': 'Asset', 'reportType': 'Balance Sheet', 'parentCode': '1100', 'balanceMustBe': 'Debit'},
      // Assets - Inventory
      {'code': '1131', 'name': 'مخزون دجاج طازج', 'nameEn': 'Fresh Chicken Inventory', 'type': 'asset', 'rootType': 'Asset', 'reportType': 'Balance Sheet', 'parentCode': '1130', 'balanceMustBe': 'Debit'},
      // Liabilities
      {'code': '2110', 'name': 'ذمم دائنة', 'nameEn': 'Accounts Payable', 'type': 'liability', 'rootType': 'Liability', 'reportType': 'Balance Sheet', 'parentCode': '2100', 'balanceMustBe': 'Credit'},
      {'code': '2120', 'name': 'ضريبة مخرجات', 'nameEn': 'VAT Payable', 'type': 'liability', 'rootType': 'Liability', 'reportType': 'Balance Sheet', 'parentCode': '2100', 'balanceMustBe': 'Credit'},
      // Equity
      {'code': '3100', 'name': 'رأس المال', 'nameEn': 'Capital', 'type': 'equity', 'rootType': 'Equity', 'reportType': 'Balance Sheet', 'parentCode': '3000', 'balanceMustBe': 'Credit'},
      {'code': '3200', 'name': 'أرباح محتجزة', 'nameEn': 'Retained Earnings', 'type': 'equity', 'rootType': 'Equity', 'reportType': 'Balance Sheet', 'parentCode': '3000', 'balanceMustBe': 'Credit'},
      // Revenue
      {'code': '4110', 'name': 'مبيعات دجاج طازج', 'nameEn': 'Fresh Chicken Sales', 'type': 'revenue', 'rootType': 'Income', 'reportType': 'Profit and Loss', 'parentCode': '4100'},
      {'code': '4200', 'name': 'إيرادات أخرى', 'nameEn': 'Other Income', 'type': 'revenue', 'rootType': 'Income', 'reportType': 'Profit and Loss', 'parentCode': '4000'},
      // Expenses
      {'code': '5100', 'name': 'تكلفة البضاعة المباعة', 'nameEn': 'Cost of Goods Sold', 'type': 'expense', 'rootType': 'Expense', 'reportType': 'Profit and Loss', 'parentCode': '5000'},
      {'code': '5300', 'name': 'مصروف هدر', 'nameEn': 'Wastage Expense', 'type': 'expense', 'rootType': 'Expense', 'reportType': 'Profit and Loss', 'parentCode': '5000'},
      {'code': '5320', 'name': 'تعديل مخزون', 'nameEn': 'Inventory Adjustment', 'type': 'expense', 'rootType': 'Expense', 'reportType': 'Profit and Loss', 'parentCode': '5000'},
      {'code': '5400', 'name': 'مصروفات تشغيلية', 'nameEn': 'Operating Expenses', 'type': 'expense', 'rootType': 'Expense', 'reportType': 'Profit and Loss', 'parentCode': '5000'},
    ];

    // Insert group accounts first
    final codeToId = <String, int>{};
    for (final acc in groupAccounts) {
      final parentCode = acc['parentCode'] as String?;
      final parentId = parentCode != null ? codeToId[parentCode] : null;
      final id = await into(accounts).insert(
        AccountsCompanion.insert(
          code: acc['code'] as String,
          name: acc['name'] as String,
          nameEn: Value(acc['nameEn'] as String?),
          accountType: acc['type'] as String,
          rootType: Value(acc['rootType'] as String?),
          reportType: Value(acc['reportType'] as String?),
          parentId: Value(parentId),
          isGroup: const Value(true),
          companyId: const Value(companyId),
        ),
      );
      codeToId[acc['code'] as String] = id;
    }

    // Insert postable accounts
    for (final acc in postableAccounts) {
      final parentCode = acc['parentCode'] as String?;
      final parentId = parentCode != null ? codeToId[parentCode] : null;
      final id = await into(accounts).insert(
        AccountsCompanion.insert(
          code: acc['code'] as String,
          name: acc['name'] as String,
          nameEn: Value(acc['nameEn'] as String?),
          accountType: acc['type'] as String,
          rootType: Value(acc['rootType'] as String?),
          reportType: Value(acc['reportType'] as String?),
          parentId: Value(parentId),
          isGroup: const Value(false),
          balanceMustBe: Value(acc['balanceMustBe'] as String?),
          companyId: const Value(companyId),
        ),
      );
      codeToId[acc['code'] as String] = id;
    }
  }
}

// ============================================================================
// DATABASE CONNECTION
// ============================================================================

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, AppConstants.databaseName));
    
    return NativeDatabase.createInBackground(file);
  });
}
