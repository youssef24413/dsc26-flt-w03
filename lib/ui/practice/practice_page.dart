import 'dart:async';

import 'package:flutter/material.dart';

import '../../data/repositories/practice_repository.dart';
import '../../data/services/api_failure.dart';
import '../../domain/models/question.dart';
import 'practice_view_model.dart';

class PracticePage extends StatefulWidget {
  const PracticePage({
    super.key,
    required this.repository,
    required this.studentId,
  });

  final PracticeRepository repository;
  final String studentId;

  @override
  State<PracticePage> createState() => _PracticePageState();
}

class _PracticePageState extends State<PracticePage> {
  late final PracticeViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = PracticeViewModel(
      repository: widget.repository,
      studentId: widget.studentId,
    );
    unawaited(_viewModel.load()); // loads once on start
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  void _signIn() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sign-in is not available in this demo.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        final state = _viewModel.state;
        return Scaffold(
          appBar: AppBar(
            title: const Text('Practice'),
            actions: [
              IconButton(
                key: const Key('practice-refresh'),
                tooltip: 'Refresh',
                icon: const Icon(Icons.refresh),
                onPressed: _viewModel.isLoading ? null : _viewModel.load,
              ),
            ],
          ),
          body: switch (state) {
            PracticeLoading() => const Center(
                child: CircularProgressIndicator(key: Key('practice-loading')),
              ),
            PracticeLoaded(:final questions) => ListView.builder(
                key: const Key('practice-list'),
                padding: const EdgeInsets.all(12),
                itemCount: questions.length,
                itemBuilder: (context, i) => _QuestionTile(questions[i]),
              ),
            PracticeEmpty() => const Center(
                key: Key('practice-empty'),
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    "You have finished today's practice. Well done!",
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            PracticeFailed(:final failure) => _FailureView(
                failure: failure,
                onRetry: _viewModel.load,
                onSignIn: _signIn,
              ),
          },
        );
      },
    );
  }
}

class _QuestionTile extends StatelessWidget {
  const _QuestionTile(this.question);

  final Question question;

  @override
  Widget build(BuildContext context) {
    return Card(
      key: Key('question-${question.id}'),
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              question.stem,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            for (final choice in question.choices)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text('• $choice'),
              ),
          ],
        ),
      ),
    );
  }
}

class _FailureView extends StatelessWidget {
  const _FailureView({
    required this.failure,
    required this.onRetry,
    required this.onSignIn,
  });

  final ApiFailure failure;
  final VoidCallback onRetry;
  final VoidCallback onSignIn;

  String get _message => switch (failure) {
        Offline() =>
          "You seem to be offline. Check your connection and try again.",
        TimedOut() => 'The server is taking too long. Please try again.',
        ServerError() =>
          'The server is busy right now. Please try again in a moment.',
        RateLimited() => 'Too many requests. Please wait a moment and retry.',
        Unauthorized() => 'Your session has expired. Please sign in again.',
        NotFound() => "We couldn't find your practice. Please try again later.",
        BadResponse() =>
          'We got an unexpected answer from the server. Please try again.',
        UnexpectedStatus() => 'Something went wrong. Please try again.',
      };

  @override
  Widget build(BuildContext context) {
    final needsSignIn = failure is Unauthorized;
    return Center(
      key: const Key('practice-error'),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48),
            const SizedBox(height: 12),
            Text(_message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            if (needsSignIn)
              FilledButton(
                key: const Key('practice-signin'),
                onPressed: onSignIn,
                child: const Text('Sign in'),
              )
            else
              FilledButton(
                key: const Key('practice-retry'),
                onPressed: onRetry,
                child: const Text('Try again'),
              ),
          ],
        ),
      ),
    );
  }
}
