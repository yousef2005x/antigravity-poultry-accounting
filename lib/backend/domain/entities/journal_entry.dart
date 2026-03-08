import 'package:meta/meta.dart';

/// Journal Entry Line
@immutable
class JournalEntryLine {
  const JournalEntryLine({
    this.id,
    this.journalEntryId,
    this.lineNumber = 0,
    required this.accountId,
    this.debitAmount = 0,
    this.creditAmount = 0,
    this.debitInAccountCurrency,
    this.creditInAccountCurrency,
    this.description,
    this.partyType,
    this.partyId,
    this.costCenterId,
    this.accountCode,
    this.accountName,
    this.partyName,
  });

  final int? id;
  final int? journalEntryId;
  final int lineNumber;
  final int accountId;
  final double debitAmount;
  final double creditAmount;
  final double? debitInAccountCurrency;
  final double? creditInAccountCurrency;
  final String? description;
  final String? partyType; // customer, supplier
  final int? partyId;
  final int? costCenterId;

  // Display helpers (populated from joins)
  final String? accountCode;
  final String? accountName;
  final String? partyName;

  JournalEntryLine copyWith({
    int? id,
    int? journalEntryId,
    int? lineNumber,
    int? accountId,
    double? debitAmount,
    double? creditAmount,
    double? debitInAccountCurrency,
    double? creditInAccountCurrency,
    String? description,
    String? partyType,
    int? partyId,
    int? costCenterId,
    String? accountCode,
    String? accountName,
    String? partyName,
  }) {
    return JournalEntryLine(
      id: id ?? this.id,
      journalEntryId: journalEntryId ?? this.journalEntryId,
      lineNumber: lineNumber ?? this.lineNumber,
      accountId: accountId ?? this.accountId,
      debitAmount: debitAmount ?? this.debitAmount,
      creditAmount: creditAmount ?? this.creditAmount,
      debitInAccountCurrency: debitInAccountCurrency ?? this.debitInAccountCurrency,
      creditInAccountCurrency: creditInAccountCurrency ?? this.creditInAccountCurrency,
      description: description ?? this.description,
      partyType: partyType ?? this.partyType,
      partyId: partyId ?? this.partyId,
      costCenterId: costCenterId ?? this.costCenterId,
      accountCode: accountCode ?? this.accountCode,
      accountName: accountName ?? this.accountName,
      partyName: partyName ?? this.partyName,
    );
  }
}

/// Journal Entry (header + lines)
@immutable
class JournalEntry {
  const JournalEntry({
    this.id,
    required this.entryNumber,
    required this.entryDate,
    this.description,
    this.sourceType,
    this.sourceId,
    this.branchId,
    this.isPosted = false,
    this.isReversed = false,
    this.reversedByEntryId,
    this.createdById,
    this.createdByName,
    this.lines = const [],
    this.createdAt,
  });

  final int? id;
  final String entryNumber;
  final DateTime entryDate;
  final String? description;
  final String? sourceType;
  final int? sourceId;
  final int? branchId;
  final bool isPosted;
  final bool isReversed;
  final int? reversedByEntryId;
  final int? createdById;
  final String? createdByName;
  final List<JournalEntryLine> lines;
  final DateTime? createdAt;

  double get totalDebit => lines.fold(0, (sum, l) => sum + l.debitAmount);
  double get totalCredit => lines.fold(0, (sum, l) => sum + l.creditAmount);
  bool get isBalanced => (totalDebit - totalCredit).abs() < 0.01;

  JournalEntry copyWith({
    int? id,
    String? entryNumber,
    DateTime? entryDate,
    String? description,
    String? sourceType,
    int? sourceId,
    int? branchId,
    bool? isPosted,
    bool? isReversed,
    int? reversedByEntryId,
    int? createdById,
    String? createdByName,
    List<JournalEntryLine>? lines,
    DateTime? createdAt,
  }) {
    return JournalEntry(
      id: id ?? this.id,
      entryNumber: entryNumber ?? this.entryNumber,
      entryDate: entryDate ?? this.entryDate,
      description: description ?? this.description,
      sourceType: sourceType ?? this.sourceType,
      sourceId: sourceId ?? this.sourceId,
      branchId: branchId ?? this.branchId,
      isPosted: isPosted ?? this.isPosted,
      isReversed: isReversed ?? this.isReversed,
      reversedByEntryId: reversedByEntryId ?? this.reversedByEntryId,
      createdById: createdById ?? this.createdById,
      createdByName: createdByName ?? this.createdByName,
      lines: lines ?? this.lines,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() => 'JournalEntry(id: $id, entryNumber: $entryNumber, posted: $isPosted)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is JournalEntry && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Input for creating journal entry lines (used internally)
@immutable
class JournalLineInput {
  const JournalLineInput({
    this.accountCode,
    this.accountId,
    this.debitAmount = 0,
    this.creditAmount = 0,
    this.description,
    this.partyType,
    this.partyId,
  });

  final String? accountCode;
  final int? accountId;
  final double debitAmount;
  final double creditAmount;
  final String? description;
  final String? partyType;
  final int? partyId;
}

/// Trial Balance row
@immutable
class TrialBalanceRow {
  const TrialBalanceRow({
    required this.accountId,
    required this.accountCode,
    required this.accountName,
    required this.accountType,
    required this.debit,
    required this.credit,
    required this.balance,
  });

  final int accountId;
  final String accountCode;
  final String accountName;
  final String accountType;
  final double debit;
  final double credit;
  final double balance;
}

/// Balance Sheet data
@immutable
class BalanceSheet {
  const BalanceSheet({
    required this.assets,
    required this.liabilities,
    required this.equity,
    required this.totalAssets,
    required this.totalLiabilities,
    required this.totalEquity,
    required this.asOfDate,
  });

  final List<TrialBalanceRow> assets;
  final List<TrialBalanceRow> liabilities;
  final List<TrialBalanceRow> equity;
  final double totalAssets;
  final double totalLiabilities;
  final double totalEquity;
  final String asOfDate;
}

/// Income Statement data
@immutable
class IncomeStatement {
  const IncomeStatement({
    required this.revenue,
    required this.expenses,
    required this.totalRevenue,
    required this.totalExpenses,
    required this.netIncome,
    required this.startDate,
    required this.endDate,
  });

  final List<IncomeStatementRow> revenue;
  final List<IncomeStatementRow> expenses;
  final double totalRevenue;
  final double totalExpenses;
  final double netIncome;
  final String startDate;
  final String endDate;
}

/// Income Statement row
@immutable
class IncomeStatementRow {
  const IncomeStatementRow({
    required this.accountCode,
    required this.accountName,
    required this.amount,
  });

  final String accountCode;
  final String accountName;
  final double amount;
}

/// Account Ledger entry
@immutable
class LedgerEntry {
  const LedgerEntry({
    this.id,
    required this.entryDate,
    required this.entryNumber,
    required this.description,
    required this.debit,
    required this.credit,
    required this.balance,
  });

  final int? id;
  final DateTime entryDate;
  final String entryNumber;
  final String description;
  final double debit;
  final double credit;
  final double balance;
}
