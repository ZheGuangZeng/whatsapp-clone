import '../../../../core/errors/failures.dart' as failures;
import '../../../../core/utils/result.dart';
import '../../../auth/domain/usecases/base_usecase.dart';
import '../entities/room.dart';
import '../repositories/i_chat_repository.dart';

/// Use case for getting all rooms for current user
class GetRoomsUseCase implements NoParamsUseCase<List<Room>> {
  GetRoomsUseCase(this._chatRepository);

  final IChatRepository _chatRepository;

  @override
  Future<Result<List<Room>>> call() async {
    try {
      final rooms = await _chatRepository.getRooms();
      return Success(rooms);
    } catch (e) {
      return const ResultFailure(
        failures.ServerFailure('Failed to get rooms'),
      );
    }
  }
}

/// Use case for watching room updates
class WatchRoomsUseCase {
  WatchRoomsUseCase(this._chatRepository);

  final IChatRepository _chatRepository;

  /// Watch for real-time room updates
  Stream<List<Room>> call() {
    return _chatRepository.watchRooms();
  }
}