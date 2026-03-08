import 'package:drift/drift.dart';
import 'package:poultry_accounting/backend/data/database/database.dart' as db;
import 'package:poultry_accounting/backend/domain/entities/account.dart';
import 'package:poultry_accounting/backend/domain/entities/journal_entry.dart';
import 'package:poultry_accounting/backend/domain/entities/credit_note.dart';
import 'package:poultry_accounting/backend/domain/repositories/accounting_repository.dart';

/// Standard account codes — must match seeded chart of accounts
class AccountCodes {
  static const cash = '1111';
  static const bank = '1112';
  static const accountsReceivable = '1120';
  static const vatReceivable = '1125';
  static const inventory = '1131';
  static const accountsPayable = '2110';
  static const vatPayable = '2120';
  static const capital = '3100';
  static const retainedEarnings = '3200';
  static const salesRevenue = '4110';
  static const otherIncome = '4200';
  static const costOfGoodsSold = '5100';
  static const wastageExpense = '5300';
  static const inventoryAdjustment = '5320';
  static const operatingExpenses = '5400';
  static const discountsGiven = '5400'; // Same as operating expenses
}

class AccountingRepositoryImpl implements AccountingRepository {
  AccountingRepositoryImpl(this._db);
  final db.AppDatabase _db;

  // ============ CHART OF ACCOUNTS ============

  @override
  Future<List<Account>> getAllAccounts({bool postableOnly = false}) async {
    final query = _db.select(_db.accounts)
      ..where((t) => t.isActive.equals(true))
      ..orderBy([(t) => OrderingTerm.asc(t.code)]);
    if (postableOnly) {
      query.where((t) => t.isGroup.equals(false));
    }
    final rows = await query.get();
    return rows.map(_mapAccountToEntity).toList();
  }

  @override
  Stream<List<Account>> watchAllAccounts() {
    return (_db.select(_db.accounts)
          ..where((t) => t.isActive.equals(true))
          ..orderBy([(t) => OrderingTerm.asc(t.code)]))
        .watch()
        .map((rows) => rows.map(_mapAccountToEntity).toList());
  }

