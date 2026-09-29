import '../../domain/entities/manager_item.dart';
import '../../domain/entities/manager_pagination.dart';
import '../../domain/repositories/manager_repository.dart';
import '../datasources/manager_remote_data_source.dart';

/// FastAPI-backed repository for Managers. Thin pass-through — all parsing
/// and error typing lives in the remote data source.
class ManagerRepositoryImpl implements ManagerRepository {
  final ManagerRemoteDataSource remoteDataSource;

  ManagerRepositoryImpl({required this.remoteDataSource});

  @override
  Future<({List<ManagerItem> items, ManagerPagination pagination})>
      getManagers({
    required String accessToken,
    int page = 1,
    int pageSize = 20,
    String? search,
    String? status,
    String? sort,
    String? order,
  }) {
    return remoteDataSource.getManagers(
      accessToken: accessToken,
      page: page,
      pageSize: pageSize,
      search: search,
      status: status,
      sort: sort,
      order: order,
    );
  }

  @override
  Future<ManagerItem> createManager({
    required String accessToken,
    required String name,
    required String phone,
    required String password,
    String? email,
    String? assignedRegion,
    String? department,
  }) {
    return remoteDataSource.createManager(
      accessToken: accessToken,
      name: name,
      phone: phone,
      password: password,
      email: email,
      assignedRegion: assignedRegion,
      department: department,
    );
  }

  @override
  Future<ManagerItem> updateManagerStatus({
    required String accessToken,
    required String managerId,
    required String status,
  }) {
    return remoteDataSource.updateManagerStatus(
      accessToken: accessToken,
      managerId: managerId,
      status: status,
    );
  }

  @override
  Future<String> resetManagerPassword({
    required String accessToken,
    required String managerId,
    required String newPassword,
  }) {
    return remoteDataSource.resetManagerPassword(
      accessToken: accessToken,
      managerId: managerId,
      newPassword: newPassword,
    );
  }
}
