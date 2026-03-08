import 'package:poultry_accounting/backend/domain/entities/partner.dart';
import 'package:poultry_accounting/backend/domain/entities/partner_transaction.dart';

abstract class IPartnerRepository {
  Future<List<Partner>> getAllPartners();
  Future<Partner?> getPartnerById(int id);
  Future<int> createPartner(Partner partner);
  Future<void> updatePartner(Partner partner);
  
  Future<List<PartnerTransaction>> getPartnerTransactions(int partnerId);
  Future<int> createPartnerTransaction(PartnerTransaction transaction);
  Future<void> deletePartnerTransaction(int id);
}
