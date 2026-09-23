import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'legal_trivia_game_screen.dart';

class LevelSelectionScreen extends StatelessWidget {
  final String userId;

  const LevelSelectionScreen({super.key, required this.userId});

  static const Color primaryColor = Color(0xFFE66C75);
  static const Color darkBackground = Color(0xFF111318);
  static const Color cardBackground = Color(0xFF1A1D24);

  static const List<String> _levelTitles = [
    'Everyday Law & Street Rights',
    'Cybercrime, Data Rights & Consumer Law',

  ];

  @override
  Widget build(BuildContext context) {
    final docRef = FirebaseFirestore.instance
        .collection('game-data')
        .doc(userId)
        .collection('gameData')
        .doc('legalTrivia');

    return Scaffold(
      backgroundColor: darkBackground,
      appBar: AppBar(
        backgroundColor: cardBackground,
        elevation: 0,
        title: const Text(
          'Legal Trivia - Select Stage',
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white, size: 20),
          onPressed: () => Navigator.maybePop(context),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: docRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: primaryColor));
          }

          int unlockedLevel = 0;
          Map<String, dynamic> highScores = {};

          if (snapshot.hasData && snapshot.data!.exists && snapshot.data!.data() != null) {
            final data = snapshot.data!.data() as Map<String, dynamic>;
            unlockedLevel = data['unlockedLevel'] ?? 0;
            highScores = Map<String, dynamic>.from(data['highScores'] ?? {});
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: 1.1,
            ),
            itemCount: 2,
            itemBuilder: (context, index) {
              final bool isUnlocked = index <= unlockedLevel;
              final int score = highScores['level_$index'] ?? 0;

              return InkWell(
                onTap: isUnlocked
                    ? () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => LegalTriviaGameScreen(
                        levelIndex: index,
                        userId: userId,
                      ),
                    ),
                  );
                }
                    : () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Complete previous levels to unlock this stage!'),
                      backgroundColor: Colors.orangeAccent,
                    ),
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: isUnlocked ? cardBackground : cardBackground.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isUnlocked ? primaryColor.withValues(alpha: 0.4) : Colors.white10,
                      width: isUnlocked ? 1.5 : 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isUnlocked ? Icons.lock_open_rounded : Icons.lock_rounded,
                        color: isUnlocked ? primaryColor : Colors.white30,
                        size: 32,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Level ${index + 1}',
                        style: TextStyle(
                          color: isUnlocked ? Colors.white : Colors.white30,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _levelTitles[index],
                        style: TextStyle(
                          color: isUnlocked ? Colors.white70 : Colors.white24,
                          fontSize: 11,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (score > 0) ...[
                        const SizedBox(height: 6),
                        Text(
                          'Best: $score pts',
                          style: const TextStyle(
                            color: Colors.greenAccent,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}