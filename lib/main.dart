import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app.dart';
import 'features/auth/data/datasources/auth_local_data_source.dart';
import 'features/auth/data/datasources/auth_remote_data_source.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/presentation/controllers/auth_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final localDataSource = SharedPreferencesAuthLocalDataSource(prefs);
  final remoteDataSource = FastApiAuthRemoteDataSource();
  final authRepository = AuthRepositoryImpl(
    localDataSource: localDataSource,
    remoteDataSource: remoteDataSource,
  );
  final authController = AuthController(repository: authRepository);

  runApp(AgriFlowApp(
    authController: authController,
    localDataSource: localDataSource,
  ));
}
