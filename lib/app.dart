import 'package:flutter/material.dart';

import 'data/repositories/practice_repository.dart';
import 'ui/practice/practice_page.dart';

/// The practice app. The tests only ever call this function.
Widget buildPracticeApp({
  required PracticeRepository repository,
  String studentId = 'demo',
}) {
  return MaterialApp(
    title: 'Masaraat',
    home: PracticePage(repository: repository, studentId: studentId),
  );
}
