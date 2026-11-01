import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../domain/models/question.dart';
import '../../utils/result.dart';
import 'api_failure.dart';

/// One call to the Masaraat questions API. Holds no state and never retries.
///
/// Keep the constructor and the signature of [fetchNext] exactly.
class QuestionApi {
  QuestionApi({
    required http.Client client,
    required Uri baseUrl,
    Duration timeout = const Duration(seconds: 10),
  })  : _client = client,
        _baseUrl = baseUrl,
        _timeout = timeout;

  final http.Client _client;
  final Uri _baseUrl;
  final Duration _timeout;

  static const Duration _defaultRetryAfter = Duration(seconds: 5);

  /// `GET {baseUrl}/v1/students/{studentId}/next-questions?limit={limit}`.
  ///
  /// Never throws for network or server problems. A [limit] outside 1-50 is a
  /// programming error and throws an [ArgumentError] before any request.
  Future<Result<List<Question>>> fetchNext({
    required String studentId,
    int limit = 10,
  }) async {
    if (limit < 1 || limit > 50) {
      throw ArgumentError.value(limit, 'limit', 'must be between 1 and 50');
    }

    final uri = _buildUri(studentId, limit);

    final http.Response response;
    try {
      response = await _client
          .get(uri, headers: const {'Accept': 'application/json'})
          .timeout(_timeout);
    } on TimeoutException {
      return const Err(TimedOut());
    } on http.ClientException {
      return const Err(Offline());
    }

    final code = response.statusCode;
    if (code == 200) {
      return _parse(response);
    }
    if (code == 401) return const Err(Unauthorized());
    if (code == 404) return const Err(NotFound());
    if (code == 429) {
      return Err(RateLimited(_parseRetryAfter(response.headers['retry-after'])));
    }
    if (code >= 500 && code <= 599) return Err(ServerError(code));
    return Err(UnexpectedStatus(code));
  }

  Uri _buildUri(String studentId, int limit) {
    // Keep any path the base URL already has; ignore a trailing slash.
    final basePath = _baseUrl.pathSegments.where((s) => s.isNotEmpty);
    return _baseUrl.replace(
      pathSegments: [
        ...basePath,
        'v1',
        'students',
        studentId,
        'next-questions',
      ],
      queryParameters: {'limit': '$limit'},
    );
  }

  Duration _parseRetryAfter(String? header) {
    if (header == null) return _defaultRetryAfter;
    final text = header.trim();
    if (!RegExp(r'^[0-9]+$').hasMatch(text)) return _defaultRetryAfter;
    final seconds = int.tryParse(text);
    if (seconds == null) return _defaultRetryAfter;
    return Duration(seconds: seconds);
  }

  Result<List<Question>> _parse(http.Response response) {
    try {
      // Always UTF-8, whatever the headers claim.
      var text = utf8.decode(response.bodyBytes);
      if (text.startsWith('\uFEFF')) text = text.substring(1);

      final decoded = jsonDecode(text);
      if (decoded is! Map<String, Object?>) {
        return const Err(BadResponse('top level is not an object'));
      }
      final rawQuestions = decoded['questions'];
      if (rawQuestions is! List<Object?>) {
        return const Err(BadResponse('questions is missing or not a list'));
      }

      final questions = <Question>[];
      for (final item in rawQuestions) {
        if (item is! Map<String, Object?>) {
          return const Err(BadResponse('a question is not an object'));
        }
        questions.add(Question.fromJson(item));
      }
      return Ok(List<Question>.unmodifiable(questions));
    } on FormatException catch (e) {
      return Err(BadResponse(e.message));
    } on Object catch (e) {
      return Err(BadResponse('unreadable body: ${e.runtimeType}'));
    }
  }
}