  @override
  Future<Account?> getAccountById(int id) async {
    final row = await (_db.select(_db.accounts)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    return row != null ? _mapAccountToEntity(row) : null;
  }

  @override
  Future<Account?> getAccountByCode(String code) async {
    final row = await (_db.select(_db.accounts)
          ..where((t) => t.code.equals(code)))
        .getSingleOrNull();
    return row != null ? _mapAccountToEntity(row) : null;
  }

  @override
  Future<int?> getAccountIdByCode(String code) async {
    final row = await (_db.select(_db.accounts)
          ..where((t) => t.code.equals(code)))
        .getSingleOrNull();
    return row?.id;
  }

  @override
  Future<int> createAccount(Account account) {
    return _db.into(_db.accounts).insert(
      db.AccountsCompanion.insert(
        code: account.code,
        name: account.name,
        nameEn: Value(account.nameEn),
        accountType: account.accountType,
        rootType: Value(account.rootType),
        reportType: Value(account.reportType),
        parentId: Value(account.parentId),
        isGroup: Value(account.isGroup),
        balanceMustBe: Value(account.balanceMustBe),
        accountCurrency: Value(account.accountCurrency),
        companyId: Value(account.companyId ?? 1),
      ),
    );
  }

  @override
  Future<void> updateAccount(Account account) async {
    await (_db.update(_db.accounts)..where((t) => t.id.equals(account.id!)))
        .write(
      db.AccountsCompanion(
        name: Value(account.name),
        nameEn: Value(account.nameEn),
        accountType: Value(account.accountType),
        parentId: Value(account.parentId),
        isGroup: Value(account.isGroup),
        isActive: Value(account.isActive),
        balanceMustBe: Value(account.balanceMustBe),
        accountCurrency: Value(account.accountCurrency),
        freezeAccount: Value(account.freezeAccount),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  @override
  Future<void> deleteAccount(int id) async {
    await (_db.delete(_db.accounts)..where((t) => t.id.equals(id))).go();
  }

  @override
  Future<Map<String, bool>> canDeleteAccount(int id) async {
    // Check for journal entry lines referencing this account
    final hasEntries = await (_db.select(_db.journalEntryLines)
          ..where((t) => t.accountId.equals(id))
          ..limit(1))
        .get();
    // Check for child accounts
    final hasChildren = await (_db.select(_db.accounts)
          ..where((t) => t.parentId.equals(id))
          ..limit(1))
        .get();
    return {
      'canDelete': hasEntries.isEmpty && hasChildren.isEmpty,
      'hasEntries': hasEntries.isNotEmpty,
      'hasChildren': hasChildren.isNotEmpty,
    };
  }

  // ============ JOURNAL ENTRIES ============

  @override
  Future<List<JournalEntry>> getJournalEntries({int page = 1, int pageSize = 20}) async {
    final query = _db.select(_db.journalEntries)
      ..orderBy([(t) => OrderingTerm.desc(t.entryDate)])
      ..limit(pageSize, offset: (page - 1) * pageSize);
    final rows = await query.get();
    return Future.wait(rows.map((r) async => _mapJournalEntryToEntity(r, await _getJournalLines(r.id))).toList());
  }

  @override
  Stream<List<JournalEntry>> watchJournalEntries() {
    return (_db.select(_db.journalEntries)
          ..orderBy([(t) => OrderingTerm.desc(t.entryDate)])
          ..limit(50))
        .watch()
        .asyncMap((rows) async {
      return Future.wait(rows.map((r) async => _mapJournalEntryToEntity(r, await _getJournalLines(r.id))).toList());
    });
  }

  @override
  Future<JournalEntry?> getJournalEntryById(int id) async {
    final row = await (_db.select(_db.journalEntries)..where((t) => t.id.equals(id))).getSingleOrNull();
    if (row == null) return null;
    final lines = await _getJournalLines(id);
    return _mapJournalEntryToEntity(row, lines);
  }

  Future<List<JournalEntryLine>> _getJournalLines(int entryId) async {
    final query = _db.select(_db.journalEntryLines).join([
      innerJoin(_db.accounts, _db.accounts.id.equalsExp(_db.journalEntryLines.accountId)),
    ])
      ..where(_db.journalEntryLines.journalEntryId.equals(entryId))
      ..orderBy([OrderingTerm.asc(_db.journalEntryLines.lineNumber)]);
    final rows = await query.get();
    return rows.map((r) {
      final line = r.readTable(_db.journalEntryLines);
      final account = r.readTable(_db.accounts);
      return JournalEntryLine(
        id: line.id,
        journalEntryId: line.journalEntryId,
        lineNumber: line.lineNumber,
        accountId: line.accountId,
        debitAmount: line.debitAmount,
        creditAmount: line.creditAmount,
        description: line.description,
        partyType: line.partyType,
        partyId: line.partyId,
        costCenterId: line.costCenterId,
        accountCode: account.code,
        accountName: account.name,
      );
    }).toList();
  }

  @override
  Future<JournalEntry> createJournalEntry({
    required String description,
    required List<JournalEntryLine> lines,
    required int userId,
    String? sourceType,
    int? sourceId,
    int? branchId,
    DateTime? entryDate,
  }) async {
    return _db.transaction(() async {
      // Validate balance
      final totalDebit = lines.fold(0.0, (sum, l) => sum + l.debitAmount);
      final totalCredit = lines.fold(0.0, (sum, l) => sum + l.creditAmount);
      if ((totalDebit - totalCredit).abs() > 0.01) {
        throw Exception('القيد غير متوازن: مدين=$totalDebit، دائن=$totalCredit');
      }

      final entryNumber = await _generateEntryNumber();
      final entryId = await _db.into(_db.journalEntries).insert(
        db.JournalEntriesCompanion.insert(
          entryNumber: entryNumber,
          entryDate: entryDate ?? DateTime.now(),
          description: Value(description),
          sourceType: Value(sourceType),
          sourceId: Value(sourceId),
          branchId: Value(branchId),
          createdById: userId,
        ),
      );

      for (int i = 0; i < lines.length; i++) {
        final line = lines[i];
        await _db.into(_db.journalEntryLines).insert(
          db.JournalEntryLinesCompanion.insert(
            journalEntryId: entryId,
            lineNumber: i + 1,
            accountId: line.accountId,
            debitAmount: Value(line.debitAmount),
            creditAmount: Value(line.creditAmount),
            description: Value(line.description),
            partyType: Value(line.partyType),
            partyId: Value(line.partyId),
          ),
        );
      }

      final entry = await getJournalEntryById(entryId);
      return entry!;
    });
  }

  @override
  Future<void> postJournalEntry(int id) async {
    await (_db.update(_db.journalEntries)..where((t) => t.id.equals(id)))
        .write(const db.JournalEntriesCompanion(isPosted: Value(true)));
  }

  @override
  Future<JournalEntry> reverseJournalEntry(int id, int userId) async {
    return _db.transaction(() async {
      final original = await getJournalEntryById(id);
      if (original == null) throw Exception('القيد غير موجود');
      if (original.isReversed) throw Exception('القيد معكوس بالفعل');

      final reversalLines = original.lines.map((l) => JournalEntryLine(
            accountId: l.accountId,
            debitAmount: l.creditAmount,
            creditAmount: l.debitAmount,
            description: 'عكس: ${l.description ?? original.description ?? ''}',
          )).toList();

      final reversal = await createJournalEntry(
        description: 'عكس: ${original.description ?? ''}',
        lines: reversalLines,
        userId: userId,
        sourceType: 'reversal',
        sourceId: original.id,
        branchId: original.branchId,
      );

      await (_db.update(_db.journalEntries)..where((t) => t.id.equals(id))).write(
        db.JournalEntriesCompanion(
          isReversed: const Value(true),
          reversedByEntryId: Value(reversal.id),
        ),
      );

      return reversal;
    });
  }

  // ============ AUTO JOURNAL ENTRIES ============

  Future<int?> _resolveAccountId(String code) async {
    return getAccountIdByCode(code);
  }

  Future<int> _requireAccountId(String code) async {
    final id = await _resolveAccountId(code);
    if (id == null) throw Exception('الحساب المحاسبي غير موجود: كود $code');
    return id;
  }

  Future<String> _generateEntryNumber() async {
    final count = await _db.journalEntries.count().getSingle();
    return 'JE-${(count + 1).toString().padLeft(6, '0')}';
  }

  Future<void> _createAutoJournalEntry({
    required String description,
    required String sourceType,
    required int sourceId,
    required int userId,
    required List<JournalLineInput> lines,
    int? branchId,
    bool autoPost = true,
  }) async {
    // Resolve account codes to IDs
    final resolvedLines = <JournalEntryLine>[];
    for (final line in lines) {
      int? accountId = line.accountId;
      if (accountId == null && line.accountCode != null) {
        accountId = await _requireAccountId(line.accountCode!);
      }
      if (accountId == null) throw Exception('كل سطر في القيد يجب أن يحتوي على حساب محاسبي');
      resolvedLines.add(JournalEntryLine(
        accountId: accountId,
        debitAmount: line.debitAmount,
        creditAmount: line.creditAmount,
        description: line.description,
        partyType: line.partyType,
        partyId: line.partyId,
      ));
    }

    final entryNumber = await _generateEntryNumber();
    final entryId = await _db.into(_db.journalEntries).insert(
      db.JournalEntriesCompanion.insert(
        entryNumber: entryNumber,
        entryDate: DateTime.now(),
        description: Value(description),
        sourceType: Value(sourceType),
        sourceId: Value(sourceId),
        branchId: Value(branchId),
        isPosted: Value(autoPost),
        createdById: userId,
      ),
    );

    for (int i = 0; i < resolvedLines.length; i++) {
      final line = resolvedLines[i];
      await _db.into(_db.journalEntryLines).insert(
        db.JournalEntryLinesCompanion.insert(
          journalEntryId: entryId,
          lineNumber: i + 1,
          accountId: line.accountId,
          debitAmount: Value(line.debitAmount),
          creditAmount: Value(line.creditAmount),
          description: Value(line.description),
          partyType: Value(line.partyType),
          partyId: Value(line.partyId),
        ),
      );
    }
  }

  @override
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
  }) async {
    final lines = <JournalLineInput>[];
    final amountDue = totalAmount - amountPaid;

    // DR Cash
    if (amountPaid > 0) {
      lines.add(JournalLineInput(accountCode: AccountCodes.cash, debitAmount: amountPaid, description: 'نقد مستلم'));
    }
    // DR Accounts Receivable
    if (amountDue > 0 && customerId != null) {
      lines.add(JournalLineInput(accountCode: AccountCodes.accountsReceivable, debitAmount: amountDue, description: 'بيع آجل'));
    }
    // CR Sales Revenue
    final netRevenue = totalAmount + (discountAmount ?? 0);
    lines.add(JournalLineInput(accountCode: AccountCodes.salesRevenue, creditAmount: netRevenue, description: 'إيراد مبيعات'));
    // DR Discounts Given
    if (discountAmount != null && discountAmount > 0) {
      lines.add(JournalLineInput(accountCode: AccountCodes.discountsGiven, debitAmount: discountAmount, description: 'خصم مبيعات'));
    }
    // DR COGS
    lines.add(JournalLineInput(accountCode: AccountCodes.costOfGoodsSold, debitAmount: totalCost, description: 'تكلفة البضاعة المباعة'));
    // CR Inventory
    lines.add(JournalLineInput(accountCode: AccountCodes.inventory, creditAmount: totalCost, description: 'تخفيض مخزون'));

    await _createAutoJournalEntry(
      description: 'بيع: $saleNumber',
      sourceType: 'sale',
      sourceId: saleId,
      userId: userId,
      lines: lines,
      branchId: branchId,
    );
  }

  @override
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
  }) async {
    final lines = <JournalLineInput>[];
    final amountDue = totalAmount - amountPaid;

    if (amountPaid > 0) {
      lines.add(JournalLineInput(accountCode: AccountCodes.cash, creditAmount: amountPaid, description: 'استرداد نقدي'));
    }
    if (amountDue > 0) {
      lines.add(JournalLineInput(accountCode: AccountCodes.accountsReceivable, creditAmount: amountDue, description: 'إلغاء ذمة مدينة'));
    }
    final netRevenue = totalAmount + (discountAmount ?? 0);
    lines.add(JournalLineInput(accountCode: AccountCodes.salesRevenue, debitAmount: netRevenue, description: 'عكس إيراد مبيعات'));
    if (discountAmount != null && discountAmount > 0) {
      lines.add(JournalLineInput(accountCode: AccountCodes.discountsGiven, creditAmount: discountAmount, description: 'عكس خصم'));
    }
    lines.add(JournalLineInput(accountCode: AccountCodes.costOfGoodsSold, creditAmount: totalCost, description: 'عكس تكلفة بضاعة'));
    lines.add(JournalLineInput(accountCode: AccountCodes.inventory, debitAmount: totalCost, description: 'استعادة مخزون'));

    await _createAutoJournalEntry(
      description: 'إلغاء بيع: $saleNumber',
      sourceType: 'sale_void',
      sourceId: saleId,
      userId: userId,
      lines: lines,
      branchId: branchId,
    );
  }

