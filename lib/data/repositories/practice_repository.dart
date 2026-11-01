import '../../domain/models/question.dart';
import '../../utils/result.dart';
import '../services/api_failure.dart';
import '../services/question_api.dart';

/// The source of truth for practice questions. Owns the retry policy.
///
/// Keep the constructor and the signature of [nextQuestions] exactly.
class PracticeRepository {
  PracticeRepository({
    required QuestionApi api,
    required Future<void> Function(Duration) sleep,
    int maxRetries = 2,
  })  : _api = api,
        _sleep = sleep,
        _maxRetries = maxRetries;

  final QuestionApi _api;
  final Future<void> Function(Duration) _sleep;
  final int _maxRetries;

  static const Duration _maxRateLimitWait = Duration(seconds: 30);

  /// Retries transient failures at most `maxRetries` times, waiting 1 s, 2 s,
  /// 4 s, ... (Retry-After for 429, capped at 30 s). Permanent failures are
  /// returned after one call. When retries run out, the last result is returned.
  Future<Result<List<Question>>> nextQuestions(String studentId) async {
    var result = await _api.fetchNext(studentId: studentId);
    var retry = 0;

    while (result is Err<List<Question>> &&
        result.failure.isTransient &&
        retry < _maxRetries) {
      await _sleep(_waitFor(result.failure, retry));
      retry++;
      result = await _api.fetchNext(studentId: studentId);
    }
    return result;
  }

  Duration _waitFor(ApiFailure failure, int retryIndex) {
    if (failure is RateLimited) {
      return failure.retryAfter > _maxRateLimitWait
          ? _maxRateLimitWait
          : failure.retryAfter;
    }
    return Duration(seconds: 1 << retryIndex);
  }
}
