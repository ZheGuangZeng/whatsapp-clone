import 'package:equatable/equatable.dart';

import '../../../core/errors/failures.dart';
import '../../../core/utils/result.dart';
import '../../auth/domain/usecases/base_usecase.dart';
import '../entities/meeting_participant.dart';
import '../repositories/i_meeting_repository.dart';

/// Result for joining a meeting
class JoinMeetingResult extends Equatable {
  const JoinMeetingResult({
    required this.participant,
    required this.accessToken,
  });

  final MeetingParticipant participant;
  final String accessToken;

  @override
  List<Object?> get props => [participant, accessToken];
}

/// Use case to join a meeting
class JoinMeetingUseCase implements UseCase<JoinMeetingResult, JoinMeetingParams> {
  const JoinMeetingUseCase(this._repository);

  final IMeetingRepository _repository;

  @override
  Future<Result<JoinMeetingResult>> call(JoinMeetingParams params) async {
    // First check if meeting exists
    final getMeetingResult = await _repository.getMeeting(params.meetingId);
    
    return await getMeetingResult.when(
      success: (meeting) async {
        // Check if meeting is at capacity
        if (meeting.isAtCapacity && meeting.hostId != params.userId) {
          return const ResultFailure(
            ValidationFailure('Meeting has reached maximum capacity'),
          );
        }

        // Check if meeting has ended
        if (meeting.hasEnded) {
          return const ResultFailure(
            ValidationFailure('Meeting has already ended'),
          );
        }

        // Check if user is already a participant
        final participantsResult = await _repository.getMeetingParticipants(params.meetingId);
        final existingParticipant = await participantsResult.when(
          success: (participants) async {
            return participants
                .where((p) => p.userId == params.userId && p.isActive)
                .firstOrNull;
          },
          failure: (failure) async => null,
        );

        // If already participant, generate token and return
        if (existingParticipant != null) {
          final tokenResult = await _repository.generateLivekitToken(
            meetingId: params.meetingId,
            userId: params.userId,
            role: existingParticipant.role,
            ttl: params.tokenTtl,
          );

          return tokenResult.when(
            success: (token) => Success(JoinMeetingResult(
              participant: existingParticipant,
              accessToken: token,
            )),
            failure: (failure) => ResultFailure(failure),
          );
        }

        // Determine participant role
        final role = meeting.hostId == params.userId 
            ? ParticipantRole.host
            : params.role ?? ParticipantRole.participant;

        // Add user as participant
        final addParticipantResult = await _repository.addParticipant(
          meetingId: params.meetingId,
          userId: params.userId,
          role: role,
        );

        return await addParticipantResult.when(
          success: (participant) async {
            // Generate LiveKit access token
            final tokenResult = await _repository.generateLivekitToken(
              meetingId: params.meetingId,
              userId: params.userId,
              role: role,
              ttl: params.tokenTtl,
            );

            return tokenResult.when(
              success: (token) => Success(JoinMeetingResult(
                participant: participant,
                accessToken: token,
              )),
              failure: (failure) => ResultFailure(failure),
            );
          },
          failure: (failure) async => ResultFailure(failure),
        );
      },
      failure: (failure) async => ResultFailure(failure),
    );
  }
}

/// Parameters for JoinMeetingUseCase
class JoinMeetingParams extends Equatable {
  const JoinMeetingParams({
    required this.meetingId,
    required this.userId,
    this.role,
    this.tokenTtl = const Duration(hours: 2),
  });

  final String meetingId;
  final String userId;
  final ParticipantRole? role;
  final Duration tokenTtl;

  @override
  List<Object?> get props => [meetingId, userId, role, tokenTtl];
}