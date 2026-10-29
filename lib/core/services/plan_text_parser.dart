import '../../shared/models/exercise.dart';

/// One row the heuristic parser pulled out of free-form text.
class SmartParsedRow {
  const SmartParsedRow({required this.day, required this.exercise, required this.sets, required this.reps});
  final String day;
  final Exercise exercise;
  final int sets;
  final String reps;
}

/// Turns free-form text from a pasted CSV, .xlsx or .pdf into plan rows.
/// It's rule-based, not a language model: regex pattern matching plus fuzzy
/// matching of exercise names against the catalog. No network call or API.
class PlanTextParser {
  PlanTextParser._();

  // Matches "4x8", "4 x 8", "4 sets x 8 reps", "3 sets of 10" and so on.
  // Group 1 is sets, group 2 is reps (a number or a duration like "45s").
  // The trailing word "reps" is optional and not captured.
  static final _setsRepsPatterns = [
    RegExp(r'(\d+)\s*(?:sets?)?\s*[x×]\s*(\d+\s*(?:s|sec|secs|min|mins)?)', caseSensitive: false),
    RegExp(r'(\d+)\s*sets?\s*(?:of|for)\s*(\d+\s*(?:s|sec|secs|min|mins)?)(?:\s*reps?)?', caseSensitive: false),
  ];

  static final _dayKeywords = RegExp(
    r'^(monday|tuesday|wednesday|thursday|friday|saturday|sunday|mon|tue|tues|wed|thu|thur|thurs|fri|sat|sun|'
    r'day\s*\d+|push(\s*[ab])?|pull(\s*[ab])?|legs?(\s*[ab])?|upper(\s*body)?|lower(\s*body)?|'
    r'full\s*body|chest|back|shoulders?|arms?|core|cardio|rest\s*day|'
    // Short codes like "A1", "B2" or "C", common in workout logs. Safe to allow
    // because real exercise lines always have several words.
    r'[a-z]\d{0,2})\s*:?\s*$',
    caseSensitive: false,
  );

  /// [rawText] is the text already extracted from the file; [catalog] is the
  /// exercise list names are matched against, so imported plans link to real
  /// `exercises` rows.
  static List<SmartParsedRow> parse(String rawText, List<Exercise> catalog) {
    final lines = rawText
        .split(RegExp(r'[\r\n]+'))
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    final rows = <SmartParsedRow>[];
    var currentDay = 'Day 1';

    for (final rawLine in lines) {
      final line = _stripBullet(rawLine);

      if (_dayKeywords.hasMatch(line) && line.length < 40) {
        currentDay = _titleCase(line.replaceAll(':', '').trim());
        continue;
      }

      final match = _findSetsReps(line);
      if (match == null) continue;
      final (sets, reps, matchStart, matchEnd) = match;

      // The name is whatever remains once the sets/reps token and surrounding
      // separators are removed. That covers "Bench Press, 4x8" and
      // "Bench Press - 4 sets of 8"; a day prefix is handled above.
      var namePart = '${line.substring(0, matchStart)} ${line.substring(matchEnd)}'.trim();
      namePart = namePart.replaceAll(RegExp(r'^[,\-–:•\s]+|[,\-–:•\s]+$'), '').trim();
      if (namePart.isEmpty) continue;

      final exercise = _bestMatch(namePart, catalog);
      if (exercise == null) continue;

      rows.add(SmartParsedRow(day: currentDay, exercise: exercise, sets: sets, reps: reps));
    }

    return rows;
  }

  static String _stripBullet(String line) => line.replaceFirst(RegExp(r'^[\-*•▪\d]+[\.\)]?\s+'), '');

  static (int, String, int, int)? _findSetsReps(String line) {
    for (final pattern in _setsRepsPatterns) {
      final m = pattern.firstMatch(line);
      if (m == null) continue;
      final sets = int.tryParse(m.group(1) ?? '');
      if (sets == null) continue;
      final repsRaw = (m.group(2) ?? '').trim();
      final reps = repsRaw.isEmpty ? '' : repsRaw.replaceAll(RegExp(r'\s+'), ' ');
      if (reps.isEmpty) continue;
      return (sets, reps, m.start, m.end);
    }
    return null;
  }

  static String _titleCase(String s) {
    if (s.isEmpty) return s;
    return s.split(RegExp(r'\s+')).map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}').join(' ');
  }

  /// Fuzzy-matches [namePart] to a catalog exercise by word overlap, so extra
  /// words, missing words and different word order still match.
  static Exercise? _bestMatch(String namePart, List<Exercise> catalog) {
    final queryWords = _words(namePart);
    if (queryWords.isEmpty) return null;

    Exercise? best;
    var bestScore = 0.0;
    for (final exercise in catalog) {
      final nameWords = _words(exercise.name);
      if (nameWords.isEmpty) continue;
      final overlap = queryWords.intersection(nameWords).length;
      if (overlap == 0) continue;
      // Score favors matching a high fraction of the CATALOG name's
      // words (so "Bench Press" matches "Barbell Bench Press" well)
      // while still rewarding exact/near-exact matches most.
      final score = overlap / nameWords.length + (overlap / queryWords.length) * 0.5;
      if (score > bestScore) {
        bestScore = score;
        best = exercise;
      }
    }
    // Require at least half of the catalog exercise's own words to be
    // present -- otherwise a single shared common word (e.g. "press")
    // would match almost anything.
    return bestScore >= 0.5 ? best : null;
  }

  static Set<String> _words(String s) => s
      .toLowerCase()
      .split(RegExp(r'[^a-z0-9]+'))
      .where((w) => w.length > 2) // drop short filler words ("a", "of", "to"...)
      .toSet();
}
