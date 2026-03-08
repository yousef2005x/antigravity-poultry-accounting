import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poultry_accounting/backend/data/repositories/accounting_repository_impl.dart';
import 'package:poultry_accounting/backend/domain/entities/account.dart';
import 'package:poultry_accounting/backend/domain/entities/journal_entry.dart';
import 'package:poultry_accounting/backend/domain/entities/credit_note.dart';
import 'package:poultry_accounting/backend/domain/repositories/accounting_repository.dart';
import 'package:poultry_accounting/core/providers/database_providers.dart';

// ============ REPOSITORY PROVIDER ============

final accountingRepositoryProvider = Provider<AccountingRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return AccountingRepositoryImpl(db);
});

// ============ CHART OF ACCOUNTS ============

/// Stream provider for watching all accounts
final accountsStreamProvider = StreamProvider<List<Account>>((ref) {
  final repo = ref.watch(accountingRepositoryProvider);
  return repo.watchAllAccounts();
});

/// Future provider for all postable accounts (for dropdowns)
final postableAccountsProvider = FutureProvider<List<Account>>((ref) {
  ref.watch(accountsStreamProvider); // refresh when accounts change
  final repo = ref.read(accountingRepositoryProvider);
  return repo.getAllAccounts(postableOnly: true);
});

// ============ JOURNAL ENTRIES ============

/// Stream provider for watching journal entries
final journalEntriesStreamProvider = StreamProvider<List<JournalEntry>>((ref) {
  final repo = ref.watch(accountingRepositoryProvider);
  return repo.watchJournalEntries();
});

// ============ TRIAL BALANCE ============

/// Future provider for trial balance
final trialBalanceProvider = FutureProvider<List<TrialBalanceRow>>((ref) {
  ref.watch(journalEntriesStreamProvider); // refresh when entries change
  final repo = ref.read(accountingRepositoryProvider);
  return repo.getTrialBalance();
});

// ============ BALANCE SHEET ============

/// Future provider for balance sheet
final balanceSheetProvider = FutureProvider<BalanceSheet>((ref) {
  ref.watch(journalEntriesStreamProvider);
  final repo = ref.read(accountingRepositoryProvider);
  return repo.getBalanceSheet();
});

// ============ INCOME STATEMENT ============

/// Family provider for income statement (parameterized by date range)
final incomeStatementProvider =
    FutureProvider.family<IncomeStatement, ({String startDate, String endDate})>((ref, params) {
  ref.watch(journalEntriesStreamProvider);
  final repo = ref.read(accountingRepositoryProvider);
  return repo.getIncomeStatement(startDate: params.startDate, endDate: params.endDate);
});

// ============ ACCOUNT LEDGER ============

/// Family provider for account ledger (parameterized by account code)
final accountLedgerProvider =
    FutureProvider.family<List<LedgerEntry>, String>((ref, accountCode) {
  ref.watch(journalEntriesStreamProvider);
  final repo = ref.read(accountingRepositoryProvider);
  return repo.getAccountLedger(accountCode);
});

// ============ CREDIT NOTES ============

/// Future provider for credit notes list
final creditNotesProvider = FutureProvider<List<CreditNote>>((ref) {
  final repo = ref.read(accountingRepositoryProvider);
  return repo.getCreditNotes();
});