  @override
  Future<void> createPurchaseJournalEntry({
    required int purchaseId,
    required String purchaseNumber,
    required int userId,
    required double totalAmount,
    required double amountPaid,
    int? supplierId,
    int? branchId,
  }) async {
    final lines = <JournalLineInput>[];
    final amountDue = totalAmount - amountPaid;

    // DR Inventory
    lines.add(JournalLineInput(accountCode: AccountCodes.inventory, debitAmount: totalAmount, description: 'شراء مخزون'));
    // CR Cash
    if (amountPaid > 0) {
      lines.add(JournalLineInput(accountCode: AccountCodes.cash, creditAmount: amountPaid, description: 'دفع نقدي'));
    }
    // CR Accounts Payable
    if (amountDue > 0) {
      lines.add(JournalLineInput(accountCode: AccountCodes.accountsPayable, creditAmount: amountDue, description: 'شراء آجل'));
    }

    await _createAutoJournalEntry(
      description: 'شراء: $purchaseNumber',
      sourceType: 'purchase',
      sourceId: purchaseId,
      userId: userId,
      lines: lines,
      branchId: branchId,
    );
  }

  @override
  Future<void> createPaymentReceivedJournalEntry({
    required int paymentId,
    required String paymentNumber,
    required int userId,
    required double amount,
    int? branchId,
  }) async {
    await _createAutoJournalEntry(
      description: 'تحصيل: $paymentNumber',
      sourceType: 'payment',
      sourceId: paymentId,
      userId: userId,
      branchId: branchId,
      lines: [
        JournalLineInput(accountCode: AccountCodes.cash, debitAmount: amount, description: 'تحصيل دفعة'),
        JournalLineInput(accountCode: AccountCodes.accountsReceivable, creditAmount: amount, description: 'تخفيض ذمة مدينة'),
      ],
    );
  }

