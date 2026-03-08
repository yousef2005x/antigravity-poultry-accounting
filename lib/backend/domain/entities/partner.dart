import 'package:equatable/equatable.dart';

class Partner extends Equatable {

  const Partner({
    required this.name, this.id,
    this.sharePercentage = 50.0,
    this.isActive = true,
    this.createdAt,
  });
  final int? id;
  final String name;
  final double sharePercentage;
  final bool isActive;
  final DateTime? createdAt;

  @override
  List<Object?> get props => [id, name, sharePercentage, isActive, createdAt];

  Partner copyWith({
    int? id,
    String? name,
    double? sharePercentage,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return Partner(
      id: id ?? this.id,
      name: name ?? this.name,
      sharePercentage: sharePercentage ?? this.sharePercentage,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
