import 'package:poultry_accounting/domain/entities/employee.dart';

abstract class EmployeeRepository {
  Future<List<Employee>> getAllEmployees();
  Stream<List<Employee>> watchAllEmployees();
  Future<Employee?> getEmployeeById(int id);
  Future<int> createEmployee(Employee employee);
  Future<void> updateEmployee(Employee employee);
  Future<void> deleteEmployee(int id); // Soft delete usually
}