  @override
  Future<void> createPaymentMadeJournalEntry({
    required int paymentId,
    required String paymentNumber,
    required int userId,
    required double amount,
    int? branchId,
  }) async {
    await _createAutoJournalEntry(
      description: 'دفع: $paymentNumber',
      sourceType: 'payment',
      sourceId: paymentId,
      userId: userId,
      branchId: branchId,
      lines: [
        JournalLineInput(accountCode: AccountCodes.accountsPayable, debitAmount: amount, description: 'دفع مورد'),
        JournalLineInput(accountCode: AccountCodes.cash, creditAmount: amount, description: 'دفع نقدي'),
      ],
    );
  }

  @override
  Future<void> createExpenseJournalEntry({
    required int expenseId,
    required String expenseNumber,
    required int userId,
    required double amount,
    String? paymentMethod,
    int? branchId,
  }) async {
    final creditCode = paymentMethod == 'credit' ? AccountCodes.accountsPayable : AccountCodes.cash;
    final creditDesc = paymentMethod == 'credit' ? 'مصروف آجل' : 'دفع نقدي';

    await _createAutoJournalEntry(
      description: 'مصروف: $expenseNumber',
      sourceType: 'expense',
      sourceId: expenseId,
      userId: userId,
      branchId: branchId,
      lines: [
        JournalLineInput(accountCode: AccountCodes.operatingExpenses, debitAmount: amount, description: 'مصروف تشغيلي'),
        JournalLineInput(accountCode: creditCode, creditAmount: amount, description: creditDesc),
      ],
    );
  }

