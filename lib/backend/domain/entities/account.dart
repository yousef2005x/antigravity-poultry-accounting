import 'package:meta/meta.dart';

/// Account domain entity (Chart of Accounts)
@immutable
class Account {
  const Account({
    this.id,
    required this.code,
    required this.name,
    this.nameEn,
    required this.accountType,
    this.rootType,
    this.reportType,
    this.parentId,
    this.isGroup = false,
    this.isActive = true,
    this.lft = 0,
    this.rgt = 0,
    this.balanceMustBe,
    this.accountCurrency,
    this.freezeAccount = false,
    this.companyId,
    this.children = const [],
    this.createdAt,
    this.updatedAt,
  });

  final int? id;
  final String code;
  final String name;
  final String? nameEn;
  final String accountType; // asset, liability, equity, revenue, expense
  final String? rootType; // Asset, Liability, Equity, Income, Expense
  final String? reportType; // Balance Sheet, Profit and Loss
  final int? parentId;
  final bool isGroup;
  final bool isActive;
  final int lft;
  final int rgt;
  final String? balanceMustBe; // Debit, Credit, or null
  final String? accountCurrency;
  final bool freezeAccount;
  final int? companyId;
  final List<Account> children;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// Whether this account can be posted to (not a group)
  bool get isPostable => !isGroup;

  Account copyWith({
    int? id,
    String? code,
    String? name,
    String? nameEn,
    String? accountType,
    String? rootType,
    String? reportType,
    int? parentId,
    bool? isGroup,
    bool? isActive,
    int? lft,
    int? rgt,
    String? balanceMustBe,
    String? accountCurrency,
    bool? freezeAccount,
    int? companyId,
    List<Account>? children,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Account(
      id: id ?? this.id,
      code: code ?? this.code,
      name: name ?? this.name,
      nameEn: nameEn ?? this.nameEn,
      accountType: accountType ?? this.accountType,
      rootType: rootType ?? this.rootType,
      reportType: reportType ?? this.reportType,
      parentId: parentId ?? this.parentId,
      isGroup: isGroup ?? this.isGroup,
      isActive: isActive ?? this.isActive,
      lft: lft ?? this.lft,
      rgt: rgt ?? this.rgt,
      balanceMustBe: balanceMustBe ?? this.balanceMustBe,
      accountCurrency: accountCurrency ?? this.accountCurrency,
      freezeAccount: freezeAccount ?? this.freezeAccount,
      companyId: companyId ?? this.companyId,
      children: children ?? this.children,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() => 'Account(id: $id, code: $code, name: $name)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Account && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
