import 'package:equatable/equatable.dart';

class ExpenseCategory extends Equatable {
  const ExpenseCategory({
    required this.name,
    this.id,
    this.description,
    this.isActive = true,
  });

  final int? id;
  final String name;
  final String? description;
  final bool isActive;

  @override
  List<Object?> get props => [id, name, description, isActive];

  ExpenseCategory copyWith({
    int? id,
    String? name,
    String? description,
    bool? isActive,
  }) {
    return ExpenseCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
    );
  }
}

class Expense extends Equatable {
  const Expense({
    required this.categoryId,
    required this.amount,
    required this.expenseDate,
    required this.description,
    this.id,
    this.notes,
    this.createdBy,
    this.categoryName,
  });

  final int? id;
  final int categoryId;
  final double amount;
  final DateTime expenseDate;
  final String description;
  final String? notes;
  final int? createdBy;
  final String? categoryName; // Helper field for display

  @override
  List<Object?> get props => [
        id,
        categoryId,
        amount,
        expenseDate,
        description,
        notes,
        createdBy,
        categoryName,
      ];

  Expense copyWith({
    int? id,
    int? categoryId,
    double? amount,
    DateTime? expenseDate,
    String? description,
    String? notes,
    int? createdBy,
    String? categoryName,
  }) {
    return Expense(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      amount: amount ?? this.amount,
      expenseDate: expenseDate ?? this.expenseDate,
      description: description ?? this.description,
      notes: notes ?? this.notes,
      createdBy: createdBy ?? this.createdBy,
      categoryName: categoryName ?? this.categoryName,
    );
  }
}