  @override
  Future<void> createWastageJournalEntry({
    required int wastageId,
    required int userId,
    required double amount,
    int? branchId,
  }) async {
    await _createAutoJournalEntry(
      description: 'هدر مخزون',
      sourceType: 'wastage',
      sourceId: wastageId,
      userId: userId,
      branchId: branchId,
      lines: [
        JournalLineInput(accountCode: AccountCodes.wastageExpense, debitAmount: amount, description: 'مصروف هدر'),
        JournalLineInput(accountCode: AccountCodes.inventory, creditAmount: amount, description: 'خسارة مخزون'),
      ],
    );
  }

  // ============ REPORTS ============

  @override
  Future<List<TrialBalanceRow>> getTrialBalance({String? asOfDate}) async {
    // Use raw SQL for GROUP BY aggregation
    final dateFilter = asOfDate != null
        ? "AND je.entry_date <= '${asOfDate}T23:59:59'"
        : '';

    final results = await _db.customSelect(
      '''
      SELECT 
        jel.account_id,
        a.code as account_code,
        a.name as account_name,
        a.account_type,
        COALESCE(SUM(jel.debit_amount), 0) as total_debit,
        COALESCE(SUM(jel.credit_amount), 0) as total_credit
      FROM journal_entry_lines jel
      INNER JOIN journal_entries je ON je.id = jel.journal_entry_id
      INNER JOIN accounts a ON a.id = jel.account_id
      WHERE je.is_posted = 1 $dateFilter
      GROUP BY jel.account_id, a.code, a.name, a.account_type
      ORDER BY a.code
      ''',
    ).get();

    return results.map((r) {
      final debit = (r.read<double>('total_debit'));
      final credit = (r.read<double>('total_credit'));
      return TrialBalanceRow(
        accountId: r.read<int>('account_id'),
        accountCode: r.read<String>('account_code'),
        accountName: r.read<String>('account_name'),
        accountType: r.read<String>('account_type'),
        debit: debit,
        credit: credit,
        balance: debit - credit,
      );
    }).toList();
  }

