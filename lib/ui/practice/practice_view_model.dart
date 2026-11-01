import 'package:flutter/foundation.dart';

import '../../data/repositories/practice_repository.dart';
import '../../data/services/api_failure.dart';
import '../../domain/models/question.dart';
import '../../utils/result.dart';

sealed class PracticeState {
  const PracticeState();
}

final class PracticeLoading extends PracticeState {
  const PracticeLoading();
}

final class PracticeLoaded extends PracticeState {
  const PracticeLoaded(this.questions);
  final List<Question> questions;
}

final class PracticeEmpty extends PracticeState {
  const PracticeEmpty();
}

final class PracticeFailed extends PracticeState {
  const PracticeFailed(this.failure);
  final ApiFailure failure;
}

/// Holds the screen state. Safe to dispose while a request is in flight.
class PracticeViewModel extends ChangeNotifier {
  PracticeViewModel({
    required PracticeRepository repository,
    required String studentId,
  })  : _repository = repository,
        _studentId = studentId;

  final PracticeRepository _repository;
  final String _studentId;

  PracticeState _state = const PracticeLoading();
  bool _inFlight = false;
  bool _disposed = false;

  PracticeState get state => _state;
  bool get isLoading => _state is PracticeLoading;

  Future<void> load() async {
    if (_inFlight || _disposed) return; // a second tap sends no request
    _inFlight = true;
    _state = const PracticeLoading();
    notifyListeners();

    final result = await _repository.nextQuestions(_studentId);

    _inFlight = false;
    if (_disposed) return;
    _state = switch (result) {
      Ok(:final value) =>
        value.isEmpty ? const PracticeEmpty() : PracticeLoaded(value),
      Err(:final failure) => PracticeFailed(failure),
    };
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
