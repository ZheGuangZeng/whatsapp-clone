import 'package:flutter_test/flutter_test.dart';
import 'package:whatsapp_clone/features/file_storage/domain/entities/file_permission.dart';

void main() {
  group('FilePermission', () {
    final testPermission = FilePermission(
      id: 'perm_123',
      fileId: 'file_123',
      userId: 'user_456',
      permissionType: PermissionType.read,
      grantedBy: 'user_123',
      grantedAt: DateTime.parse('2024-01-15T10:30:00Z'),
      expiresAt: DateTime.now().add(const Duration(days: 30)), // Future date
    );

    group('constructor', () {
      test('should create FilePermission with all required properties', () {
        expect(testPermission.id, equals('perm_123'));
        expect(testPermission.fileId, equals('file_123'));
        expect(testPermission.userId, equals('user_456'));
        expect(testPermission.permissionType, equals(PermissionType.read));
        expect(testPermission.grantedBy, equals('user_123'));
        expect(testPermission.grantedAt, equals(DateTime.parse('2024-01-15T10:30:00Z')));
        expect(testPermission.expiresAt, isNotNull);
        expect(testPermission.expiresAt!.isAfter(DateTime.now()), isTrue);
      });

      test('should create FilePermission with no expiration', () {
        final permanentPermission = FilePermission(
          id: 'perm_456',
          fileId: 'file_456',
          userId: 'user_789',
          permissionType: PermissionType.write,
          grantedBy: 'user_123',
          grantedAt: DateTime.parse('2024-01-16T11:00:00Z'),
          // expiresAt is null - permanent permission
        );

        expect(permanentPermission.expiresAt, isNull);
        expect(permanentPermission.isPermanent, isTrue);
      });
    });

    group('PermissionType enum', () {
      test('should convert from string value', () {
        expect(PermissionType.fromString('read'), equals(PermissionType.read));
        expect(PermissionType.fromString('write'), equals(PermissionType.write));
        expect(PermissionType.fromString('delete'), equals(PermissionType.delete));
        expect(PermissionType.fromString('admin'), equals(PermissionType.admin));
        expect(PermissionType.fromString('invalid'), equals(PermissionType.read));
      });

      test('should check permission hierarchy', () {
        expect(PermissionType.read.canRead, isTrue);
        expect(PermissionType.read.canWrite, isFalse);
        expect(PermissionType.read.canDelete, isFalse);
        expect(PermissionType.read.canAdmin, isFalse);

        expect(PermissionType.write.canRead, isTrue);
        expect(PermissionType.write.canWrite, isTrue);
        expect(PermissionType.write.canDelete, isFalse);
        expect(PermissionType.write.canAdmin, isFalse);

        expect(PermissionType.delete.canRead, isTrue);
        expect(PermissionType.delete.canWrite, isTrue);
        expect(PermissionType.delete.canDelete, isTrue);
        expect(PermissionType.delete.canAdmin, isFalse);

        expect(PermissionType.admin.canRead, isTrue);
        expect(PermissionType.admin.canWrite, isTrue);
        expect(PermissionType.admin.canDelete, isTrue);
        expect(PermissionType.admin.canAdmin, isTrue);
      });
    });

    group('computed properties', () {
      test('should determine if permission is expired', () {
        final expiredPermission = testPermission.copyWith(
          expiresAt: DateTime.now().subtract(const Duration(days: 1)),
        );
        expect(expiredPermission.isExpired, isTrue);

        final futurePermission = testPermission.copyWith(
          expiresAt: DateTime.now().add(const Duration(days: 1)),
        );
        expect(futurePermission.isExpired, isFalse);

        final permanentPermission = testPermission.copyWith(clearExpiration: true);
        expect(permanentPermission.isExpired, isFalse);
        expect(permanentPermission.isPermanent, isTrue);
      });

      test('should determine if permission is active', () {
        final activePermission = testPermission.copyWith(
          expiresAt: DateTime.now().add(const Duration(days: 1)),
        );
        expect(activePermission.isActive, isTrue);

        final expiredPermission = testPermission.copyWith(
          expiresAt: DateTime.now().subtract(const Duration(days: 1)),
        );
        expect(expiredPermission.isActive, isFalse);

        final permanentPermission = testPermission.copyWith(clearExpiration: true);
        expect(permanentPermission.isActive, isTrue);
      });

      test('should calculate time until expiration', () {
        final now = DateTime.now();
        final futurePermission = testPermission.copyWith(
          expiresAt: now.add(const Duration(hours: 2)),
        );
        final timeToExpiry = futurePermission.timeUntilExpiry;
        expect(timeToExpiry, isNotNull);
        expect(timeToExpiry!.inMinutes, greaterThan(60)); // At least 1 hour remaining

        final permanentPermission = testPermission.copyWith(clearExpiration: true);
        expect(permanentPermission.timeUntilExpiry, isNull);
      });

      test('should check if permission allows specific actions', () {
        final readPermission = testPermission.copyWith(permissionType: PermissionType.read);
        expect(readPermission.allowsRead, isTrue);
        expect(readPermission.allowsWrite, isFalse);
        expect(readPermission.allowsDelete, isFalse);

        final writePermission = testPermission.copyWith(permissionType: PermissionType.write);
        expect(writePermission.allowsRead, isTrue);
        expect(writePermission.allowsWrite, isTrue);
        expect(writePermission.allowsDelete, isFalse);

        final deletePermission = testPermission.copyWith(permissionType: PermissionType.delete);
        expect(deletePermission.allowsRead, isTrue);
        expect(deletePermission.allowsWrite, isTrue);
        expect(deletePermission.allowsDelete, isTrue);
      });
    });

    group('copyWith', () {
      test('should create copy with updated fields', () {
        final updatedPermission = testPermission.copyWith(
          permissionType: PermissionType.write,
          expiresAt: DateTime.parse('2024-03-15T10:30:00Z'),
        );

        expect(updatedPermission.id, equals(testPermission.id));
        expect(updatedPermission.fileId, equals(testPermission.fileId));
        expect(updatedPermission.permissionType, equals(PermissionType.write));
        expect(updatedPermission.expiresAt, equals(DateTime.parse('2024-03-15T10:30:00Z')));
      });

      test('should preserve original values when no updates provided', () {
        final copiedPermission = testPermission.copyWith();

        expect(copiedPermission, equals(testPermission));
        expect(copiedPermission.hashCode, equals(testPermission.hashCode));
      });
    });

    group('equality', () {
      test('should be equal when all properties match', () {
        final otherPermission = FilePermission(
          id: 'perm_123',
          fileId: 'file_123',
          userId: 'user_456',
          permissionType: PermissionType.read,
          grantedBy: 'user_123',
          grantedAt: DateTime.parse('2024-01-15T10:30:00Z'),
          expiresAt: testPermission.expiresAt, // Use same expiration date
        );

        expect(testPermission, equals(otherPermission));
        expect(testPermission.hashCode, equals(otherPermission.hashCode));
      });

      test('should not be equal when properties differ', () {
        final differentPermission = testPermission.copyWith(permissionType: PermissionType.write);

        expect(testPermission, isNot(equals(differentPermission)));
        expect(testPermission.hashCode, isNot(equals(differentPermission.hashCode)));
      });
    });
  });

  group('FilePermissionSet', () {
    final permissions = [
      FilePermission(
        id: 'perm_1',
        fileId: 'file_123',
        userId: 'user_1',
        permissionType: PermissionType.read,
        grantedBy: 'admin',
        grantedAt: DateTime.parse('2024-01-15T10:30:00Z'),
      ),
      FilePermission(
        id: 'perm_2',
        fileId: 'file_123',
        userId: 'user_2',
        permissionType: PermissionType.write,
        grantedBy: 'admin',
        grantedAt: DateTime.parse('2024-01-15T10:30:00Z'),
      ),
      FilePermission(
        id: 'perm_3',
        fileId: 'file_123',
        userId: 'user_3',
        permissionType: PermissionType.admin,
        grantedBy: 'admin',
        grantedAt: DateTime.parse('2024-01-15T10:30:00Z'),
        expiresAt: DateTime.now().subtract(const Duration(days: 1)), // Expired
      ),
    ];

    final permissionSet = FilePermissionSet(permissions);

    group('constructor', () {
      test('should create FilePermissionSet with list of permissions', () {
        expect(permissionSet.permissions.length, equals(3));
        expect(permissionSet.fileId, equals('file_123'));
      });
    });

    group('permission queries', () {
      test('should get active permissions', () {
        final activePermissions = permissionSet.activePermissions;
        expect(activePermissions.length, equals(2));
        expect(activePermissions.every((p) => p.isActive), isTrue);
      });

      test('should get expired permissions', () {
        final expiredPermissions = permissionSet.expiredPermissions;
        expect(expiredPermissions.length, equals(1));
        expect(expiredPermissions.first.isExpired, isTrue);
      });

      test('should get permissions for specific user', () {
        final userPermissions = permissionSet.getPermissionsForUser('user_1');
        expect(userPermissions.length, equals(1));
        expect(userPermissions.first.userId, equals('user_1'));
      });

      test('should check if user has specific permission type', () {
        expect(permissionSet.hasPermission('user_1', PermissionType.read), isTrue);
        expect(permissionSet.hasPermission('user_1', PermissionType.write), isFalse);
        expect(permissionSet.hasPermission('user_2', PermissionType.write), isTrue);
        expect(permissionSet.hasPermission('user_3', PermissionType.admin), isFalse); // Expired
        expect(permissionSet.hasPermission('nonexistent', PermissionType.read), isFalse);
      });

      test('should get highest permission level for user', () {
        expect(permissionSet.getHighestPermission('user_1'), equals(PermissionType.read));
        expect(permissionSet.getHighestPermission('user_2'), equals(PermissionType.write));
        expect(permissionSet.getHighestPermission('user_3'), isNull); // Expired
        expect(permissionSet.getHighestPermission('nonexistent'), isNull);
      });
    });

    group('permission management', () {
      test('should add new permission', () {
        final newPermission = FilePermission(
          id: 'perm_4',
          fileId: 'file_123',
          userId: 'user_4',
          permissionType: PermissionType.delete,
          grantedBy: 'admin',
          grantedAt: DateTime.now(),
        );

        final updatedSet = permissionSet.addPermission(newPermission);
        expect(updatedSet.permissions.length, equals(4));
        expect(updatedSet.hasPermission('user_4', PermissionType.delete), isTrue);
      });

      test('should remove permission', () {
        final updatedSet = permissionSet.removePermission('perm_1');
        expect(updatedSet.permissions.length, equals(2));
        expect(updatedSet.hasPermission('user_1', PermissionType.read), isFalse);
      });

      test('should update existing permission', () {
        final updatedPermission = permissions.first.copyWith(
          permissionType: PermissionType.admin,
        );

        final updatedSet = permissionSet.updatePermission(updatedPermission);
        expect(updatedSet.getHighestPermission('user_1'), equals(PermissionType.admin));
      });
    });
  });
}