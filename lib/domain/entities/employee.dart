import 'package:equatable/equatable.dart';

class Employee extends Equatable {
  final int? id;
  final String name;
  final String? phone;
  final double monthlySalary;
  final DateTime hireDate;
  final bool isActive;

  const Employee({
    this.id,
    required this.name,
    this.phone,
    this.monthlySalary = 0.0,
    required this.hireDate,
    this.isActive = true,
  });

  @override
  List<Object?> get props => [id, name, phone, monthlySalary, hireDate, isActive];
}
