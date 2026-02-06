import 'package:drift/drift.dart';
import 'package:poultry_accounting/data/database/database.dart' as db;
import 'package:poultry_accounting/domain/entities/salary.dart';
import 'package:poultry_accounting/domain/repositories/salary_repository.dart';

class SalaryRepositoryImpl implements SalaryRepository {
  SalaryRepositoryImpl(this.database);
  final db.AppDatabase database;

  @override
  Future<List<Salary>> getAllSalaries({
    DateTime? fromDate,
    DateTime? toDate,
    String? employeeName,
  }) async {
    final query = database.select(database.salaries);

    if (employeeName != null && employeeName.isNotEmpty) {
      query.where((t) => t.employeeName.contains(employeeName));
    }
    if (fromDate != null) {
      query.where((t) => t.salaryDate.isBiggerOrEqualValue(fromDate));
    }
    if (toDate != null) {
      query.where((t) => t.salaryDate.isSmallerOrEqualValue(toDate));
    }

    query.orderBy([(t) => OrderingTerm.desc(t.salaryDate)]);

    final rows = await query.get();
    return rows.map(_mapToEntity).toList();
  }

  @override
  Stream<List<Salary>> watchAllSalaries({
    DateTime? fromDate,
    DateTime? toDate,
    String? employeeName,
  }) {
    final query = database.select(database.salaries);

    if (employeeName != null && employeeName.isNotEmpty) {
      query.where((t) => t.employeeName.contains(employeeName));
    }
    
    // Simplification for watch: typically we watch all or filter by basic criteria
    return query
        .watch()
        .map((rows) => rows.map(_mapToEntity).toList());
  }

  @override
  Future<Salary?> getSalaryById(int id) async {
    final query = database.select(database.salaries)..where((t) => t.id.equals(id));
    final row = await query.getSingleOrNull();
    return row != null ? _mapToEntity(row) : null;
  }

  @override
  Future<int> createSalary(Salary salary) {
    return database.into(database.salaries).insert(
          db.SalariesCompanion.insert(
            amount: salary.amount,
            salaryDate: salary.salaryDate,
            employeeName: salary.employeeName,
            employeeId: Value(salary.employeeId),
            notes: Value(salary.notes),
            createdBy: salary.createdBy ?? 1,
          ),
        );
  }

  @override
  Future<void> updateSalary(Salary salary) {
    return (database.update(database.salaries)..where((t) => t.id.equals(salary.id!)))
        .write(
      db.SalariesCompanion(
        amount: Value(salary.amount),
        salaryDate: Value(salary.salaryDate),
        employeeName: Value(salary.employeeName),
        employeeId: Value(salary.employeeId),
        notes: Value(salary.notes),
      ),
    );
  }

  @override
  Future<void> deleteSalary(int id) {
    return (database.delete(database.salaries)..where((t) => t.id.equals(id))).go();
  }

  @override
  Future<double> getTotalSalaries({DateTime? fromDate, DateTime? toDate}) async {
    final amountExp = database.salaries.amount.sum();
    final query = database.selectOnly(database.salaries)..addColumns([amountExp]);

    if (fromDate != null) {
      query.where(database.salaries.salaryDate.isBiggerOrEqualValue(fromDate));
    }
    if (toDate != null) {
      query.where(database.salaries.salaryDate.isSmallerOrEqualValue(toDate));
    }

    final row = await query.getSingle();
    return row.read(amountExp) ?? 0.0;
  }

  Salary _mapToEntity(db.SalaryTable row) {
    return Salary(
      id: row.id,
      amount: row.amount,
      salaryDate: row.salaryDate,
      employeeName: row.employeeName,
      employeeId: row.employeeId,
      notes: row.notes,
      createdBy: row.createdBy,
    );
  }
}
