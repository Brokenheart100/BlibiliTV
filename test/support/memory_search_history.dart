import 'package:mambatv/core/result.dart';
import 'package:mambatv/domain/repositories/repositories.dart';

class MemorySearchHistoryRepository implements SearchHistoryRepository {
  final entries = <String, List<String>>{};
  @override
  Future<Result<List<String>>> load(String ownerKey) async =>
      Success(List.of(entries[ownerKey] ?? []));
  @override
  Future<Result<void>> remember(String ownerKey, String query) async {
    entries[ownerKey] = [
      query.trim(),
      ...(entries[ownerKey] ?? []).where((v) => v != query.trim()),
    ].take(12).toList();
    return const Success(null);
  }

  @override
  Future<Result<void>> clear(String ownerKey) async {
    entries.remove(ownerKey);
    return const Success(null);
  }
}
