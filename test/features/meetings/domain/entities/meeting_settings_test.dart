import 'package:flutter_test/flutter_test.dart';
import 'package:whatsapp_clone/features/meetings/domain/entities/meeting_settings.dart';

void main() {
  group('MeetingSettings Entity', () {
    late MeetingSettings testSettings;

    setUp(() {
      testSettings = const MeetingSettings(
        maxParticipants: 50,
        isRecordingEnabled: true,
        isWaitingRoomEnabled: false,
        allowScreenShare: true,
      );
    });

    group('Settings Creation', () {
      test('should create settings with all required fields', () {
        // Assert
        expect(testSettings.maxParticipants, equals(50));
        expect(testSettings.isRecordingEnabled, isTrue);
        expect(testSettings.isWaitingRoomEnabled, isFalse);
        expect(testSettings.allowScreenShare, isTrue);
      });

      test('should create settings with default values', () {
        // Arrange & Act
        const defaultSettings = MeetingSettings();

        // Assert
        expect(defaultSettings.maxParticipants, equals(100));
        expect(defaultSettings.isRecordingEnabled, isFalse);
        expect(defaultSettings.isWaitingRoomEnabled, isFalse);
        expect(defaultSettings.allowScreenShare, isTrue);
        expect(defaultSettings.allowChat, isTrue);
        expect(defaultSettings.isPublic, isFalse);
        expect(defaultSettings.requireApproval, isFalse);
      });

      test('should create settings with custom optional fields', () {
        // Arrange & Act
        const customSettings = MeetingSettings(
          maxParticipants: 25,
          isRecordingEnabled: false,
          isWaitingRoomEnabled: true,
          allowScreenShare: false,
          allowChat: false,
          isPublic: true,
          requireApproval: true,
          password: 'secret123',
        );

        // Assert
        expect(customSettings.maxParticipants, equals(25));
        expect(customSettings.isWaitingRoomEnabled, isTrue);
        expect(customSettings.allowScreenShare, isFalse);
        expect(customSettings.allowChat, isFalse);
        expect(customSettings.isPublic, isTrue);
        expect(customSettings.requireApproval, isTrue);
        expect(customSettings.password, equals('secret123'));
      });
    });

    group('Settings Validation', () {
      test('should validate max participants minimum value', () {
        // Arrange & Act
        const settingsWithMinParticipants = MeetingSettings(maxParticipants: 1);

        // Assert
        expect(settingsWithMinParticipants.maxParticipants, greaterThanOrEqualTo(1));
      });

      test('should validate max participants maximum value', () {
        // Arrange & Act
        const settingsWithMaxParticipants = MeetingSettings(maxParticipants: 1000);

        // Assert
        expect(settingsWithMaxParticipants.maxParticipants, lessThanOrEqualTo(1000));
      });

      test('should enforce password requirements when set', () {
        // Arrange
        const protectedSettings = MeetingSettings(
          password: 'validPassword123',
        );

        // Assert
        expect(protectedSettings.password, isNotNull);
        expect(protectedSettings.password!.isNotEmpty, isTrue);
        expect(protectedSettings.hasPassword, isTrue);
      });

      test('should identify settings without password', () {
        // Assert
        expect(testSettings.hasPassword, isFalse);
      });
    });

    group('Security Settings', () {
      test('should configure private meeting with approval required', () {
        // Arrange & Act
        const privateSettings = MeetingSettings(
          isPublic: false,
          requireApproval: true,
          password: 'private123',
        );

        // Assert
        expect(privateSettings.isPublic, isFalse);
        expect(privateSettings.requireApproval, isTrue);
        expect(privateSettings.hasPassword, isTrue);
        expect(privateSettings.isSecure, isTrue);
      });

      test('should configure public meeting without restrictions', () {
        // Arrange & Act
        const publicSettings = MeetingSettings(
          isPublic: true,
          requireApproval: false,
        );

        // Assert
        expect(publicSettings.isPublic, isTrue);
        expect(publicSettings.requireApproval, isFalse);
        expect(publicSettings.hasPassword, isFalse);
        expect(publicSettings.isSecure, isFalse);
      });

      test('should determine security level correctly', () {
        // Arrange
        const secureSettings = MeetingSettings(
          password: 'secure',
          requireApproval: true,
          isWaitingRoomEnabled: true,
        );

        const openSettings = MeetingSettings(
          isPublic: true,
          requireApproval: false,
          isWaitingRoomEnabled: false,
        );

        // Assert
        expect(secureSettings.isSecure, isTrue);
        expect(openSettings.isSecure, isFalse);
      });
    });

    group('Feature Settings', () {
      test('should configure recording settings correctly', () {
        // Arrange
        const recordingSettings = MeetingSettings(isRecordingEnabled: true);
        const noRecordingSettings = MeetingSettings(isRecordingEnabled: false);

        // Assert
        expect(recordingSettings.isRecordingEnabled, isTrue);
        expect(noRecordingSettings.isRecordingEnabled, isFalse);
      });

      test('should configure screen share permissions', () {
        // Arrange
        const screenShareAllowed = MeetingSettings(allowScreenShare: true);
        const screenShareBlocked = MeetingSettings(allowScreenShare: false);

        // Assert
        expect(screenShareAllowed.allowScreenShare, isTrue);
        expect(screenShareBlocked.allowScreenShare, isFalse);
      });

      test('should configure chat permissions', () {
        // Arrange
        const chatEnabled = MeetingSettings(allowChat: true);
        const chatDisabled = MeetingSettings(allowChat: false);

        // Assert
        expect(chatEnabled.allowChat, isTrue);
        expect(chatDisabled.allowChat, isFalse);
      });

      test('should configure waiting room feature', () {
        // Arrange
        const waitingRoomEnabled = MeetingSettings(isWaitingRoomEnabled: true);
        const waitingRoomDisabled = MeetingSettings(isWaitingRoomEnabled: false);

        // Assert
        expect(waitingRoomEnabled.isWaitingRoomEnabled, isTrue);
        expect(waitingRoomDisabled.isWaitingRoomEnabled, isFalse);
      });
    });

    group('Business Logic', () {
      test('should determine if meeting allows anonymous participants', () {
        // Arrange
        const publicNoApproval = MeetingSettings(
          isPublic: true,
          requireApproval: false,
          isWaitingRoomEnabled: false,
        );

        const privateWithApproval = MeetingSettings(
          isPublic: false,
          requireApproval: true,
          isWaitingRoomEnabled: true,
        );

        // Assert
        expect(publicNoApproval.allowsAnonymousJoin, isTrue);
        expect(privateWithApproval.allowsAnonymousJoin, isFalse);
      });

      test('should determine if meeting requires host approval', () {
        // Arrange
        const autoJoin = MeetingSettings(
          requireApproval: false,
          isWaitingRoomEnabled: false,
        );

        const manualApproval = MeetingSettings(
          requireApproval: true,
          isWaitingRoomEnabled: true,
        );

        // Assert
        expect(autoJoin.requiresHostApproval, isFalse);
        expect(manualApproval.requiresHostApproval, isTrue);
      });

      test('should validate participant limits against settings', () {
        // Arrange
        const limitedSettings = MeetingSettings(maxParticipants: 5);

        // Assert
        expect(limitedSettings.canAccommodate(3), isTrue);
        expect(limitedSettings.canAccommodate(5), isTrue);
        expect(limitedSettings.canAccommodate(6), isFalse);
        expect(limitedSettings.canAccommodate(10), isFalse);
      });
    });

    group('Equatable Implementation', () {
      test('should be equal when all properties match', () {
        // Arrange
        const settings1 = MeetingSettings(
          maxParticipants: 30,
          isRecordingEnabled: true,
          isWaitingRoomEnabled: true,
          allowScreenShare: false,
        );

        const settings2 = MeetingSettings(
          maxParticipants: 30,
          isRecordingEnabled: true,
          isWaitingRoomEnabled: true,
          allowScreenShare: false,
        );

        // Assert
        expect(settings1, equals(settings2));
      });

      test('should not be equal when properties differ', () {
        // Arrange
        final settings1 = testSettings;
        final settings2 = testSettings.copyWith(maxParticipants: 25);

        // Assert
        expect(settings1, isNot(equals(settings2)));
      });
    });

    group('CopyWith Functionality', () {
      test('should create copy with updated fields', () {
        // Arrange
        const newMaxParticipants = 75;
        const newRecordingStatus = false;

        // Act
        final updatedSettings = testSettings.copyWith(
          maxParticipants: newMaxParticipants,
          isRecordingEnabled: newRecordingStatus,
        );

        // Assert
        expect(updatedSettings.maxParticipants, equals(newMaxParticipants));
        expect(updatedSettings.isRecordingEnabled, equals(newRecordingStatus));
        expect(updatedSettings.allowScreenShare, equals(testSettings.allowScreenShare)); // Unchanged
        expect(updatedSettings.isWaitingRoomEnabled, equals(testSettings.isWaitingRoomEnabled)); // Unchanged
      });

      test('should preserve original values when no updates provided', () {
        // Act
        final copiedSettings = testSettings.copyWith();

        // Assert
        expect(copiedSettings, equals(testSettings));
      });

      test('should handle password updates correctly', () {
        // Arrange
        const newPassword = 'newSecurePassword';

        // Act
        final securedSettings = testSettings.copyWith(password: newPassword);
        final clearedPasswordSettings = securedSettings.copyWith(password: null);

        // Assert
        expect(securedSettings.password, equals(newPassword));
        expect(securedSettings.hasPassword, isTrue);
        expect(clearedPasswordSettings.password, isNull);
        expect(clearedPasswordSettings.hasPassword, isFalse);
      });
    });

    group('Settings Templates', () {
      test('should create default open meeting settings', () {
        // Act
        const openMeeting = MeetingSettings.openMeeting();

        // Assert
        expect(openMeeting.isPublic, isTrue);
        expect(openMeeting.requireApproval, isFalse);
        expect(openMeeting.isWaitingRoomEnabled, isFalse);
        expect(openMeeting.allowScreenShare, isTrue);
        expect(openMeeting.allowChat, isTrue);
        expect(openMeeting.hasPassword, isFalse);
      });

      test('should create secure meeting settings', () {
        // Act
        const secureMeeting = MeetingSettings.secureMeeting();

        // Assert
        expect(secureMeeting.isPublic, isFalse);
        expect(secureMeeting.requireApproval, isTrue);
        expect(secureMeeting.isWaitingRoomEnabled, isTrue);
        expect(secureMeeting.isRecordingEnabled, isFalse); // Security default
        expect(secureMeeting.hasPassword, isTrue);
      });

      test('should create webinar settings', () {
        // Act
        const webinarSettings = MeetingSettings.webinar();

        // Assert
        expect(webinarSettings.maxParticipants, greaterThan(100));
        expect(webinarSettings.allowScreenShare, isFalse); // Only host can share
        expect(webinarSettings.allowChat, isTrue);
        expect(webinarSettings.requireApproval, isTrue);
        expect(webinarSettings.isRecordingEnabled, isTrue);
      });
    });
  });
}