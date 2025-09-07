import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../entities/meeting.dart';
import '../repositories/i_meeting_repository.dart';

/// Use case for creating a new meeting
class CreateMeetingUseCase {
  const CreateMeetingUseCase(this._repository);

  final IMeetingRepository _repository;

  Future<Result<Meeting>> call(CreateMeetingParams params) async {
    // Validate input parameters
    final validationResult = _validateParams(params);
    if (validationResult != null) {
      return ResultFailure(validationResult);
    }

    // Delegate to repository
    return await _repository.createMeeting(params);
  }

  ValidationFailure? _validateParams(CreateMeetingParams params) {
    // Title validation
    if (params.title.trim().isEmpty) {
      return const ValidationFailure(message: 'Title cannot be empty');
    }

    if (params.title.length > 200) {
      return const ValidationFailure(message: 'Title cannot exceed 200 characters');
    }

    // Host ID validation
    if (params.hostId.trim().isEmpty) {
      return const ValidationFailure(message: 'Host ID cannot be empty');
    }

    // Description validation
    if (params.description != null && params.description!.length > 1000) {
      return const ValidationFailure(message: 'Description cannot exceed 1000 characters');
    }

    // Scheduled time validation
    if (params.scheduledStartTime != null && 
        params.scheduledStartTime!.isBefore(DateTime.now())) {
      return const ValidationFailure(message: 'Meeting scheduled time cannot be in the past');
    }

    // Settings validation
    if (params.settings.maxParticipants <= 0) {
      return const ValidationFailure(message: 'Meeting participant limit must be greater than 0');
    }

    return null; // No validation errors
  }
}