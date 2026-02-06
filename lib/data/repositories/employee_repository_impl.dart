import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poultry_accounting/core/providers/database_providers.dart';
import 'package:poultry_accounting/data/database/database.dart';
import 'package:poultry_accounting/domain/entities/employee.dart';
import 'package:poultry_accounting/domain/repositories/employee_repository.dart';

class EmployeeRepositoryImpl implements EmployeeRepository {
  final AppDatabase _db;

  EmployeeRepositoryImpl(this._db);

  @override
  Future<List<Employee>> getAllEmployees() async {
    final query = _db.select(_db.employees)
      ..where((t) => t.isActive.equals(true));
    final result = await query.get();
    return result.map(_mapToEntity).toList();
  }

  @override
  Stream<List<Employee>> watchAllEmployees() {
    final query = _db.select(_db.employees)
      ..where((t) => t.isActive.equals(true));
    return query.watch().map((rows) => rows.map(_mapToEntity).toList());
  }

  @override
  Future<Employee?> getEmployeeById(int id) async {
    final result = await (_db.select(_db.employees)..where((t) => t.id.equals(id))).getSingleOrNull();
    return result != null ? _mapToEntity(result) : null;
  }

  @override
  Future<int> createEmployee(Employee employee) async {
    return _db.into(_db.employees).insert(
          EmployeesCompanion(
            name: Value(employee.name),
            phone: Value(employee.phone),
            monthlySalary: Value(employee.monthlySalary),
            hireDate: Value(employee.hireDate),
            isActive: const Value(true),
          ),
        );
  }

  @override
  Future<void> updateEmployee(Employee employee) async {
    await (_db.update(_db.employees)..where((t) => t.id.equals(employee.id!))).write(
      EmployeesCompanion(
        name: Value(employee.name),
        phone: Value(employee.phone),
        monthlySalary: Value(employee.monthlySalary),
        hireDate: Value(employee.hireDate),
      ),
    );
  }

  @override
  Future<void> deleteEmployee(int id) async {
    await (_db.update(_db.employees)..where((t) => t.id.equals(id))).write(
      const EmployeesCompanion(isActive: Value(false)),
    );
  }

  Employee _mapToEntity(EmployeeTable data) {
    return Employee(
      id: data.id,
      name: data.name,
      phone: data.phone,
      monthlySalary: data.monthlySalary,
      hireDate: data.hireDate,
      isActive: data.isActive,
    );
  }
}

final employeeRepositoryProvider = Provider<EmployeeRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return EmployeeRepositoryImpl(db);
});

final employeesStreamProvider = StreamProvider<List<Employee>>((ref) {
  final repo = ref.watch(employeeRepositoryProvider);
  return repo.watchAllEmployees();
});
