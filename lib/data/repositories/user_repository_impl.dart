import 'package:drift/drift.dart';
import 'package:poultry_accounting/core/constants/app_constants.dart';
import 'package:poultry_accounting/core/utils/security_utils.dart';
import 'package:poultry_accounting/data/database/database.dart' as db;
import 'package:poultry_accounting/domain/entities/user.dart' as domain;
import 'package:poultry_accounting/domain/repositories/user_repository.dart';

class UserRepositoryImpl implements UserRepository {
  UserRepositoryImpl(this._db);

  final db.AppDatabase _db;

  @override
  Future<domain.User?> login(String username, String password) async {
    final hash = SecurityUtils.hashPassword(password);
    
    final query = _db.select(_db.users)
      ..where((tbl) => tbl.username.equals(username))
      ..where((tbl) => tbl.passwordHash.equals(hash))
      ..where((tbl) => tbl.isActive.equals(true));

    final userRow = await query.getSingleOrNull();

    if (userRow != null) {
      return _mapToEntity(userRow);
    }
    return null;
  }

  @override
  Future<domain.User> createUser(domain.User user, String password) async {
    final companion = db.UsersCompanion(
      username: Value(user.username),
      passwordHash: Value(SecurityUtils.hashPassword(password)),
      fullName: Value(user.fullName),
      role: Value(user.role.name), // Enum to string
      isActive: Value(user.isActive),
    );

    final id = await _db.into(_db.users).insert(companion);
    return user.copyWith(id: id);
  }

  @override
  Future<domain.User?> getUserById(int id) async {
    final query = _db.select(_db.users)..where((tbl) => tbl.id.equals(id));
    final row = await query.getSingleOrNull();
    return row != null ? _mapToEntity(row) : null;
  }

  @override
  Future<void> changePassword(int userId, String currentPassword, String newPassword) async {
    final userRow = await (_db.select(_db.users)..where((tbl) => tbl.id.equals(userId))).getSingleOrNull();
    
    if (userRow == null) {
      throw Exception('المستخدم غير موجود');
    }

    final currentHash = SecurityUtils.hashPassword(currentPassword);
    if (userRow.passwordHash != currentHash) {
      throw Exception('كلمة المرور الحالية غير صحيحة');
    }

    final companion = db.UsersCompanion(
      passwordHash: Value(SecurityUtils.hashPassword(newPassword)),
      updatedAt: Value(DateTime.now()),
    );
    
    await (_db.update(_db.users)..where((tbl) => tbl.id.equals(userId))).write(companion);
  }
  
  @override
  Future<List<domain.User>> getAllUsers() async {
    final rows = await _db.select(_db.users).get();
    return rows.map(_mapToEntity).toList().cast<domain.User>();
  }
  
  @override
  Future<int> countUsers() async {
    final countExp = _db.users.id.count();
    final query = _db.selectOnly(_db.users)..addColumns([countExp]);
    final result = await query.map((row) => row.read(countExp)).getSingle();
    return result ?? 0;
  }

  domain.User _mapToEntity(db.UserTable row) {
    return domain.User(
      id: row.id,
      username: row.username,
      fullName: row.fullName,
      phoneNumber: row.phoneNumber,
      passwordHash: '', // Not exposed in domain entity
      role: UserRole.fromCode(row.role),
      isActive: row.isActive,
    );
  }
}
