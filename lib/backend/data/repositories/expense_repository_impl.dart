import 'package:drift/drift.dart';
import 'package:poultry_accounting/backend/data/database/database.dart' as db;
import 'package:poultry_accounting/backend/domain/entities/expense.dart';
import 'package:poultry_accounting/backend/domain/repositories/expense_repository.dart';
import 'package:poultry_accounting/backend/data/repositories/accounting_repository_impl.dart';

class ExpenseRepositoryImpl implements ExpenseRepository {
  ExpenseRepositoryImpl(this.database);
  final db.AppDatabase database;

  // Expense Categories
  @override
  Future<List<ExpenseCategory>> getAllCategories() async {
    final rows = await database.select(database.expenseCategories).get();
    return rows.map(_mapCategoryToEntity).toList();
  }

  @override
  Stream<List<ExpenseCategory>> watchAllCategories() {
    return database
        .select(database.expenseCategories)
        .watch()
        .map((rows) => rows.map(_mapCategoryToEntity).toList());
  }

  @override
  Future<int> createCategory(ExpenseCategory category) {
    return database.into(database.expenseCategories).insert(
          db.ExpenseCategoriesCompanion.insert(
            name: category.name,
            description: Value(category.description),
            isActive: Value(category.isActive),
          ),
        );
  }

  @override
  Future<void> updateCategory(ExpenseCategory category) {
    return (database.update(database.expenseCategories)
          ..where((t) => t.id.equals(category.id!)))
        .write(
      db.ExpenseCategoriesCompanion(
        name: Value(category.name),
        description: Value(category.description),
        isActive: Value(category.isActive),
      ),
    );
  }

  @override
  Future<void> deleteCategory(int id) {
    return (database.delete(database.expenseCategories)
          ..where((t) => t.id.equals(id)))
        .go();
  }

  // Expenses
  @override
  Future<List<Expense>> getAllExpenses({
    int? categoryId,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    final query = database.select(database.expenses).join([
      innerJoin(
        database.expenseCategories,
        database.expenseCategories.id.equalsExp(database.expenses.categoryId),
      ),
    ]);

    if (categoryId != null) {
      query.where(database.expenses.categoryId.equals(categoryId));
    }
    if (fromDate != null) {
      query.where(database.expenses.expenseDate.isBiggerOrEqualValue(fromDate));
    }
    if (toDate != null) {
      query.where(database.expenses.expenseDate.isSmallerOrEqualValue(toDate));
    }

    final rows = await query.get();
    return rows.map(_mapExpenseToEntity).toList();
  }

  @override
  Stream<List<Expense>> watchAllExpenses({
    int? categoryId,
    DateTime? fromDate,
    DateTime? toDate,
  }) {
    final query = database.select(database.expenses).join([
      innerJoin(
        database.expenseCategories,
        database.expenseCategories.id.equalsExp(database.expenses.categoryId),
      ),
    ]);

    if (categoryId != null) {
      query.where(database.expenses.categoryId.equals(categoryId));
    }
    
    // Note: complex date filtering in watch queries with Drift join requires careful handling.
    // Simplifying for now to watch all and filter if needed, or just watch basic expenses.
    
    return query.watch().map((rows) => rows.map(_mapExpenseToEntity).toList());
  }

  @override
  Future<Expense?> getExpenseById(int id) async {
    final query = database.select(database.expenses).join([
      innerJoin(
        database.expenseCategories,
        database.expenseCategories.id.equalsExp(database.expenses.categoryId),
      ),
    ]);
    query.where(database.expenses.id.equals(id));
    
    final row = await query.getSingleOrNull();
    return row != null ? _mapExpenseToEntity(row) : null;
  }

  @override
  Future<int> createExpense(Expense expense) {
    return database.transaction(() async {
      // 1. Insert expense
      final id = await database.into(database.expenses).insert(
            db.ExpensesCompanion.insert(
              categoryId: expense.categoryId,
              amount: expense.amount,
              expenseDate: expense.expenseDate,
              description: expense.description,
              notes: Value(expense.notes),
              createdBy: expense.createdBy ?? 1,
            ),
          );

      // 2. Create cash transaction
      await database.into(database.cashTransactions).insert(
            db.CashTransactionsCompanion.insert(
              amount: expense.amount,
              type: 'out',
              description: 'ظ…طµط±ظˆظپ: ${expense.description}',
              transactionDate: expense.expenseDate,
              relatedExpenseId: Value(id),
              createdBy: expense.createdBy ?? 1,
            ),
          );

      // --- ACCOUNTING INTEGRATION ---
      final accountingRepo = AccountingRepositoryImpl(database);
      await accountingRepo.createExpenseJournalEntry(
        expenseId: id,
        expenseNumber: 'EXP-$id', // Generates a standard readable reference
        userId: expense.createdBy ?? 1,
        amount: expense.amount,
        paymentMethod: 'cash', // Expenses are currently cash-based by default
      );

      return id;
    });
  }

  @override
  Future<void> updateExpense(Expense expense) {
    return database.transaction(() async {
      await (database.update(database.expenses)
            ..where((t) => t.id.equals(expense.id!)))
          .write(
        db.ExpensesCompanion(
          categoryId: Value(expense.categoryId),
          amount: Value(expense.amount),
          expenseDate: Value(expense.expenseDate),
          description: Value(expense.description),
          notes: Value(expense.notes),
        ),
      );

      // Update associated cash transaction
      await (database.update(database.cashTransactions)
            ..where((t) => t.relatedExpenseId.equals(expense.id!)))
          .write(
        db.CashTransactionsCompanion(
          amount: Value(expense.amount),
          description: Value('ظ…طµط±ظˆظپ: ${expense.description}'),
          transactionDate: Value(expense.expenseDate),
        ),
      );
    });
  }

  @override
  Future<void> deleteExpense(int id) {
    return database.transaction(() async {
      // 1. Delete associated cash transaction
      await (database.delete(database.cashTransactions)
            ..where((t) => t.relatedExpenseId.equals(id)))
          .go();

      // 2. Delete expense
      await (database.delete(database.expenses)
            ..where((t) => t.id.equals(id)))
          .go();
    });
  }

  @override
  Future<double> getTotalExpenses({DateTime? fromDate, DateTime? toDate}) async {
    final amountExp = database.expenses.amount.sum();
    final query = database.selectOnly(database.expenses)..addColumns([amountExp]);
    
    if (fromDate != null) {
      query.where(database.expenses.expenseDate.isBiggerOrEqualValue(fromDate));
    }
    if (toDate != null) {
      query.where(database.expenses.expenseDate.isSmallerOrEqualValue(toDate));
    }

    final row = await query.getSingle();
    return row.read(amountExp) ?? 0.0;
  }

  // Mappers
  ExpenseCategory _mapCategoryToEntity(db.ExpenseCategoryTable row) {
    return ExpenseCategory(
      id: row.id,
      name: row.name,
      description: row.description,
      isActive: row.isActive,
    );
  }

  Expense _mapExpenseToEntity(TypedResult result) {
    final expense = result.readTable(database.expenses);
    final category = result.readTable(database.expenseCategories);
    
    return Expense(
      id: expense.id,
      categoryId: expense.categoryId,
      amount: expense.amount,
      expenseDate: expense.expenseDate,
      description: expense.description,
      notes: expense.notes,
      createdBy: expense.createdBy,
      categoryName: category.name,
    );
  }
}
