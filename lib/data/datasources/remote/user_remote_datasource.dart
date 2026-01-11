import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/error/exceptions.dart';
import '../../../domain/entities/user.dart';
import '../../models/user_model.dart';

/// Remote data source for user data
/// 
/// Handles user operations with Firebase Auth and Firestore.
abstract class UserRemoteDataSource {
  /// Get the current authenticated user
  Future<UserModel?> getCurrentUser();

  /// Sign in with email and password
  Future<UserModel> signInWithEmailPassword({
    required String email,
    required String password,
  });

  /// Sign up with email and password
  Future<UserModel> signUpWithEmailPassword({
    required String email,
    required String password,
    String? displayName,
  });

  /// Sign out
  Future<void> signOut();

  /// Update user profile
  Future<UserModel> updateProfile({
    String? displayName,
    String? photoUrl,
  });

  /// Update user settings
  Future<UserModel> updateSettings(UserSettings settings);

  /// Stream of authentication state changes
  Stream<UserModel?> get authStateChanges;
}

/// Implementation of [UserRemoteDataSource] using Firebase
class UserRemoteDataSourceImpl implements UserRemoteDataSource {
  final firebase_auth.FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;

  UserRemoteDataSourceImpl({
    firebase_auth.FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
  })  : _firebaseAuth = firebaseAuth ?? firebase_auth.FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestore.collection('users');

  @override
  Future<UserModel?> getCurrentUser() async {
    try {
      final firebaseUser = _firebaseAuth.currentUser;
      if (firebaseUser == null) return null;

      final docSnapshot = await _usersCollection.doc(firebaseUser.uid).get();
      if (!docSnapshot.exists) return null;

      return UserModel.fromJson(docSnapshot.data()!, firebaseUser.uid);
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw AuthException(
        message: _mapFirebaseAuthError(e.code),
        code: e.code,
        originalError: e,
      );
    } catch (e) {
      throw ServerException(
        message: 'Error getting current user',
        originalError: e,
      );
    }
  }

  @override
  Future<UserModel> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final firebaseUser = credential.user;
      if (firebaseUser == null) {
        throw const AuthException(message: 'Error al iniciar sesión');
      }

      final docSnapshot = await _usersCollection.doc(firebaseUser.uid).get();
      if (!docSnapshot.exists) {
        throw const AuthException(message: 'Usuario no encontrado');
      }

      return UserModel.fromJson(docSnapshot.data()!, firebaseUser.uid);
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw AuthException(
        message: _mapFirebaseAuthError(e.code),
        code: e.code,
        originalError: e,
      );
    } catch (e) {
      if (e is AuthException) rethrow;
      throw ServerException(
        message: 'Error al iniciar sesión',
        originalError: e,
      );
    }
  }

  @override
  Future<UserModel> signUpWithEmailPassword({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final firebaseUser = credential.user;
      if (firebaseUser == null) {
        throw const AuthException(message: 'Error al crear cuenta');
      }

      // Update display name in Firebase Auth
      if (displayName != null) {
        await firebaseUser.updateDisplayName(displayName);
      }

      // Create user document in Firestore
      final now = DateTime.now();
      final userModel = UserModel(
        id: firebaseUser.uid,
        email: email,
        displayName: displayName,
        photoUrl: null,
        createdAt: now,
        updatedAt: now,
        settings: const UserSettingsModel(),
        stats: const UserStatsModel(),
      );

      await _usersCollection.doc(firebaseUser.uid).set(userModel.toJson());

      return userModel;
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw AuthException(
        message: _mapFirebaseAuthError(e.code),
        code: e.code,
        originalError: e,
      );
    } catch (e) {
      if (e is AuthException) rethrow;
      throw ServerException(
        message: 'Error al crear cuenta',
        originalError: e,
      );
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
    } catch (e) {
      throw ServerException(
        message: 'Error al cerrar sesión',
        originalError: e,
      );
    }
  }

  @override
  Future<UserModel> updateProfile({
    String? displayName,
    String? photoUrl,
  }) async {
    try {
      final firebaseUser = _firebaseAuth.currentUser;
      if (firebaseUser == null) {
        throw const AuthException(message: 'Usuario no autenticado');
      }

      // Update Firebase Auth profile
      if (displayName != null) {
        await firebaseUser.updateDisplayName(displayName);
      }
      if (photoUrl != null) {
        await firebaseUser.updatePhotoURL(photoUrl);
      }

      // Update Firestore document
      final updates = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (displayName != null) updates['displayName'] = displayName;
      if (photoUrl != null) updates['photoURL'] = photoUrl;

      await _usersCollection.doc(firebaseUser.uid).update(updates);

      // Fetch updated user
      final docSnapshot = await _usersCollection.doc(firebaseUser.uid).get();
      return UserModel.fromJson(docSnapshot.data()!, firebaseUser.uid);
    } catch (e) {
      if (e is AuthException) rethrow;
      throw ServerException(
        message: 'Error al actualizar perfil',
        originalError: e,
      );
    }
  }

  @override
  Future<UserModel> updateSettings(UserSettings settings) async {
    try {
      final firebaseUser = _firebaseAuth.currentUser;
      if (firebaseUser == null) {
        throw const AuthException(message: 'Usuario no autenticado');
      }

      final settingsModel = UserSettingsModel.fromEntity(settings);

      await _usersCollection.doc(firebaseUser.uid).update({
        'settings': settingsModel.toJson(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      final docSnapshot = await _usersCollection.doc(firebaseUser.uid).get();
      return UserModel.fromJson(docSnapshot.data()!, firebaseUser.uid);
    } catch (e) {
      if (e is AuthException) rethrow;
      throw ServerException(
        message: 'Error al actualizar configuración',
        originalError: e,
      );
    }
  }

  @override
  Stream<UserModel?> get authStateChanges {
    return _firebaseAuth.authStateChanges().asyncMap((firebaseUser) async {
      if (firebaseUser == null) return null;

      try {
        final docSnapshot = await _usersCollection.doc(firebaseUser.uid).get();
        if (!docSnapshot.exists) return null;
        return UserModel.fromJson(docSnapshot.data()!, firebaseUser.uid);
      } catch (e) {
        return null;
      }
    });
  }

  String _mapFirebaseAuthError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No existe una cuenta con este correo electrónico';
      case 'wrong-password':
        return 'Contraseña incorrecta';
      case 'email-already-in-use':
        return 'Ya existe una cuenta con este correo electrónico';
      case 'invalid-email':
        return 'Correo electrónico inválido';
      case 'weak-password':
        return 'La contraseña es muy débil';
      case 'user-disabled':
        return 'Esta cuenta ha sido deshabilitada';
      case 'too-many-requests':
        return 'Demasiados intentos. Intenta más tarde';
      case 'network-request-failed':
        return 'Error de conexión. Verifica tu internet';
      default:
        return 'Error de autenticación';
    }
  }
}
