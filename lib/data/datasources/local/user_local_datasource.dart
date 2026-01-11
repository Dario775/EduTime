import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../../../core/error/exceptions.dart';
import '../../models/user_model.dart';

/// Local data source for user data
/// 
/// Handles caching user data locally using SharedPreferences.
abstract class UserLocalDataSource {
  /// Get cached user
  Future<UserModel?> getCachedUser();

  /// Cache user data
  Future<void> cacheUser(UserModel user);

  /// Clear cached user
  Future<void> clearCachedUser();

  /// Check if user is cached
  Future<bool> hasUserCached();
}

/// Implementation of [UserLocalDataSource] using SharedPreferences
class UserLocalDataSourceImpl implements UserLocalDataSource {
  static const String cachedUserKey = 'CACHED_USER';

  final SharedPreferences sharedPreferences;

  UserLocalDataSourceImpl({required this.sharedPreferences});

  @override
  Future<UserModel?> getCachedUser() async {
    try {
      final jsonString = sharedPreferences.getString(cachedUserKey);
      if (jsonString == null) return null;

      final jsonMap = json.decode(jsonString) as Map<String, dynamic>;
      final id = jsonMap['id'] as String;
      return UserModel.fromJson(jsonMap, id);
    } catch (e) {
      throw CacheException(
        message: 'Error reading cached user',
        originalError: e,
      );
    }
  }

  @override
  Future<void> cacheUser(UserModel user) async {
    try {
      final jsonMap = user.toJson();
      jsonMap['id'] = user.id;
      final jsonString = json.encode(jsonMap);
      await sharedPreferences.setString(cachedUserKey, jsonString);
    } catch (e) {
      throw CacheException(
        message: 'Error caching user',
        originalError: e,
      );
    }
  }

  @override
  Future<void> clearCachedUser() async {
    try {
      await sharedPreferences.remove(cachedUserKey);
    } catch (e) {
      throw CacheException(
        message: 'Error clearing cached user',
        originalError: e,
      );
    }
  }

  @override
  Future<bool> hasUserCached() async {
    return sharedPreferences.containsKey(cachedUserKey);
  }
}
