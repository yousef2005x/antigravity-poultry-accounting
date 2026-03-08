import 'package:poultry_accounting/backend/domain/entities/account.dart';
import 'package:poultry_accounting/backend/domain/entities/journal_entry.dart';
import 'package:poultry_accounting/backend/domain/entities/credit_note.dart';

/// Accounting Repository Interface
abstract class AccountingRepository {
  // ============ CHART OF ACCOUNTS ============

  /// Get all accounts (flat list)
  Future<List<Account>> getAllAccounts({bool postableOnly = false});

  /// Watch all accounts
  Stream<List<Account>> watchAllAccounts();

  /// Get account by ID
  Future<Account?> getAccountById(int id);

  /// Get account by code
  Future<Account?> getAccountByCode(String code);

  /// Get account ID by code
  Future<int?> getAccountIdByCode(String code);

  /// Create a new account
  Future<int> createAccount(Account account);

  /// Update an existing account
  Future<void> updateAccount(Account account);

  /// Delete an account
  Future<void> deleteAccount(int id);

  /// Check if account can be deleted
  Future<Map<String, bool>> canDeleteAccount(int id);

  // ============ JOURNAL ENTRIES ============

  /// Get journal entries with pagination
  Future<List<JournalEntry>> getJournalEntries({int page = 1, int pageSize = 20});

  /// Watch journal entries
  Stream<List<JournalEntry>> watchJournalEntries();

  /// Get journal entry by ID (with lines)
  Future<JournalEntry?> getJournalEntryById(int id);

  /// Create a manual journal entry
  Future<JournalEntry> createJournalEntry({
    required String description,
    required List<JournalEntryLine> lines,
    required int userId,
    String? sourceType,
    int? sourceId,
    int? branchId,
    DateTime? entryDate,
  });

  /// Post a journal entry
  Future<void> postJournalEntry(int id);

  /// Reverse a journal entry
  Future<JournalEntry> reverseJournalEntry(int id, int userId);

  // ============ AUTO JOURNAL ENTRIES ============

  /// Create journal entry for a sale transaction
  Future<void> createSaleJournalEntry({
    required int saleId,
    required String saleNumber,
    required int userId,
    required double totalAmount,
    required double totalCost,
    required double amountPaid,
    int? customerId,
    double? discountAmount,
    int? branchId,
    DateTime? saleDate,
  });

  /// Create reversal journal entry for voided sale
  Future<void> createSaleVoidJournalEntry({
    required int saleId,
    required String saleNumber,
    required int userId,
    required double totalAmount,
    required double totalCost,
    required double amountPaid,
    double? discountAmount,
    int? customerId,
    int? branchId,
  });

  /// Create journal entry for purchase
  Future<void> createPurchaseJournalEntry({
    required int purchaseId,
    required String purchaseNumber,
    required int userId,
    required double totalAmount,
    required double amountPaid,
    int? supplierId,
    int? branchId,
  });

  /// Create journal entry for payment received
  Future<void> createPaymentReceivedJournalEntry({
    required int paymentId,
    required String paymentNumber,
    required int userId,
    required double amount,
    int? branchId,
  });

  /// Create journal entry for payment made
  Future<void> createPaymentMadeJournalEntry({
    required int paymentId,
    required String paymentNumber,
    required int userId,
    required double amount,
    int? branchId,
  });

  /// Create journal entry for expense
  Future<void> createExpenseJournalEntry({
    required int expenseId,
    required String expenseNumber,
    required int userId,
    required double amount,
    String? paymentMethod,
    int? branchId,
  });

  /// Create journal entry for wastage
  Future<void> createWastageJournalEntry({
    required int wastageId,
    required int userId,
    required double amount,
    int? branchId,
  });

  // ============ REPORTS ============

  /// Get trial balance
  Future<List<TrialBalanceRow>> getTrialBalance({String? asOfDate});

  /// Get balance sheet
  Future<BalanceSheet> getBalanceSheet({String? asOfDate});

  /// Get income statement
  Future<IncomeStatement> getIncomeStatement({
    required String startDate,
    required String endDate,
  });

  /// Get account ledger
  Future<List<LedgerEntry>> getAccountLedger(
    String accountCode, {
    String? startDate,
    String? endDate,
  });

  // ============ CREDIT NOTES ============

  /// Get all credit notes
  Future<List<CreditNote>> getCreditNotes({int page = 1, int pageSize = 20});

  /// Get credit note by ID
  Future<CreditNote?> getCreditNoteById(int id);

  /// Create a credit note (draft)
  Future<CreditNote> createCreditNote({
    required String originalInvoiceType,
    required int originalInvoiceId,
    required double amount,
    required int userId,
    String? reason,
    int? branchId,
  });

  /// Submit a credit note (creates GL + PLE entries)
  Future<CreditNote?> submitCreditNote(int id, int userId);

  // ============ SYSTEM SETTINGS ============

  /// Get a system setting value
  Future<String?> getSystemSetting(String key);

  /// Set a system setting value
  Future<void> setSystemSetting(String key, String value);
}
