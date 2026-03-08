import 'package:poultry_accounting/backend/domain/entities/salary.dart';

abstract class SalaryRepository {
  Future<List<Salary>> getAllSalaries({
    DateTime? fromDate,
    DateTime? toDate,
    String? employeeName,
  });
  
  Stream<List<Salary>> watchAllSalaries({
    DateTime? fromDate,
    DateTime? toDate,
    String? employeeName,
  });
  
  Future<Salary?> getSalaryById(int id);
  Future<int> createSalary(Salary salary);
  Future<void> updateSalary(Salary salary);
  Future<void> deleteSalary(int id);
  
  Future<double> getTotalSalaries({
    DateTime? fromDate,
    DateTime? toDate,
  });
}
