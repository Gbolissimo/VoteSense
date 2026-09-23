import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../models/trivia_models.dart';

class LegalTriviaGameScreen extends StatefulWidget {
  final int levelIndex;
  final String userId;
  final VoidCallback? onLevelCompleted;

  const LegalTriviaGameScreen({
    super.key,
    required this.levelIndex,
    required this.userId,
    this.onLevelCompleted,
  });

  @override
  State<LegalTriviaGameScreen> createState() => _LegalTriviaGameScreenState();
}

class _LegalTriviaGameScreenState extends State<LegalTriviaGameScreen>
    with TickerProviderStateMixin {
  static const Color primaryColor = Color(0xFFE66C75);
  static const Color darkBackground = Color(0xFF111318);
  static const Color cardBackground = Color(0xFF1A1D24);

  static const List<TriviaStage> _allStages = [
    TriviaStage(
      stageTitle: 'Level 1: Everyday Law & Street Rights',
      questions: [

        TriviaQuestion(
          scenario: 'Police come looking for your roommate for a crime, but because they can’t find him, they arrest you instead. What illegal practice is this?',
          answer: 'PROXY',
          hint: 'Under Section 7 of the ACJA, arrest in lieu (arresting someone else) is illegal.',
        ),
        TriviaQuestion(
          scenario: 'Security officers knock on your door at 6 AM demanding to search your bedroom. What official document signed by a magistrate must they produce first?',
          answer: 'WARRANT',
          hint: 'Without a search warrant (or hot pursuit), entering a private residence is unlawful.',
        ),
        TriviaQuestion(
          scenario: 'Your landlord suddenly changes the main gate lock while you are at work because you are 2 weeks late on rent. What illegal act is this called?',
          answer: 'SELF-HELP',
          hint: 'Landlords cannot take the law into their hands without a proper court Quit Notice.',
        ),
        TriviaQuestion(
          scenario: 'You buy a second-hand phone at Computer Village without a receipt, and it turns out to be stolen. What crime can you be charged with?',
          answer: 'RECEIVING',
          hint: 'Receiving stolen property is a serious criminal offense under the Criminal Code.',
        ),
        TriviaQuestion(
          scenario: 'You get arrested, and the IPO demands you sign a written statement immediately. What constitutional right allows you to refuse until your lawyer arrives?',
          answer: 'SILENCE',
          hint: 'You have the right to remain silent under Section 35 of the 1999 Constitution.',
        ),
        TriviaQuestion(
          scenario: 'Your company fires you overnight without paying your earned salary or giving notice. Which specialized Nigerian court handles this workplace dispute?',
          answer: 'NICN',
          hint: 'National Industrial Court of Nigeria handles all labor and employment matters.',
        ),
        TriviaQuestion(
          scenario: 'An officer seizes your mobile phone at a random stop and demands your passcode to scroll through your WhatsApp messages. Is this search legal without a court order?',
          answer: 'ILLEGAL',
          hint: 'Your right to privacy of communication is protected under Section 37 of the Constitution.',
        ),
        TriviaQuestion(
          scenario: 'Police hold a suspect in a station cell for 5 straight days without taking them before a magistrate. What fundamental right is being violated?',
          answer: 'LIBERTY',
          hint: 'Section 35 limits police detention to 24-48 hours depending on court proximity.',
        ),
        TriviaQuestion(
          scenario: 'What is the mandatory legal document required from every voter at a polling unit before casting a vote in Nigerian general elections?',
          answer: 'PVC',
          hint: 'Permanent Voter Card issued by INEC.',
        ),
        TriviaQuestion(
          scenario: 'You sign a contract with a artisan, pay a 70% deposit, and they run away with the money without doing the work. What type of court case is this primarily?',
          answer: 'CIVIL',
          hint: 'Breach of contract is civil, though intent to defraud can make it criminal (obtaining under false pretence).',
        ),
        TriviaQuestion(
          scenario: 'An emergency order issued by a judge to compel the police to bring a detained person physically to court to check if their detention is lawful.',
          answer: 'HABEAS-CORPUS',
          hint: 'A writ used to rescue individuals held in prolonged illegal detention.',
        ),
        TriviaQuestion(
          scenario: 'You lose your SIM card or National ID and need a sworn paper from a court to retrieve or replace it. What is this sworn document called?',
          answer: 'AFFIDAVIT',
          hint: 'A written statement sworn under oath before a court Commissioner for Oaths.',
        ),

        TriviaQuestion(
          scenario: 'What legal document must a landlord serve a yearly tenant before issuing a 7-day Notice owner intent to recover premises?',
          answer: 'QUIT-NOTICE',
          hint: 'Yearly tenants are entitled to a statutory 6-month notice period.',
        ),
        TriviaQuestion(
          scenario: 'The maximum authority law in Nigeria that overrides any local law or state assembly regulation if there is a conflict.',
          answer: 'CONSTITUTION',
          hint: 'Section 1(3) states that any law inconsistent with it is void to the extent of the inconsistency.',
        ),
        TriviaQuestion(
          scenario: 'You witness a road accident on the highway and take the victim to a private hospital. Can the hospital refuse treatment while demanding a police report first?',
          answer: 'ILLEGAL',
          hint: 'Under the Compulsory Treatment and Care for Victims of Gunshots/Accidents Act, treatment is mandatory before police reports.',
        ),
        TriviaQuestion(
          scenario: 'What legal principle states that you cannot be punished for an act that was not a defined crime at the time you committed it?',
          answer: 'RETROACTIVE',
          hint: 'Non-retroactivity of criminal law under Section 36 of the Constitution.',
        ),
        TriviaQuestion(
          scenario: 'A consumer buys a brand-new generator that blows up the next day due to a factory fault, but the seller points to a "No Refund After Purchase" sign. Is that sign valid?',
          answer: 'INVALID',
          hint: 'The FCCPA (Federal Consumer Protection Act) protects buyers against defective goods regardless of store notices.',
        ),
        TriviaQuestion(
          scenario: 'In a criminal trial in Nigeria, who bears the legal burden of proving that the defendant actually committed the crime beyond reasonable doubt?',
          answer: 'PROSECUTION',
          hint: 'The defendant is presumed innocent until proven guilty by the state or complainant.',
        ),
        TriviaQuestion(
          scenario: 'A loan app company sends embarrassing messages and photos to all your phone contacts because you missed a repayment deadline. What law does this violate?',
          answer: 'NDPA',
          hint: 'Violates the Nigeria Data Protection Act and fundamental constitutional privacy rights.',
        ),
        TriviaQuestion(
          scenario: 'What statutory registration body must you register a new business name or private limited company with in Nigeria?',
          answer: 'CAC',
          hint: 'Corporate Affairs Commission established under CAMA.',
        ),
      ],
    ),


    TriviaStage(
      stageTitle: 'Level 2: Cybercrime, Data Rights & Consumer Law',
      questions: [
        TriviaQuestion(
          scenario: 'A digital lending app accesses your phone contact list without your clear permission and sends defamatory messages to your contacts. What law does this violate?',
          answer: 'NDPA',
          hint: 'The Nigeria Data Protection Act 2023 prohibits unauthorized processing and harvesting of personal data.',
        ),
        TriviaQuestion(
          scenario: 'What statutory regulatory body is empowered to investigate data breaches, issue enforcement orders, and fine defaulting companies in Nigeria?',
          answer: 'NDPC',
          hint: 'Nigeria Data Protection Commission, established under the NDPA.',
        ),
        TriviaQuestion(
          scenario: 'You buy an electronic device online that stops working after 2 days. The seller points to a printed receipt stating "Goods Sold Are Not Returnable." Is this clause valid?',
          answer: 'INVALID',
          hint: 'Under the FCCPA, consumers have a statutory right to return defective goods regardless of seller disclaimers.',
        ),
        TriviaQuestion(
          scenario: 'What primary federal agency is tasked with enforcing fair competition, preventing price gouging, and protecting consumer rights in Nigeria?',
          answer: 'FCCPC',
          hint: 'Federal Competition and Consumer Protection Commission.',
        ),
        TriviaQuestion(
          scenario: 'An individual uses computer software to unauthorizedly intercept banking credentials and drain funds from victims’ accounts. What major Act criminalizes this?',
          answer: 'CYBERCRIME-ACT',
          hint: 'Cybercrimes (Prohibition, Prevention, Etc.) Act.',
        ),
        TriviaQuestion(
          scenario: 'Under the NDPA, what fundamental legal principle requires organizations to collect only the minimal personal data necessary for a specific purpose?',
          answer: 'DATA-MINIMIZATION',
          hint: 'Prevents entities from harvesting unnecessary personal details from users.',
        ),
        TriviaQuestion(
          scenario: 'You request an online service to permanently delete all your stored personal records and account history from their servers. What data right are you exercising?',
          answer: 'RIGHT-TO-ERASURE',
          hint: 'Also commonly referred to as the "Right to be Forgotten."',
        ),
        TriviaQuestion(
          scenario: 'An individual sends phishing emails pretending to be a bank official to trick victims into revealing their PINs. What specific crime is committed?',
          answer: 'IDENTITY-THEFT',
          hint: 'Also prosecuted as computer-related fraud under cybercrime legislation.',
        ),
        TriviaQuestion(
          scenario: 'Can a bank or merchant process your sensitive personal data (such as biometric fingerprints or facial scans) without obtaining your explicit consent or lawful basis?',
          answer: 'NO',
          hint: 'Processing sensitive personal data requires explicit consent or strict statutory exemptions.',
        ),
        TriviaQuestion(
          scenario: 'A flight gets cancelled by an airline without prior notice or emergency justification, leaving passengers stranded. Which consumer body can passengers report to for restitution?',
          answer: 'FCCPC',
          hint: 'Works alongside the NCAA to enforce consumer rights in aviation and transport.',
        ),
        TriviaQuestion(
          scenario: 'An internet service provider deliberately throttles your connection speed far below the advertised speed package you paid for. What right under consumer law is breached?',
          answer: 'SERVICE-QUALITY',
          hint: 'Consumers are entitled to services that meet contractual representations and quality standards.',
        ),
        TriviaQuestion(
          scenario: 'What is the legal term for a designated officer within an organization responsible for ensuring compliance with national data privacy laws?',
          answer: 'DPO',
          hint: 'Data Protection Officer.',
        ),
        TriviaQuestion(
          scenario: 'A person knowingly accesses a critical national computer system or database without authorization. What class of crime is this categorized as?',
          answer: 'CYBER-TERRORISM',
          hint: 'Unauthorized access to Critical National Information Infrastructure (CNII) carries severe penalties.',
        ),
        TriviaQuestion(
          scenario: 'You sign up for a web service, and they automatically opt you into receiving promotional SMS and third-party advertising by default. Is pre-ticked consent valid under NDPA?',
          answer: 'INVALID',
          hint: 'Consent must be freely given, specific, informed, and unambiguous (opt-in, not default opt-out).',
        ),
        TriviaQuestion(
          scenario: 'Under the NDPA, what is an individual whose personal data is being collected, stored, or processed called?',
          answer: 'DATA-SUBJECT',
          hint: 'The person to whom the personal data relates.',
        ),
        TriviaQuestion(
          scenario: 'What is the maximum timeline an individual has to withdraw their consent for data processing under standard data protection regulations?',
          answer: 'ANYTIME',
          hint: 'Data subjects retain the legal right to withdraw consent at any time without penalty.',
        ),
      ],
    ),


  ];

  int _currentQuestionIndex = 0;
  List<String?> _placedLetters = [];
  List<TileItem> _availableTiles = [];

  int _score = 0;
  int _timeLeft = 35;
  Timer? _timer;

  double _runnerPosition = 0.65;
  double _policePosition = 0.20;

  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);

    _loadQuestion(_currentQuestionIndex);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  TriviaStage get _stage => _allStages[widget.levelIndex];
  TriviaQuestion get _currentQuestion => _stage.questions[_currentQuestionIndex];

  void _loadQuestion(int qIdx) {
    final question = _stage.questions[qIdx];
    final cleanAnswer = question.answer.replaceAll(' ', '');
    _placedLetters = List<String?>.filled(cleanAnswer.length, null);

    List<String> chars = cleanAnswer.split('')..shuffle();
    _availableTiles = List.generate(
      chars.length,
          (i) => TileItem(id: i, letter: chars[i], isPlaced: false),
    );

    _runnerPosition = 0.65;
    _policePosition = 0.20;
    _timeLeft = 35;

    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_timeLeft > 0) {
          _timeLeft--;
          _policePosition += 0.012;
          if (_policePosition >= _runnerPosition) {
            _timer?.cancel();
            _showGameOverDialog(isCaptured: true);
          }
        } else {
          _timer?.cancel();
          _showGameOverDialog(isCaptured: true);
        }
      });
    });
  }

  void _onLetterPlaced(int slotIndex, TileItem tile) {
    setState(() {
      if (_placedLetters[slotIndex] != null) {
        final existingLetter = _placedLetters[slotIndex];
        final previousTileIndex = _availableTiles.indexWhere(
                (t) => t.isPlaced && t.letter == existingLetter);
        if (previousTileIndex != -1) {
          _availableTiles[previousTileIndex].isPlaced = false;
        }
      }

      _placedLetters[slotIndex] = tile.letter;
      tile.isPlaced = true;
    });

    _checkAnswer();
  }

  void _tapTileToFirstEmptySlot(TileItem tile) {
    final emptyIndex = _placedLetters.indexOf(null);
    if (emptyIndex != -1) {
      _onLetterPlaced(emptyIndex, tile);
    }
  }

  void _removeLetterFromSlot(int slotIndex) {
    if (_placedLetters[slotIndex] == null) return;

    final removedLetter = _placedLetters[slotIndex];
    setState(() {
      _placedLetters[slotIndex] = null;
      final tileIndex = _availableTiles
          .indexWhere((t) => t.isPlaced && t.letter == removedLetter);
      if (tileIndex != -1) {
        _availableTiles[tileIndex].isPlaced = false;
      }
    });
  }

  void _checkAnswer() {
    if (_placedLetters.contains(null)) return;

    final targetWord = _currentQuestion.answer.replaceAll(' ', '');
    final userWord = _placedLetters.join('');

    if (userWord == targetWord) {
      _timer?.cancel();
      setState(() {
        _score += 100 + (_timeLeft * 5);
        _runnerPosition = (_runnerPosition + 0.20).clamp(0.0, 0.90);
      });

      _showSuccessFeedback();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.redAccent,
          content: Text('Not quite right! Tap target slots to clear letters.'),
          duration: Duration(seconds: 1),
        ),
      );
      setState(() {
        _policePosition = (_policePosition + 0.08).clamp(0.0, _runnerPosition);
      });
    }
  }

  void _showSuccessFeedback() {
    showModalBottomSheet(
      context: context,
      backgroundColor: cardBackground,
      isDismissible: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.verified_rounded, color: Colors.greenAccent, size: 56),
            const SizedBox(height: 12),
            const Text(
              'RIGHT PRESERVED!',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Mastered: ${_currentQuestion.answer}',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 14),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  _advanceToNextQuestion();
                },
                child: const Text(
                  'Continue',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 100),

          ],
        ),
      ),
    );
  }

  void _advanceToNextQuestion() {
    if (_currentQuestionIndex < _stage.questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _loadQuestion(_currentQuestionIndex);
      });
    } else {
      _saveProgressAndFinish();
    }
  }

  Future<void> _saveProgressAndFinish() async {
    final docRef = FirebaseFirestore.instance
        .collection('game-data')
        .doc(widget.userId)
        .collection('gameData')
        .doc('legalTrivia');

    try {
      final snap = await docRef.get();
      int currentUnlocked = 0;
      Map<String, dynamic> highScores = {};

      if (snap.exists && snap.data() != null) {
        currentUnlocked = snap.data()!['unlockedLevel'] ?? 0;
        highScores = Map<String, dynamic>.from(snap.data()!['highScores'] ?? {});
      }

      int nextLevel = widget.levelIndex + 1;
      int updatedUnlocked = nextLevel > currentUnlocked ? nextLevel : currentUnlocked;

      int previousScore = highScores['level_${widget.levelIndex}'] ?? 0;
      if (_score > previousScore) {
        highScores['level_${widget.levelIndex}'] = _score;
      }

      await docRef.set({
        'unlockedLevel': updatedUnlocked.clamp(0, 9),
        'highScores': highScores,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (widget.onLevelCompleted != null) {
        widget.onLevelCompleted!();
      }

      _showGameOverDialog(isCaptured: false);
    } catch (e) {
      _showGameOverDialog(isCaptured: false);
    }
  }

  void _showGameOverDialog({required bool isCaptured}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Column(
          children: [
            Icon(
              isCaptured ? Icons.local_police_rounded : Icons.emoji_events_rounded,
              color: isCaptured ? Colors.redAccent : Colors.amber,
              size: 56,
            ),
            const SizedBox(height: 12),
            Text(
              isCaptured ? 'BUSTED!' : 'LEVEL COMPLETED!',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Text(
          isCaptured
              ? 'The police caught up to you before you could prove your rights!'
              : 'You completed Level ${widget.levelIndex + 1} with $_score points! Next level is now unlocked.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
        ),
        actions: [
          Center(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: Text(
                isCaptured ? 'Try Again' : 'Return to Levels',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: darkBackground,
      appBar: AppBar(
        backgroundColor: cardBackground,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Text(
          _stage.stageTitle,
          style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: primaryColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  'Score: $_score',
                  style: const TextStyle(
                    color: primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardBackground,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.timer_rounded, color: primaryColor, size: 18),
                          const SizedBox(width: 6),
                          Text(
                            'Time: ${_timeLeft}s',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'Q ${_currentQuestionIndex + 1}/${_stage.questions.length}',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  SizedBox(
                    height: 54,
                    width: double.infinity,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: Align(
                            alignment: Alignment.center,
                            child: Container(
                              height: 10,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                          ),
                        ),

                        AnimatedPositioned(
                          duration: const Duration(milliseconds: 300),
                          left: (size.width - 80) * _policePosition,
                          top: 4,
                          child: AnimatedBuilder(
                            animation: _animationController,
                            builder: (context, child) {
                              return Transform.translate(
                                offset: Offset(0, _animationController.value * -4),
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: const BoxDecoration(
                                    color: Colors.blueAccent,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.local_police_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),

                        AnimatedPositioned(
                          duration: const Duration(milliseconds: 300),
                          left: (size.width - 80) * _runnerPosition,
                          top: 4,
                          child: AnimatedBuilder(
                            animation: _animationController,
                            builder: (context, child) {
                              return Transform.translate(
                                offset: Offset(0, (1 - _animationController.value) * -5),
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: const BoxDecoration(
                                    color: primaryColor,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.directions_run_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: cardBackground,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: primaryColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Legal Scenario',
                            style: TextStyle(
                              color: primaryColor,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _currentQuestion.scenario,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            height: 1.45,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Hint: ${_currentQuestion.hint}',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.45),
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: List.generate(
                  _placedLetters.length,
                      (index) {
                    final letter = _placedLetters[index];
                    return DragTarget<TileItem>(
                      onAcceptWithDetails: (details) {
                        _onLetterPlaced(index, details.data);
                      },
                      builder: (context, candidateData, rejectedData) {
                        return GestureDetector(
                          onTap: () => _removeLetterFromSlot(index),
                          child: Container(
                            width: 42,
                            height: 50,
                            decoration: BoxDecoration(
                              color: letter != null
                                  ? primaryColor.withValues(alpha: 0.2)
                                  : darkBackground,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: candidateData.isNotEmpty
                                    ? primaryColor
                                    : letter != null
                                    ? primaryColor
                                    : Colors.white.withValues(alpha: 0.2),
                                width: 1.5,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                letter ?? '',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),

            const SizedBox(height: 20),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  Text(
                    'Tap or drag letters to complete the answer:',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: _availableTiles.map((tile) {
                      if (tile.isPlaced) {
                        return SizedBox(
                          width: 44,
                          height: 44,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.03),
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        );
                      }

                      return Draggable<TileItem>(
                        data: tile,
                        feedback: Material(
                          color: Colors.transparent,
                          child: _buildLetterTile(tile.letter, isDragging: true),
                        ),
                        childWhenDragging: Opacity(
                          opacity: 0.3,
                          child: _buildLetterTile(tile.letter),
                        ),
                        child: GestureDetector(
                          onTap: () => _tapTileToFirstEmptySlot(tile),
                          child: _buildLetterTile(tile.letter),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildLetterTile(String letter, {bool isDragging = false}) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDragging ? primaryColor : Colors.white.withValues(alpha: 0.15),
          width: isDragging ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          letter,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}