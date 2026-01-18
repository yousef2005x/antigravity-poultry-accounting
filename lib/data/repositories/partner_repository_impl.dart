import 'package:drift/drift.dart';
import 'package:poultry_accounting/data/database/database.dart' as db;
import 'package:poultry_accounting/domain/entities/partner.dart';
import 'package:poultry_accounting/domain/entities/partner_transaction.dart';
import 'package:poultry_accounting/domain/repositories/i_partner_repository.dart';

class PartnerRepositoryImpl implements IPartnerRepository {

  PartnerRepositoryImpl(this.database);
  final db.AppDatabase database;

  @override
  Future<List<Partner>> getAllPartners() async {
    final results = await database.select(database.partners).get();
    return results.map(_mapToPartnerEntity).toList();
  }

  @override
  Future<Partner?> getPartnerById(int id) async {
    final query = database.select(database.partners)..where((t) => t.id.equals(id));
    final result = await query.getSingleOrNull();
    return result != null ? _mapToPartnerEntity(result) : null;
  }

  @override
  Future<int> createPartner(Partner partner) async {
    return database.into(database.partners).insert(
          db.PartnersCompanion.insert(
            name: partner.name,
            sharePercentage: Value(partner.sharePercentage),
            isActive: Value(partner.isActive),
          ),
        );
  }

  @override
  Future<void> updatePartner(Partner partner) async {
    await (database.update(database.partners)..where((t) => t.id.equals(partner.id!))).write(
          db.PartnersCompanion(
            name: Value(partner.name),
            sharePercentage: Value(partner.sharePercentage),
            isActive: Value(partner.isActive),
          ),
        );
  }

  @override
  Future<List<PartnerTransaction>> getPartnerTransactions(int partnerId) async {
    final query = database.select(database.partnerTransactions)..where((t) => t.partnerId.equals(partnerId));
    final results = await query.get();
    return results.map(_mapToTransactionEntity).toList();
  }

  @override
  Future<int> createPartnerTransaction(PartnerTransaction transaction) async {
    return database.into(database.partnerTransactions).insert(
          db.PartnerTransactionsCompanion.insert(
            partnerId: transaction.partnerId,
            amount: transaction.amount,
            type: transaction.type,
            transactionDate: transaction.transactionDate,
            notes: Value(transaction.notes),
            createdBy: transaction.createdBy,
          ),
        );
  }

  @override
  Future<void> deletePartnerTransaction(int id) async {
    await (database.delete(database.partnerTransactions)..where((t) => t.id.equals(id))).go();
  }

  Partner _mapToPartnerEntity(db.PartnerTable row) {
    return Partner(
      id: row.id,
      name: row.name,
      sharePercentage: row.sharePercentage,
      isActive: row.isActive,
      createdAt: row.createdAt,
    );
  }

  PartnerTransaction _mapToTransactionEntity(db.PartnerTransactionTable row) {
    return PartnerTransaction(
      id: row.id,
      partnerId: row.partnerId,
      amount: row.amount,
      type: row.type,
      transactionDate: row.transactionDate,
      notes: row.notes,
      createdBy: row.createdBy,
      createdAt: row.createdAt,
    );
  }
}