  @override
  Future<BalanceSheet> getBalanceSheet({String? asOfDate}) async {
    final accounts = await getTrialBalance(asOfDate: asOfDate);

    final assets = accounts.where((a) => a.accountType == 'asset').toList();
    final liabilities = accounts.where((a) => a.accountType == 'liability').toList();
    final equity = accounts.where((a) => a.accountType == 'equity').toList();

    return BalanceSheet(
      assets: assets,
      liabilities: liabilities,
      equity: equity,
      totalAssets: assets.fold(0, (sum, a) => sum + a.balance),
      totalLiabilities: liabilities.fold(0, (sum, a) => sum + a.balance),
      totalEquity: equity.fold(0, (sum, a) => sum + a.balance),
      asOfDate: asOfDate ?? DateTime.now().toIso8601String().split('T')[0],
    );
  }

  @override
  Future<IncomeStatement> getIncomeStatement({
    required String startDate,
    required String endDate,
  }) async {
    final results = await _db.customSelect(
      '''
      SELECT 
        a.code as account_code,
        a.name as account_name,
        a.account_type,
        COALESCE(SUM(jel.debit_amount), 0) as total_debit,
        COALESCE(SUM(jel.credit_amount), 0) as total_credit
      FROM journal_entry_lines jel
      INNER JOIN journal_entries je ON je.id = jel.journal_entry_id
      INNER JOIN accounts a ON a.id = jel.account_id
      WHERE je.is_posted = 1
        AND je.entry_date >= '${startDate}T00:00:00'
        AND je.entry_date <= '${endDate}T23:59:59'
        AND a.account_type IN ('revenue', 'expense')
      GROUP BY a.code, a.name, a.account_type
      ORDER BY a.code
      ''',
    ).get();

    final revenueRows = <IncomeStatementRow>[];
    final expenseRows = <IncomeStatementRow>[];

    for (final r in results) {
      final debit = r.read<double>('total_debit');
      final credit = r.read<double>('total_credit');
      final type = r.read<String>('account_type');

      if (type == 'revenue') {
        revenueRows.add(IncomeStatementRow(
          accountCode: r.read<String>('account_code'),
          accountName: r.read<String>('account_name'),
          amount: credit - debit, // Revenue: credits are positive
        ));
      } else {
        expenseRows.add(IncomeStatementRow(
          accountCode: r.read<String>('account_code'),
          accountName: r.read<String>('account_name'),
          amount: debit - credit, // Expenses: debits are positive
        ));
      }
    }

    final totalRevenue = revenueRows.fold(0.0, (sum, r) => sum + r.amount);
    final totalExpenses = expenseRows.fold(0.0, (sum, e) => sum + e.amount);

    return IncomeStatement(
      revenue: revenueRows,
      expenses: expenseRows,
      totalRevenue: totalRevenue,
      totalExpenses: totalExpenses,
      netIncome: totalRevenue - totalExpenses,
      startDate: startDate,
      endDate: endDate,
    );
  }

