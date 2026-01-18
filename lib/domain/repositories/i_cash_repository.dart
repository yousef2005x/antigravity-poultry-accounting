import 'package:poultry_accounting/domain/entities/cash_transaction.dart';

abstract class ICashRepository {
  Future<List<CashTransaction>> getAllTransactions({DateTime? start, DateTime? end});
  Stream<List<CashTransaction>> watchAllTransactions({DateTime? start, DateTime? end});
  Future<double> getBalance();
  Future<int> createTransaction(CashTransaction transaction);
  Future<void> deleteTransaction(int id);
}
