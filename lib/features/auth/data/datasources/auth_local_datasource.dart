import 'dart:convert';
import 'package:hive/hive.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/error/exceptions.dart';
import '../models/user_model.dart';

abstract class AuthLocalDataSource {
  Future<void> cacheUser(UserModel user);
  Future<UserModel> getCachedUser();
  Future<void> clearCachedUser();
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  final Box _box;
  static const _userKey = 'cached_user';

  AuthLocalDataSourceImpl({Box? box})
      : _box = box ?? Hive.box(AppConstants.authBox);

  @override
  Future<void> cacheUser(UserModel user) async {
    await _box.put(_userKey, jsonEncode(user.toJson()));
  }

  @override
  Future<UserModel> getCachedUser() async {
    final raw = _box.get(_userKey) as String?;
    if (raw == null) {
      throw const CacheException('No cached user found');
    }
    return UserModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  @override
  Future<void> clearCachedUser() async {
    await _box.delete(_userKey);
  }
}