  @override
  Future<List<LedgerEntry>> getAccountLedger(
    String accountCode, {
    String? startDate,
    String? endDate,
  }) async {
    final accountId = await getAccountIdByCode(accountCode);
    if (accountId == null) throw Exception('الحساب غير موجود: $accountCode');

    String dateFilter = '';
    if (startDate != null) dateFilter += " AND je.entry_date >= '${startDate}T00:00:00'";
    if (endDate != null) dateFilter += " AND je.entry_date <= '${endDate}T23:59:59'";

    final results = await _db.customSelect(
      '''
      SELECT 
        jel.id,
        je.entry_date,
        je.entry_number,
        COALESCE(jel.description, je.description, '') as description,
        jel.debit_amount,
        jel.credit_amount
      FROM journal_entry_lines jel
      INNER JOIN journal_entries je ON je.id = jel.journal_entry_id
      WHERE jel.account_id = $accountId
        AND je.is_posted = 1
        $dateFilter
      ORDER BY je.entry_date ASC, je.id ASC
      ''',
    ).get();

    double runningBalance = 0;
    return results.map((r) {
      final debit = r.read<double>('debit_amount');
      final credit = r.read<double>('credit_amount');
      runningBalance += debit - credit;
      return LedgerEntry(
        id: r.read<int>('id'),
        entryDate: DateTime.fromMillisecondsSinceEpoch(r.read<int>('entry_date') * 1000),
        entryNumber: r.read<String>('entry_number'),
        description: r.read<String>('description'),
        debit: debit,
        credit: credit,
        balance: runningBalance,
      );
    }).toList();
  }

  // ============ CREDIT NOTES ============

  @override
  Future<List<CreditNote>> getCreditNotes({int page = 1, int pageSize = 20}) async {
    final rows = await (_db.select(_db.creditNotes)
          ..orderBy([(t) => OrderingTerm.desc(t.creditNoteDate)])
          ..limit(pageSize, offset: (page - 1) * pageSize))
        .get();
    return rows.map(_mapCreditNoteToEntity).toList();
  }

  @override
  Future<CreditNote?> getCreditNoteById(int id) async {
    final row = await (_db.select(_db.creditNotes)..where((t) => t.id.equals(id))).getSingleOrNull();
    return row != null ? _mapCreditNoteToEntity(row) : null;
  }

  @override
  Future<CreditNote> createCreditNote({
    required String originalInvoiceType,
    required int originalInvoiceId,
    required double amount,
    required int userId,
    String? reason,
    int? branchId,
  }) async {
    final count = await _db.creditNotes.count().getSingle();
    final number = 'CN-${(count + 1).toString().padLeft(6, '0')}';

    final id = await _db.into(_db.creditNotes).insert(
      db.CreditNotesCompanion.insert(
        creditNoteNumber: number,
        creditNoteDate: DateTime.now(),
        originalInvoiceType: originalInvoiceType,
        originalInvoiceId: originalInvoiceId,
        amount: amount,
        reason: Value(reason),
        branchId: Value(branchId),
        createdById: userId,
      ),
    );

    return (await getCreditNoteById(id))!;
  }

