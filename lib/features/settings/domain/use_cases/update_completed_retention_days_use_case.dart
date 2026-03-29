import 'package:nexus/features/settings/domain/repositories/settings_repository_interface.dart';

/// How long completed tasks stay visible.

class UpdateCompletedRetentionDaysUseCase {
  UpdateCompletedRetentionDaysUseCase(this._repo);
  final SettingsRepositoryInterface _repo;

  Future<void> call(int days) => _repo.saveCompletedRetentionDays(days);
}
