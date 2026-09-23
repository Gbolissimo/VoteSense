// lib/models/trivia_models.dart

class TriviaStage {
  final String stageTitle;
  final List<TriviaQuestion> questions;

  const TriviaStage({
    required this.stageTitle,
    required this.questions,
  });
}

class TriviaQuestion {
  final String scenario;
  final String answer;
  final String hint;

  const TriviaQuestion({
    required this.scenario,
    required this.answer,
    required this.hint,
  });
}

class TileItem {
  final int id;
  final String letter;
  bool isPlaced;

  TileItem({
    required this.id,
    required this.letter,
    this.isPlaced = false,
  });
}