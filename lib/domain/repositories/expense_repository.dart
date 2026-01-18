import 'package:poultry_accounting/domain/entities/expense.dart';

abstract class ExpenseRepository {
  // Expense Categories
  Future<List<ExpenseCategory>> getAllCategories();
  Stream<List<ExpenseCategory>> watchAllCategories();
  Future<int> createCategory(ExpenseCategory category);
  Future<void> updateCategory(ExpenseCategory category);
  Future<void> deleteCategory(int id);

  // Expenses
  Future<List<Expense>> getAllExpenses({
    int? categoryId,
    DateTime? fromDate,
    DateTime? toDate,
  });
  Stream<List<Expense>> watchAllExpenses({
    int? categoryId,
    DateTime? fromDate,
    DateTime? toDate,
  });
  Future<Expense?> getExpenseById(int id);
  Future<int> createExpense(Expense expense);
  Future<void> updateExpense(Expense expense);
  Future<void> deleteExpense(int id);
  
  Future<double> getTotalExpenses({
    DateTime? fromDate,
    DateTime? toDate,
  });
}