  @override
  Future<CreditNote?> submitCreditNote(int id, int userId) async {
    return _db.transaction(() async {
      final cn = await getCreditNoteById(id);
      if (cn == null) throw Exception('الإشعار الدائن غير موجود');
      if (!cn.isDraft) throw Exception('الإشعار مُعتمد بالفعل');

      // Create GL entry based on type
      if (cn.originalInvoiceType == 'sale') {
        await _createAutoJournalEntry(
          description: 'إشعار دائن: ${cn.creditNoteNumber}',
          sourceType: 'credit_note',
          sourceId: cn.id!,
          userId: userId,
          branchId: cn.branchId,
          lines: [
            JournalLineInput(accountCode: AccountCodes.discountsGiven, debitAmount: cn.amount, description: 'إشعار دائن'),
            JournalLineInput(accountCode: AccountCodes.accountsReceivable, creditAmount: cn.amount, description: 'تخفيض ذمة مدينة'),
          ],
        );
      } else {
        await _createAutoJournalEntry(
          description: 'إشعار دائن شراء: ${cn.creditNoteNumber}',
          sourceType: 'credit_note',
          sourceId: cn.id!,
          userId: userId,
          branchId: cn.branchId,
          lines: [
            JournalLineInput(accountCode: AccountCodes.accountsPayable, debitAmount: cn.amount, description: 'إشعار دائن'),
            JournalLineInput(accountCode: AccountCodes.otherIncome, creditAmount: cn.amount, description: 'إيراد إشعار شراء'),
          ],
        );
      }

      // Update status
      await (_db.update(_db.creditNotes)..where((t) => t.id.equals(id))).write(
        db.CreditNotesCompanion(
          docstatus: const Value(1),
          submittedAt: Value(DateTime.now()),
          submittedById: Value(userId),
        ),
      );

      return getCreditNoteById(id);
    });
  }

  // ============ SYSTEM SETTINGS ============

  @override
  Future<String?> getSystemSetting(String key) async {
    final row = await (_db.select(_db.systemSettings)..where((t) => t.key.equals(key))).getSingleOrNull();
    return row?.value;
  }

  @override
  Future<void> setSystemSetting(String key, String value) async {
    final existing = await (_db.select(_db.systemSettings)..where((t) => t.key.equals(key))).getSingleOrNull();
    if (existing != null) {
      await (_db.update(_db.systemSettings)..where((t) => t.key.equals(key))).write(
        db.SystemSettingsCompanion(value: Value(value), updatedAt: Value(DateTime.now())),
      );
    } else {
      await _db.into(_db.systemSettings).insert(
        db.SystemSettingsCompanion.insert(key: key, value: value),
      );
    }
  }

  // ============ MAPPERS ============

  Account _mapAccountToEntity(db.AccountTable row) {
    return Account(
      id: row.id,
      code: row.code,
      name: row.name,
      nameEn: row.nameEn,
      accountType: row.accountType,
      rootType: row.rootType,
      reportType: row.reportType,
      parentId: row.parentId,
      isGroup: row.isGroup,
      isActive: row.isActive,
      lft: row.lft,
      rgt: row.rgt,
      balanceMustBe: row.balanceMustBe,
      accountCurrency: row.accountCurrency,
      freezeAccount: row.freezeAccount,
      companyId: row.companyId,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }

  JournalEntry _mapJournalEntryToEntity(db.JournalEntryTable row, List<JournalEntryLine> lines) {
    return JournalEntry(
      id: row.id,
      entryNumber: row.entryNumber,
      entryDate: row.entryDate,
      description: row.description,
      sourceType: row.sourceType,
      sourceId: row.sourceId,
      branchId: row.branchId,
      isPosted: row.isPosted,
      isReversed: row.isReversed,
      reversedByEntryId: row.reversedByEntryId,
      createdById: row.createdById,
      lines: lines,
      createdAt: row.createdAt,
    );
  }

  CreditNote _mapCreditNoteToEntity(db.CreditNoteTable row) {
    return CreditNote(
      id: row.id,
      creditNoteNumber: row.creditNoteNumber,
      creditNoteDate: row.creditNoteDate,
      docstatus: row.docstatus,
      originalInvoiceType: row.originalInvoiceType,
      originalInvoiceId: row.originalInvoiceId,
      amount: row.amount,
      reason: row.reason,
      branchId: row.branchId,
      submittedAt: row.submittedAt,
      submittedById: row.submittedById,
      createdById: row.createdById,
      createdAt: row.createdAt,
    );
  }
}
