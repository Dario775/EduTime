import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import 'dart:async';

class AuthService {
  static const String _keyCurrentUser = 'current_user';
  static const String _keyAllUsers = 'all_users';
  
  late SharedPreferences _prefs;
  AppUser? _currentUser;
  
  // Stream controller for auth changes
  final _authStateController = StreamController<AppUser?>.broadcast();

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadCurrentUser();
  }

  // Get current user
  AppUser? get currentUser => _currentUser;

  // Stream of auth changes
  Stream<AppUser?> get authStateChanges => _authStateController.stream;

  Future<void> _loadCurrentUser() async {
    final userJson = _prefs.getString(_keyCurrentUser);
    if (userJson != null) {
      try {
        final map = json.decode(userJson) as Map<String, dynamic>;
        _currentUser = AppUser.fromMap(map, map['uid'] as String? ?? 'unknown');
        _authStateController.add(_currentUser);
      } catch (e) {
        print('Error loading current user: $e');
        await signOut();
      }
    } else {
      _authStateController.add(null);
    }
  }

  Future<void> _saveCurrentUser() async {
    if (_currentUser != null) {
      await _prefs.setString(_keyCurrentUser, json.encode({..._currentUser!.toMap(), 'uid': _currentUser!.uid}));
    } else {
      await _prefs.remove(_keyCurrentUser);
    }
    _authStateController.add(_currentUser);
  }

  Future<List<AppUser>> _getAllUsers() async {
    final usersJson = _prefs.getString(_keyAllUsers);
    if (usersJson == null) return [];
    
    try {
      final List<dynamic> list = json.decode(usersJson) as List<dynamic>;
      return list.map((map) => AppUser.fromMap(map as Map<String, dynamic>, map['uid'] as String? ?? 'unknown')).toList();
    } catch (e) {
      print('Error getting all users: $e');
      return [];
    }
  }

  Future<void> _saveAllUsers(List<AppUser> users) async {
    final list = users.map((u) => {...u.toMap(), 'uid': u.uid}).toList();
    await _prefs.setString(_keyAllUsers, json.encode(list));
  }

  // Register new user (parent or child)
  Future<String?> registerUser({
    required String email,
    required String password,
    required String name,
    required UserRole role,
  }) async {
    try {
      final users = await _getAllUsers();
      
      // Check if email exists
      if (users.any((u) => u.email == email)) {
        return 'El email ya está registrado';
      }

      // Create new user
      final uid = DateTime.now().millisecondsSinceEpoch.toString();
      final user = AppUser(
        uid: uid,
        email: email,
        name: name,
        role: role,
        linkedChildrenIds: role == UserRole.parent ? [] : null,
        createdAt: DateTime.now(),
      );

      users.add(user);
      await _saveAllUsers(users);

      // Auto login
      _currentUser = user;
      await _saveCurrentUser();

      return null; // Success
    } catch (e) {
      return 'Error inesperado: $e';
    }
  }

  // Sign in
  // Note: Since we don't store passwords in this simple local mock, 
  // we just check if the email exists. Ideally, we would hash & store passwords.
  // For this prototype, ANY password works if the email exists.
  Future<String?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final users = await _getAllUsers();
      
      try {
        final user = users.firstWhere((u) => u.email == email);
        _currentUser = user;
        await _saveCurrentUser();
        return null; // Success
      } catch (e) {
        return 'Usuario no encontrado';
      }
    } catch (e) {
      return 'Error inesperado: $e';
    }
  }

  // Sign out
  Future<void> signOut() async {
    _currentUser = null;
    await _saveCurrentUser();
  }

  // Link child to parent
  Future<String?> linkChildToParent({
    required String childId,
    required String parentId,
  }) async {
    try {
      final users = await _getAllUsers();
      
      // Find child and parent
      final childIndex = users.indexWhere((u) => u.uid == childId);
      final parentIndex = users.indexWhere((u) => u.uid == parentId);
      
      if (childIndex == -1 || parentIndex == -1) {
        return 'Usuario no encontrado';
      }

      // Update child
      final child = users[childIndex];
      users[childIndex] = AppUser(
        uid: child.uid,
        email: child.email,
        name: child.name,
        role: child.role,
        linkedParentId: parentId,
        createdAt: child.createdAt,
      );

      // Update parent
      final parent = users[parentIndex];
      final newChildren = List<String>.from(parent.linkedChildrenIds ?? []);
      if (!newChildren.contains(childId)) {
        newChildren.add(childId);
      }
      
      users[parentIndex] = AppUser(
        uid: parent.uid,
        email: parent.email,
        name: parent.name,
        role: parent.role,
        linkedChildrenIds: newChildren,
        createdAt: parent.createdAt,
      );

      await _saveAllUsers(users);
      
      // Update current user if involved
      if (_currentUser?.uid == parentId) {
        _currentUser = users[parentIndex];
        await _saveCurrentUser();
      } else if (_currentUser?.uid == childId) {
         _currentUser = users[childIndex];
         await _saveCurrentUser();
      }

      return null; // Success
    } catch (e) {
      return 'Error al vincular cuentas: $e';
    }
  }

  // --- Parenting / Linking Logic (Mock) ---
  
  // In-memory storage for pairing codes (Code -> UserID)
  final Map<String, String> _activeConnectionCodes = {};

  // Generate a 6-digit code for the current user (Parent)
  Future<String> generateConnectionCode() async {
    final user = _currentUser;
    if (user == null) throw Exception('No user logged in');
    
    // Generate simple 6-digit code
    final code = (100000 + DateTime.now().millisecondsSinceEpoch % 900000).toString();
    
    // Store in memory (valid for this session)
    _activeConnectionCodes[code] = user.uid;
    
    return code;
  }

  // Connect using a code (Child enters Parent's code)
  Future<String?> connectWithCode(String code) async {
    try {
      final parentId = _activeConnectionCodes[code];
      
      if (parentId == null) {
        return 'Código inválido o expirado';
      }

      final childId = _currentUser?.uid;
      if (childId == null) return 'No hay usuario activo';

      // Perform the linking
      final error = await linkChildToParent(childId: childId, parentId: parentId);
      
      if (error == null) {
        // Consume code (optional, keep it if multiple children need to join)
        // _activeConnectionCodes.remove(code); 
      }
      
      return error;
    } catch (e) {
      return 'Error al conectar: $e';
    }
  }

  // Get children of a parent
  Future<List<AppUser>> getChildren(String parentId) async {
    try {
      final users = await _getAllUsers();
      return users.where((u) => u.linkedParentId == parentId).toList();
    } catch (e) {
      print('Error getting children: $e');
      return [];
    }
  }
}

// Global instance
final authService = AuthService();
