import 'package:flutter/material.dart';

// --- DATA MODELS ---

class CivicQuestion {
  final String id;
  final String prompt;
  final List<CivicOption> options;
  final String legalExplanation;
  final String constitutionReference;

  const CivicQuestion({
    required this.id,
    required this.prompt,
    required this.options,
    required this.legalExplanation,
    required this.constitutionReference,
  });
}

class CivicOption {
  final String optionId;
  final String text;
  final String subtitle;
  final bool isCorrect;
  final IconData icon;

  const CivicOption({
    required this.optionId,
    required this.text,
    required this.subtitle,
    required this.isCorrect,
    required this.icon,
  });
}

class LevelModel {
  final int levelNumber;
  final String title;
  final bool isUnlocked;
  final bool isCompleted;

  const LevelModel({
    required this.levelNumber,
    required this.title,
    required this.isUnlocked,
    required this.isCompleted,
  });
}

// --- MAIN GAME CONTAINER ---

class CivicGameContainer extends StatefulWidget {
  const CivicGameContainer({super.key});

  @override
  State<CivicGameContainer> createState() => _CivicGameContainerState();
}

class _CivicGameContainerState extends State<CivicGameContainer> {
  int _currentStep = 0; // 0: Map, 1: Scenario Intro, 2: Choice, 3: Feedback, 4: Reward
  int _userPoints = 120;
  CivicOption? _selectedOption;

  final CivicQuestion _currentQuestion = const CivicQuestion(
    id: 'q1',
    prompt:
    'Officer says: "Young man, unlock your phone, let me search your WhatsApp messages."',
    options: [
      CivicOption(
        optionId: 'A',
        text: 'Comply immediately',
        subtitle: 'Safe Route?',
        isCorrect: false,
        icon: Icons.phone_android_rounded,
      ),
      CivicOption(
        optionId: 'B',
        text: 'Politely refuse and record',
        subtitle: 'Assert Rights',
        isCorrect: true,
        icon: Icons.videocam_outlined,
      ),
      CivicOption(
        optionId: 'C',
        text: 'Ask for a search warrant or legal basis.',
        subtitle: 'Legal Basis',
        isCorrect: false,
        icon: Icons.gavel_rounded,
      ),
    ],
    legalExplanation:
    'An officer must have specific legal basis or warrant to search your digital device.',
    constitutionReference:
    'Section 37, 1999 Constitution protects your right to privacy in correspondence.',
  );

  void _onOptionSelected(CivicOption option) {
    setState(() {
      _selectedOption = option;
      if (option.isCorrect) {
        _userPoints += 20;
      }
      _currentStep = 3; // Move to Feedback Screen
    });
  }

  void _resetGame() {
    setState(() {
      _currentStep = 0;
      _selectedOption = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD4E7DC), // Soft light green theme
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _buildCurrentScreen(),
        ),
      ),
    );
  }

  Widget _buildCurrentScreen() {
    switch (_currentStep) {
      case 0:
        return _CivicJourneyMap(
          points: _userPoints,
          onStartLevel1: () => setState(() => _currentStep = 1),
        );
      case 1:
        return _ScenarioIntroScreen(
          question: _currentQuestion,
          points: _userPoints,
          onContinue: () => setState(() => _currentStep = 2),
        );
      case 2:
        return _MakeChoiceScreen(
          question: _currentQuestion,
          points: _userPoints,
          onOptionSelected: _onOptionSelected,
        );
      case 3:
        return _FeedbackScreen(
          selectedOption: _selectedOption!,
          question: _currentQuestion,
          points: _userPoints,
          onNext: () => setState(() => _currentStep = 4),
        );
      case 4:
        return _LevelCompletedScreen(
          points: _userPoints,
          onDone: _resetGame,
        );
      default:
        return Container();
    }
  }
}

// ==========================================
// SCREEN 1: CIVIC JOURNEY MAP
// ==========================================

class _CivicJourneyMap extends StatelessWidget {
  final int points;
  final VoidCallback onStartLevel1;

