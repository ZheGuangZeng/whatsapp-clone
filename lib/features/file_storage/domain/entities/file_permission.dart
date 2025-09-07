import 'package:equatable/equatable.dart';

/// Enum for permission types with hierarchical structure
enum PermissionType {
  read('read'),
  write('write'),
  delete('delete'),
  admin('admin');

  const PermissionType(this.value);
  final String value;

  static PermissionType fromString(String value) {
    return PermissionType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => PermissionType.read,
    );
  }

  /// Whether this permission allows reading
  bool get canRead => true; // All permissions allow reading

  /// Whether this permission allows writing
  bool get canWrite => index >= PermissionType.write.index;

  /// Whether this permission allows deleting
  bool get canDelete => index >= PermissionType.delete.index;

  /// Whether this permission allows admin operations
  bool get canAdmin => this == PermissionType.admin;
}

/// Domain entity representing a file permission for a specific user
class FilePermission extends Equatable {
  const FilePermission({
    required this.id,
    required this.fileId,
    required this.userId,
    required this.permissionType,
    required this.grantedBy,
    required this.grantedAt,
    this.expiresAt,
  });

  /// Unique identifier for this permission
  final String id;

  /// ID of the file this permission applies to
  final String fileId;

  /// ID of the user who has this permission
  final String userId;

  /// Type of permission granted
  final PermissionType permissionType;

  /// User ID who granted this permission
  final String grantedBy;

  /// When this permission was granted
  final DateTime grantedAt;

  /// When this permission expires (null for permanent)
  final DateTime? expiresAt;

  /// Whether this permission has expired
  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  /// Whether this permission is permanent (never expires)
  bool get isPermanent => expiresAt == null;

  /// Whether this permission is currently active
  bool get isActive => !isExpired;

  /// Time until this permission expires (null if permanent)
  Duration? get timeUntilExpiry {
    if (expiresAt == null) return null;
    final now = DateTime.now();
    if (now.isAfter(expiresAt!)) return Duration.zero;
    return expiresAt!.difference(now);
  }

  /// Whether this permission allows reading
  bool get allowsRead => isActive && permissionType.canRead;

  /// Whether this permission allows writing
  bool get allowsWrite => isActive && permissionType.canWrite;

  /// Whether this permission allows deleting
  bool get allowsDelete => isActive && permissionType.canDelete;

  /// Whether this permission allows admin operations
  bool get allowsAdmin => isActive && permissionType.canAdmin;

  @override
  List<Object?> get props => [
        id,
        fileId,
        userId,
        permissionType,
        grantedBy,
        grantedAt,
        expiresAt,
      ];

  /// Creates a copy of this permission with updated fields
  FilePermission copyWith({
    String? id,
    String? fileId,
    String? userId,
    PermissionType? permissionType,
    String? grantedBy,
    DateTime? grantedAt,
    DateTime? expiresAt,
    bool clearExpiration = false,
  }) {
    return FilePermission(
      id: id ?? this.id,
      fileId: fileId ?? this.fileId,
      userId: userId ?? this.userId,
      permissionType: permissionType ?? this.permissionType,
      grantedBy: grantedBy ?? this.grantedBy,
      grantedAt: grantedAt ?? this.grantedAt,
      expiresAt: clearExpiration ? null : (expiresAt ?? this.expiresAt),
    );
  }
}

/// A collection of file permissions for a specific file
class FilePermissionSet extends Equatable {
  const FilePermissionSet(this.permissions);

  /// List of permissions for this file
  final List<FilePermission> permissions;

  /// The file ID that all permissions in this set apply to
  String get fileId {
    if (permissions.isEmpty) throw StateError('Permission set is empty');
    return permissions.first.fileId;
  }

  /// Get all currently active permissions
  List<FilePermission> get activePermissions =>
      permissions.where((p) => p.isActive).toList();

  /// Get all expired permissions
  List<FilePermission> get expiredPermissions =>
      permissions.where((p) => p.isExpired).toList();

  /// Get permissions for a specific user
  List<FilePermission> getPermissionsForUser(String userId) =>
      permissions.where((p) => p.userId == userId).toList();

  /// Check if a user has a specific permission type
  bool hasPermission(String userId, PermissionType permissionType) {
    final userPermissions = getPermissionsForUser(userId)
        .where((p) => p.isActive)
        .toList();

    return userPermissions.any((p) => p.permissionType.index >= permissionType.index);
  }

  /// Get the highest permission level for a user
  PermissionType? getHighestPermission(String userId) {
    final userPermissions = getPermissionsForUser(userId)
        .where((p) => p.isActive)
        .toList();

    if (userPermissions.isEmpty) return null;

    return userPermissions
        .map((p) => p.permissionType)
        .reduce((current, next) => 
            next.index > current.index ? next : current);
  }

  /// Add a new permission to this set
  FilePermissionSet addPermission(FilePermission permission) {
    return FilePermissionSet([...permissions, permission]);
  }

  /// Remove a permission by its ID
  FilePermissionSet removePermission(String permissionId) {
    return FilePermissionSet(
      permissions.where((p) => p.id != permissionId).toList(),
    );
  }

  /// Update an existing permission
  FilePermissionSet updatePermission(FilePermission updatedPermission) {
    final updatedPermissions = permissions.map((p) {
      return p.id == updatedPermission.id ? updatedPermission : p;
    }).toList();

    return FilePermissionSet(updatedPermissions);
  }

  @override
  List<Object?> get props => [permissions];
}