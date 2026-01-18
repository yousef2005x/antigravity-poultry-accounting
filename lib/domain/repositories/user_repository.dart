import 'package:poultry_accounting/domain/entities/user.dart';

abstract class UserRepository {
  Future<User?> login(String username, String password);
  Future<User?> getUserById(int id);
  Future<User> createUser(User user, String password);
  Future<void> changePassword(int userId, String newPassword);
  Future<List<User>> getAllUsers();
  Future<int> countUsers();
}