  const _CivicJourneyMap({
    required this.points,
    required this.onStartLevel1,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(points),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            children: [
              _buildMapNode(
                title: 'Citizen Champion',
                isUnlocked: false,
                isCurrent: false,
                icon: Icons.lock_outline_rounded,
                alignRight: false,
              ),
              _buildDottedPath(),
              _buildMapNode(
                title: 'Market Hustler',
                isUnlocked: false,
                isCurrent: false,
                icon: Icons.storefront_rounded,
                alignRight: true,
              ),
              _buildDottedPath(),
              _buildMapNode(
                title: 'Independent Tenant',
                isUnlocked: false,
                isCurrent: false,
                icon: Icons.home_work_outlined,
                alignRight: false,
              ),
              _buildDottedPath(),
              _buildMapNode(
                title: 'Level 1: Street Smart',
                isUnlocked: true,
                isCurrent: true,
                icon: Icons.verified_user_rounded,
                alignRight: true,
                onTap: onStartLevel1,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMapNode({
    required String title,
    required bool isUnlocked,
    required bool isCurrent,
    required IconData icon,
    required bool alignRight,
    VoidCallback? onTap,
  }) {
    final nodeWidget = GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isCurrent
                  ? const Color(0xFF63A076)
                  : (isUnlocked ? Colors.white : Colors.grey[400]),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              icon,
              color: isCurrent || !isUnlocked ? Colors.white : Colors.black87,
              size: 28,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2E4032),
              ),
            ),
          ),
        ],
      ),
    );

    return Align(
      alignment: alignRight ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: nodeWidget,
      ),
    );
  }

  Widget _buildDottedPath() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Center(
        child: Container(
          height: 30,
          width: 2,
          color: Colors.green.withOpacity(0.4),
        ),
      ),
    );
  }

  Widget _buildHeader(int points) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.transparent,
      child: Column(
        children: [
          const Text(
            'Civic Journey Map',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E2E21),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircleAvatar(
                  radius: 18,
                  backgroundColor: Color(0xFF63A076),
                  child: Icon(Icons.person, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Emeka',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      'Lv. 1  •  $points Points',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// SCREEN 2: SCENARIO INTRO
// ==========================================

class _ScenarioIntroScreen extends StatelessWidget {
  final CivicQuestion question;
  final int points;
  final VoidCallback onContinue;

  const _ScenarioIntroScreen({
    required this.question,
    required this.points,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Scenario Graphic Representation
        Positioned.fill(
          child: Column(
            children: [
              const SizedBox(height: 20),
              _buildUserProfileBadge(),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    question.prompt,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E2E21),
                    ),
                  ),
                ),
              ),
              const Spacer(),
              // Simulated Cartoon Illustration / Graphic Area
              Container(
                height: 220,
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 24),
                decoration: BoxDecoration(
                  color: const Color(0xFFB0D2C1),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white, width: 3),
                ),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.local_police_rounded,
                          size: 64, color: Color(0xFF1E2E21)),
                      SizedBox(height: 8),
                      Chip(
                        label: Text('Lagos Checkpoint',
                            style: TextStyle(color: Colors.white)),
                        backgroundColor: Color(0xFF2E4032),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: onContinue,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E4032),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'What should Emeka do?',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUserProfileBadge() {
    return Row(
      children: [
        const SizedBox(width: 24),
        const CircleAvatar(
          radius: 16,
          backgroundColor: Color(0xFF63A076),
          child: Icon(Icons.person, color: Colors.white, size: 18),
        ),
        const SizedBox(width: 8),
        const Text(
          'Emeka',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            '$points Points',
            style: const TextStyle(
                color: Color(0xFF2E4032), fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: 24),
      ],
    );
  }
}

// ==========================================
// SCREEN 3: MAKING A CHOICE
// ==========================================

class _MakeChoiceScreen extends StatelessWidget {
  final CivicQuestion question;
  final int points;
  final ValueChanged<CivicOption> onOptionSelected;

  const _MakeChoiceScreen({
    required this.question,
    required this.points,
    required this.onOptionSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const BackButton(),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '$points Points',
                  style: const TextStyle(
                    color: Color(0xFF2E4032),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            question.prompt,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E2E21),
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: ListView.separated(
              itemCount: question.options.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final option = question.options[index];
                return GestureDetector(
                  onTap: () => onOptionSelected(option),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.white),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F2EC),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(option.icon,
                              color: const Color(0xFF2E4032)),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${option.optionId}) ${option.text}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Color(0xFF1E2E21),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '(${option.subtitle})',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// SCREEN 4: INSTANT FEEDBACK & LEARNING
// ==========================================

class _FeedbackScreen extends StatelessWidget {
  final CivicOption selectedOption;
  final CivicQuestion question;
  final int points;
  final VoidCallback onNext;

  const _FeedbackScreen({
    required this.selectedOption,
    required this.question,
    required this.points,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final bool isCorrect = selectedOption.isCorrect;

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          _buildTopBar(),
          const SizedBox(height: 24),
          Icon(
            isCorrect ? Icons.celebration_rounded : Icons.info_outline_rounded,
            size: 60,
            color: isCorrect ? const Color(0xFF388E3C) : Colors.orange[800],
          ),
          const SizedBox(height: 12),
          Text(
            isCorrect ? 'Correct!\nRight Answer!' : 'Not Quite Right!',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E2E21),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              isCorrect ? '+20 Points' : '+0 Points',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF388E3C),
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Legal Explanation Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Why this is correct:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Color(0xFF1E2E21),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.menu_book_rounded,
                        color: Color(0xFF388E3C), size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        question.constitutionReference,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2E4032),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.verified_outlined,
                        color: Color(0xFF388E3C), size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        question.legalExplanation,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: onNext,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E4032),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'Next Challenge',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const CircleAvatar(
          radius: 16,
          backgroundColor: Color(0xFF63A076),
          child: Icon(Icons.person, color: Colors.white, size: 18),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            '+20 Points',
            style: const TextStyle(
              color: Color(0xFF388E3C),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}

// ==========================================
// SCREEN 5: REWARDS & NEXT STEPS
// ==========================================

class _LevelCompletedScreen extends StatelessWidget {
  final int points;
  final VoidCallback onDone;

  const _LevelCompletedScreen({
    required this.points,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const SizedBox(height: 32),
              const Text(
                'Congratulations',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E2E21),
                ),
              ),
              const SizedBox(height: 24),
              const Icon(Icons.workspace_premium_rounded,
                  size: 80, color: Colors.amber),
              const SizedBox(height: 16),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Level 1: Street Smart Completed!',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E4032),
                  ),
                ),
              ),
              const Spacer(),
              // Bottom Action Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const CircleAvatar(
                          radius: 18,
                          backgroundColor: Color(0xFF63A076),
                          child: Icon(Icons.person, color: Colors.white),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Emeka',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text('Lv. 2  •  $points Points',
                                style: TextStyle(
                                    color: Colors.grey[600], fontSize: 12)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: onDone,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E4032),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text('Explore Level 2',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F2EC),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.gavel_rounded, color: Color(0xFF2E4032)),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Need Real Legal Help?',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12),
                                ),
                                Text(
                                  'Connect with a Human Rights Lawyer Near You.',
                                  style: TextStyle(
                                      fontSize: 10, color: Colors.black54),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}