import 'package:poultry_accounting/domain/entities/processing_output.dart';
import 'package:poultry_accounting/domain/entities/raw_meat_processing.dart';

abstract class IProcessingRepository {
  Future<List<RawMeatProcessing>> getAllProcessings();
  Future<RawMeatProcessing?> getProcessingById(int id);
  Future<int> createProcessing(RawMeatProcessing processing, List<ProcessingOutput> outputs);
  Future<void> updateProcessing(RawMeatProcessing processing, List<ProcessingOutput> outputs);
  Future<void> deleteProcessing(int id);
  Future<List<ProcessingOutput>> getOutputsByProcessingId(int processingId);
}
