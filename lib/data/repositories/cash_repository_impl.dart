import 'package:drift/drift.dart';
import 'package:poultry_accounting/data/database/database.dart' as db;
import 'package:poultry_accounting/domain/entities/cash_transaction.dart';
import 'package:poultry_accounting/domain/repositories/i_cash_repository.dart';

class CashRepositoryImpl implements ICashRepository {
  CashRepositoryImpl(this.database);
  final db.AppDatabase database;

  @override
  Future<List<CashTransaction>> getAllTransactions({DateTime? start, DateTime? end}) async {
    final query = _buildTransactionsQuery(start, end);
    final results = await query.get();
    return results.map(_mapToEntity).toList();
  }

  @override
  Stream<List<CashTransaction>> watchAllTransactions({DateTime? start, DateTime? end}) {
    final query = _buildTransactionsQuery(start, end);
    return query.watch().map((rows) => rows.map(_mapToEntity).toList());
  }

  SimpleSelectStatement<db.CashTransactions, db.CashTransactionTable> _buildTransactionsQuery(DateTime? start, DateTime? end) {
    final query = database.select(database.cashTransactions);
    if (start != null && end != null) {
      query.where((t) => t.transactionDate.isBetweenValues(start, end));
    }
    query.orderBy([(t) => OrderingTerm(expression: t.transactionDate, mode: OrderingMode.desc)]);
    return query;
  }

  @override
  Future<double> getBalance() async {
    final queryIn = database.selectOnly(database.cashTransactions);
    queryIn.addColumns([database.cashTransactions.amount.sum()]);
    queryIn.where(database.cashTransactions.type.equals('in'));
    final rowIn = await queryIn.getSingle();
    final totalIn = rowIn.read(database.cashTransactions.amount.sum()) ?? 0.0;

    final queryOut = database.selectOnly(database.cashTransactions);
    queryOut.addColumns([database.cashTransactions.amount.sum()]);
    queryOut.where(database.cashTransactions.type.equals('out'));
    final rowOut = await queryOut.getSingle();
    final totalOut = rowOut.read(database.cashTransactions.amount.sum()) ?? 0.0;

    return totalIn - totalOut;
  }

  @override
  Future<int> createTransaction(CashTransaction transaction) async {
    return database.into(database.cashTransactions).insert(
      db.CashTransactionsCompanion.insert(
        amount: transaction.amount,
        type: transaction.type,
        description: transaction.description,
        transactionDate: transaction.transactionDate,
        relatedPaymentId: Value(transaction.relatedPaymentId),
        relatedExpenseId: Value(transaction.relatedExpenseId),
        createdBy: transaction.createdBy,
      ),
    );
  }

  @override
  Future<void> deleteTransaction(int id) async {
    await (database.delete(database.cashTransactions)..where((t) => t.id.equals(id))).go();
  }

  CashTransaction _mapToEntity(db.CashTransactionTable row) {
    return CashTransaction(
      id: row.id,
      amount: row.amount,
      type: row.type,
      description: row.description,
      transactionDate: row.transactionDate,
      relatedPaymentId: row.relatedPaymentId,
      relatedExpenseId: row.relatedExpenseId,
      createdBy: row.createdBy,
      createdAt: row.createdAt,
    );
  }
}
