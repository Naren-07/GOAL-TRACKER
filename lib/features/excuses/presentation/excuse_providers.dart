import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/mock_excuse_repository.dart';
import '../domain/excuse_repository.dart';

final excuseRepositoryProvider = Provider<ExcuseRepository>((ref) {
  return MockExcuseRepository();
});
