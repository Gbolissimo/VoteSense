import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:vote_sense/screens/home/recent_legal_screen.dart';
import '../../models/recent_legal_item.dart';
import '../../utils/globals.dart';
import '../auth/landing_screen.dart';
import '../auth/setup_profile_screen.dart';
import '../chat/claim_verification_screen.dart';
import '../chat/ai_chat_screen.dart';
import '../messaging/chat_list_screen.dart';
import '../profile/my_profile_screen.dart';
import '../trivia/level_selection_screen.dart';
import 'legal_item_detail_screen.dart';
import 'notifications_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() =>
      _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentBottomNavIndex = 0;

  User? loggedUser;
  bool _isLoadingAuth = true;

  static const Color primaryColor =
  Color(0xFF22C55E);

  static const Color lightBackground =
  Color(0xFFF8FAFC);

  static const Color cardBackground =
      Colors.white;

  static const Color primaryText =
  Color(0xFF1E293B);

  static const Color secondaryText =
  Color(0xFF64748B);

  static const Color mutedText =
  Color(0xFF94A3B8);

  final PageController _assistantPageController = PageController();
  Timer? _assistantAutoSlideTimer;
  int _currentAssistantPage = 0;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuthAndRedirect();
    });

    _startAssistantAutoSlide();

  }

  @override
  void dispose() {
    _assistantAutoSlideTimer?.cancel();
    _assistantPageController.dispose();
    super.dispose();
  }

  void _startAssistantAutoSlide() {
    _assistantAutoSlideTimer = Timer.periodic(
      const Duration(seconds: 10),
          (_) {
        if (!_assistantPageController.hasClients) return;

        final nextPage = _currentAssistantPage == 0 ? 1 : 0;

        _assistantPageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      },
    );
  }

  // ===========================================================================
  // AUTH
  // ===========================================================================

  Future<void> _checkAuthAndRedirect() async {
    try {
      final user =
          FirebaseAuth.instance.currentUser;

      if (user == null) {
        if (!mounted) return;

        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) =>
            const LandingScreen(),
          ),
              (route) => false,
        );

        return;
      }

      final exists =
      await userExists(user.uid);

      if (!mounted) return;

      if (exists) {
        setState(() {
          loggedUser = user;
          globalUid = user.uid;
          _isLoadingAuth = false;
        });

        _updateLoginTime(user.uid);
      } else {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) =>
            const SetupProfileScreen(),
          ),
              (route) => false,
        );
      }
    } catch (e) {
      debugPrint(
        'Auth check failed: $e',
      );

      if (!mounted) return;

      setState(() {
        _isLoadingAuth = false;
      });
    }
  }

  Future<bool> userExists(String uid) async {
    if (uid.isEmpty) return false;

    try {
      final snapshot =
      await FirebaseFirestore.instance
          .collection('new-users')
          .where(
        'uid',
        isEqualTo: uid,
      )
          .limit(1)
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      debugPrint(
        'Failed to check user existence: $e',
      );

      return false;
    }
  }

  Future<void> _updateLoginTime(
      String docId,
      ) async {
    try {
      final fcmToken =
      await FirebaseMessaging.instance
          .getToken();

      await FirebaseFirestore.instance
          .collection('new-users')
          .doc(docId)
          .update({
        'updatedAt':
        FieldValue.serverTimestamp(),
        'logs':
        FieldValue.increment(1),
        if (fcmToken != null &&
            fcmToken.isNotEmpty)
          'fcmToken': fcmToken,
      });
    } catch (e) {
      debugPrint(
        'Failed to update login time: $e',
      );
    }
  }

  // ===========================================================================
  // NAVIGATION
  // ===========================================================================

  Future<void> _navigateTo(
      Widget screen,
      ) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => screen,
      ),
    );

    if (!mounted) return;

    setState(() {
      _currentBottomNavIndex = 0;
    });
  }

  void _onBottomNavTapped(int index) {
    setState(() {
      _currentBottomNavIndex = index;
    });

    switch (index) {
      case 0:
        break;

      case 1:
        _navigateTo(
          const AIChatScreen(),
        );
        break;

      case 2:
        _navigateTo(
          const ClaimVerificationScreen(),
        );
        break;

      case 3:
        _navigateTo(
          const MyProfileScreen(),
        );
        break;
    }
  }

  // ===========================================================================
  // HELPERS
  // ===========================================================================

  Uint8List? _safeBase64Decode(
      String rawBase64,
      ) {
    if (rawBase64.isEmpty) return null;

    try {
      final cleanBase64 =
      rawBase64.contains(',')
          ? rawBase64.split(',').last.trim()
          : rawBase64.trim();

      return base64Decode(cleanBase64);
    } catch (e) {
      debugPrint(
        'Failed to decode profile image: $e',
      );

      return null;
    }
  }

  Widget _buildIconButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: cardBackground,
        borderRadius:
        BorderRadius.circular(12),
        border: Border.all(
          color: Colors.black
              .withValues(alpha: 0.08),
        ),
      ),
      child: IconButton(
        icon: Icon(
          icon,
          color: primaryText,
          size: 20,
        ),
        onPressed: onPressed,
      ),
    );
  }

  // ===========================================================================
  // PROFILE HEADER
  // ===========================================================================

  Widget _buildProfileHeader(
      User currentUser,
      ) {
    return SliverToBoxAdapter(
      child: Padding(
        padding:
        const EdgeInsets.fromLTRB(
          20,
          16,
          20,
          0,
        ),
        child: Row(
          mainAxisAlignment:
          MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () {
                  _navigateTo(
                    const MyProfileScreen(),
                  );
                },
                child:
                StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore
                      .instance
                      .collection('new-users')
                      .doc(currentUser.uid)
                      .snapshots(),
                  builder:
                      (context, snapshot) {
                    String firstName =
                        'User';

                    String lastName = '';

                    String rawPhotoData =
                        '';

                    if (snapshot.hasData &&
                        snapshot.data!.exists) {
                      final rawData =
                      snapshot.data!.data();

                      if (rawData
                      is Map<String, dynamic>) {
                        final data =
                            rawData;

                        firstName =
                            data['firstName']
                                ?.toString() ??
                                'User';

                        lastName =
                            data['lastName']
                                ?.toString() ??
                                '';

                        rawPhotoData =
                            data[
                            'profilePicture']
                                ?.toString() ??
                                data['photoUrl']
                                    ?.toString() ??
                                data['photoURL']
                                    ?.toString() ??
                                '';

                        globalStatus =
                        data['status'];

                        globalName =
                            '${data['firstName'] ?? ''} '
                                '${data['lastName'] ?? ''}'
                                .trim();

                        globalFirstName =
                            data['firstName']
                                ?.toString() ??
                                '';
                      }
                    } else {
                      if (currentUser
                          .displayName !=
                          null &&
                          currentUser
                              .displayName!
                              .trim()
                              .isNotEmpty) {
                        final parts =
                        currentUser
                            .displayName!
                            .trim()
                            .split(' ');

                        firstName =
                        parts.isNotEmpty
                            ? parts.first
                            : 'User';

                        lastName =
                        parts.length > 1
                            ? parts
                            .sublist(1)
                            .join(' ')
                            : '';
                      }

                      rawPhotoData =
                          currentUser.photoURL ??
                              '';
                    }

                    final isNetworkUrl =
                        rawPhotoData.startsWith(
                            'http://') ||
                            rawPhotoData.startsWith(
                                'https://');

                    final base64Bytes =
                    isNetworkUrl
                        ? null
                        : _safeBase64Decode(
                      rawPhotoData,
                    );

                    return Row(
                      children: [
                        ClipRRect(
                          borderRadius:
                          BorderRadius
                              .circular(
                            22,
                          ),
                          child: Container(
                            width: 44,
                            height: 44,
                            color: primaryColor
                                .withValues(
                              alpha: 0.12,
                            ),
                            child: isNetworkUrl
                                ? Image.network(
                              rawPhotoData,
                              fit: BoxFit
                                  .cover,
                              errorBuilder:
                                  (
                                  context,
                                  error,
                                  stackTrace,
                                  ) {
                                return const Icon(
                                  Icons
                                      .person_rounded,
                                  color:
                                  primaryColor,
                                  size: 24,
                                );
                              },
                            )
                                : base64Bytes !=
                                null
                                ? Image.memory(
                              base64Bytes,
                              fit: BoxFit
                                  .cover,
                              errorBuilder:
                                  (
                                  context,
                                  error,
                                  stackTrace,
                                  ) {
                                return const Icon(
                                  Icons
                                      .person_rounded,
                                  color:
                                  primaryColor,
                                  size:
                                  24,
                                );
                              },
                            )
                                : const Icon(
                              Icons
                                  .person_rounded,
                              color:
                              primaryColor,
                              size: 24,
                            ),
                          ),
                        ),
                        const SizedBox(
                          width: 12,
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                            CrossAxisAlignment
                                .start,
                            children: [
                              const Text(
                                'Welcome',
                                style:
                                TextStyle(
                                  color:
                                  secondaryText,
                                  fontSize:
                                  12,
                                ),
                              ),
                              const SizedBox(
                                height: 2,
                              ),
                              Text(
                                firstName,
                                style:
                                const TextStyle(
                                  color:
                                  primaryText,
                                  fontSize:
                                  17,
                                  fontWeight:
                                  FontWeight
                                      .bold,
                                ),
                                maxLines: 1,
                                overflow:
                                TextOverflow
                                    .ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
            const SizedBox(width: 12),
            Row(
              mainAxisSize:
              MainAxisSize.min,
              children: [
                _buildIconButton(
                  icon: Icons
                      .notifications_none_rounded,
                  onPressed: () {
                    _navigateTo(
                      const NotificationsScreen(),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // ELECTION COUNTDOWN
  // ===========================================================================

  Widget _buildElectionCountdown() {
    return SliverToBoxAdapter(
      child:
      StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection(
          'election_settings',
        )
            .doc('current')
            .snapshots(),
        builder:
            (context, snapshot) {
          // Loading
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return Padding(
              padding:
              const EdgeInsets.fromLTRB(
                20,
                20,
                20,
                0,
              ),
              child:
              _buildCountdownLoading(),
            );
          }

          // Error
          if (snapshot.hasError) {
            debugPrint(
              'Election countdown error: '
                  '${snapshot.error}',
            );

            return const SizedBox.shrink();
          }

          // Document doesn't exist
          if (!snapshot.hasData ||
              !snapshot.data!.exists) {
            debugPrint(
              'Election countdown document '
                  'does not exist.',
            );

            return const SizedBox.shrink();
          }

          final rawData =
          snapshot.data!.data();

          if (rawData
          is! Map<String, dynamic>) {
            return const SizedBox.shrink();
          }

          final data = rawData;

          // Check if countdown is active
          final isActive =
              data['isActive'] == true;

          if (!isActive) {
            return const SizedBox.shrink();
          }

          final title =
              data['title']
                  ?.toString() ??
                  '2027 General Election';

          final subtitle =
              data['subtitle']
                  ?.toString() ??
                  'Countdown to Election Day';

          final dynamic dateValue =
          data['date'];

          DateTime? electionDate;

          if (dateValue is Timestamp) {
            electionDate =
                dateValue.toDate();
          } else if (dateValue
          is DateTime) {
            electionDate = dateValue;
          } else if (dateValue
          is String) {
            electionDate =
                DateTime.tryParse(
                  dateValue,
                );
          }

          if (electionDate == null) {
            debugPrint(
              'Election date is missing '
                  'or invalid.',
            );

            return const SizedBox.shrink();
          }

          return Padding(
            padding:
            const EdgeInsets.fromLTRB(
              20,
              20,
              20,
              0,
            ),
            child:
            _ElectionCountdownCard(
              title: title,
              subtitle: subtitle,
              electionDate:
              electionDate,
              primaryColor:
              primaryColor,
            ),
          );
        },
      ),
    );
  }

  Widget _buildCountdownLoading() {
    return Container(
      width: double.infinity,
      height: 145,
      decoration: BoxDecoration(
        color: cardBackground,
        borderRadius:
        BorderRadius.circular(20),
        border: Border.all(
          color: Colors.black
              .withValues(alpha: 0.06),
        ),
      ),
      child: const Center(
        child:
        CircularProgressIndicator(
          color: primaryColor,
          strokeWidth: 2,
        ),
      ),
    );
  }

  // ===========================================================================
  // AI ASSISTANT
  // ===========================================================================

  Widget _buildAIAssistantBanner() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
        child: Column(
          children: [
            SizedBox(
              height: 160,
              child: PageView(
                controller: _assistantPageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentAssistantPage = index;
                  });
                },
                children: [
                  _buildAssistantCard(),
                  _buildVerifyClaimCard(),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // Page indicators
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                2,
                    (index) {
                  final bool active =
                      _currentAssistantPage == index;

                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: active ? 18 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: active
                          ? primaryColor
                          : primaryColor.withValues(alpha: 0.20),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssistantCard() {
    return GestureDetector(
      onTap: () => _navigateTo(
        const AIChatScreen(),
      ),
      child: Container(
        margin: const EdgeInsets.only(right: 2),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cardBackground,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: primaryColor.withValues(alpha: 0.30),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.auto_awesome_rounded,
                        color: primaryColor,
                        size: 14,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'VoteSense AI',
                        style: TextStyle(
                          color: primaryColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_rounded,
                  color: Color(0xFF64748B),
                  size: 18,
                ),
              ],
            ),
            SizedBox(height: 15,),
            const Text(
              'Your intelligent civic guide',
              style: TextStyle(
                color: Color(0xFF1E293B),
                fontSize: 17,
                fontWeight: FontWeight.bold,
                height: 1.3,
              ),
            ),

            const SizedBox(height: 5),

            const Text(
              'Ask questions about elections, voting rights and civic responsibilities.',
              style: TextStyle(
                color: Color(0xFF64748B),
                fontSize: 13,
                height: 1.35,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerifyClaimCard() {
    return GestureDetector(
      onTap: () => _navigateTo(
        const ClaimVerificationScreen(),
      ),
      child: Container(
        margin: const EdgeInsets.only(right: 2),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cardBackground,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: primaryColor.withValues(alpha: 0.30),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.fact_check_rounded,
                        color: primaryColor,
                        size: 14,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Verify a Claim',
                        style: TextStyle(
                          color: primaryColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_rounded,
                  color: Color(0xFF64748B),
                  size: 18,
                ),
              ],
            ),

            SizedBox(height: 15,),

            const Text(
              'Is that election claim true?',
              style: TextStyle(
                color: Color(0xFF1E293B),
                fontSize: 17,
                fontWeight: FontWeight.bold,
                height: 1.3,
              ),
            ),

            const SizedBox(height: 5),

            const Text(
              'Check election-related claims and get evidence-based context before you share.',
              style: TextStyle(
                color: Color(0xFF64748B),
                fontSize: 13,
                height: 1.35,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
  // ===========================================================================
  // QUICK ACCESS
  // ===========================================================================

  Widget _buildQuickAccess(
      User currentUser,
      ) {
    return SliverToBoxAdapter(
      child: Padding(
        padding:
        const EdgeInsets.fromLTRB(
          20,
          28,
          20,
          0,
        ),
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            const Text(
              'Quick Access',
              style: TextStyle(
                color: primaryText,
                fontSize: 18,
                fontWeight:
                FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics:
              const NeverScrollableScrollPhysics(),
              crossAxisCount: 4,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.85,
              children: [
                _QuickAccessItem(
                  label: 'Polling Units',
                  icon:
                  Icons.radar_rounded,
                  onTap: () {
                    _navigateTo(
                      const ClaimVerificationScreen(),
                    );
                  },
                ),
                _QuickAccessItem(
                  label: 'Civic Trivia',
                  icon: Icons
                      .sports_esports_rounded,
                  onTap: () {
                    _navigateTo(
                      LevelSelectionScreen(
                        userId:
                        currentUser.uid,
                      ),
                    );
                  },
                ),
                _QuickAccessItem(
                  label: 'Messages',
                  icon:
                  Icons.chat_rounded,
                  onTap: () {
                    _navigateTo(
                      ChatListScreen(
                        currentUserId:
                        currentUser.uid,
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // NEWS HEADER
  // ===========================================================================

  Widget _buildNewsHeader() {
    return SliverToBoxAdapter(
      child: Padding(
        padding:
        const EdgeInsets.fromLTRB(
          20,
          28,
          20,
          12,
        ),
        child: Row(
          mainAxisAlignment:
          MainAxisAlignment
              .spaceBetween,
          children: [
            const Expanded(
              child: Text(
                'Recent Election News',
                style: TextStyle(
                  color: primaryText,
                  fontSize: 18,
                  fontWeight:
                  FontWeight.bold,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                _navigateTo(
                  const RecentLegalScreen(),
                );
              },
              child: const Text(
                'See All',
                style: TextStyle(
                  color: primaryColor,
                  fontSize: 14,
                  fontWeight:
                  FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // ELECTION NEWS
  // ===========================================================================

  Widget _buildElectionNews() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('election_news')
          .orderBy(
        'fetchedAt',
        descending: true,
      )
          .limit(5)
          .snapshots(),
      builder:
          (context, snapshot) {
        debugPrint(
          'Election news connection: '
              '${snapshot.connectionState}',
        );

        debugPrint(
          'Election news error: '
              '${snapshot.error}',
        );

        debugPrint(
          'Election news document count: '
              '${snapshot.data?.docs.length ?? 0}',
        );

        if (snapshot.hasError) {
          return SliverToBoxAdapter(
            child: Padding(
              padding:
              const EdgeInsets.symmetric(
                horizontal: 20,
              ),
              child: Container(
                width: double.infinity,
                padding:
                const EdgeInsets.all(
                  16,
                ),
                decoration:
                BoxDecoration(
                  color: Colors.red
                      .withValues(
                    alpha: 0.06,
                  ),
                  borderRadius:
                  BorderRadius.circular(
                    16,
                  ),
                  border: Border.all(
                    color: Colors.red
                        .withValues(
                      alpha: 0.15,
                    ),
                  ),
                ),
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons
                              .error_outline_rounded,
                          color: Colors.red,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Unable to load election news',
                          style:
                          TextStyle(
                            color:
                            Colors.red,
                            fontWeight:
                            FontWeight
                                .w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(
                      height: 8,
                    ),
                    Text(
                      '${snapshot.error}',
                      style:
                      const TextStyle(
                        color: Colors.red,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const SliverToBoxAdapter(
            child: Padding(
              padding:
              EdgeInsets.symmetric(
                vertical: 20,
              ),
              child: Center(
                child:
                CircularProgressIndicator(
                  color: primaryColor,
                ),
              ),
            ),
          );
        }

        final docs =
            snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return const SliverToBoxAdapter(
            child: Padding(
              padding:
              EdgeInsets.fromLTRB(
                20,
                10,
                20,
                20,
              ),
              child: Center(
                child: Text(
                  'No recent updates found.',
                  style: TextStyle(
                    color: mutedText,
                  ),
                ),
              ),
            ),
          );
        }

        final List<RecentLegalItem>
        items = [];

        for (final doc in docs) {
          try {
            final item =
            RecentLegalItem
                .fromFirestore(doc);

            items.add(item);

            debugPrint(
              'Election news loaded: '
                  '${item.title}',
            );
          } catch (e, stackTrace) {
            debugPrint(
              'Failed to parse election news '
                  '${doc.id}: $e',
            );

            debugPrint(
              '$stackTrace',
            );
          }
        }

        if (items.isEmpty) {
          return const SliverToBoxAdapter(
            child: Padding(
              padding:
              EdgeInsets.all(20),
              child: Center(
                child: Text(
                  'Unable to display election news.',
                  style: TextStyle(
                    color: mutedText,
                  ),
                ),
              ),
            ),
          );
        }

        return SliverList(
          delegate:
          SliverChildBuilderDelegate(
                (context, index) {
              return _buildNewsCard(
                items[index],
              );
            },
            childCount: items.length,
          ),
        );
      },
    );
  }

  // ===========================================================================
  // NEWS CARD
  // ===========================================================================

  Widget _buildNewsCard(
      RecentLegalItem item,
      ) {
    return Padding(
      padding:
      const EdgeInsets.fromLTRB(
        20,
        0,
        20,
        12,
      ),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  LegalItemDetailScreen(
                    item: item,
                  ),
            ),
          );
        },
        child: Container(
          padding:
          const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardBackground,
            borderRadius:
            BorderRadius.circular(16),
            border: Border.all(
              color: Colors.black
                  .withValues(alpha: 0.08),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black
                    .withValues(
                  alpha: 0.02,
                ),
                blurRadius: 6,
                offset:
                const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              Container(
                padding:
                const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: primaryColor
                      .withValues(
                    alpha: 0.12,
                  ),
                  borderRadius:
                  BorderRadius.circular(
                    12,
                  ),
                ),
                child: const Icon(
                  Icons.article_outlined,
                  color: primaryColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (item.tag.isNotEmpty)
                          Container(
                            padding:
                            const EdgeInsets
                                .symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration:
                            BoxDecoration(
                              color: Colors.black
                                  .withValues(
                                alpha: 0.05,
                              ),
                              borderRadius:
                              BorderRadius
                                  .circular(
                                6,
                              ),
                            ),
                            child: Text(
                              item.tag,
                              style:
                              const TextStyle(
                                color:
                                secondaryText,
                                fontSize: 10,
                                fontWeight:
                                FontWeight
                                    .w600,
                              ),
                            ),
                          ),
                        if (item.tag.isNotEmpty &&
                            item.category
                                .isNotEmpty)
                          const SizedBox(
                            width: 8,
                          ),
                        if (item.category
                            .isNotEmpty)
                          Expanded(
                            child: Text(
                              item.category,
                              style:
                              const TextStyle(
                                color:
                                mutedText,
                                fontSize: 11,
                              ),
                              maxLines: 1,
                              overflow:
                              TextOverflow
                                  .ellipsis,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(
                      height: 6,
                    ),
                    Text(
                      item.title.isNotEmpty
                          ? item.title
                          : 'Untitled update',
                      style:
                      const TextStyle(
                        color: primaryText,
                        fontSize: 14,
                        fontWeight:
                        FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow:
                      TextOverflow.ellipsis,
                    ),
                    const SizedBox(
                      height: 4,
                    ),
                    Text(
                      item.fetchedAt.isNotEmpty
                          ? item.fetchedAt
                          : 'Recently',
                      style:
                      const TextStyle(
                        color: mutedText,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons
                    .chevron_right_rounded,
                color:
                Color(0xFFCBD5E1),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // BUILD
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    if (_isLoadingAuth) {
      return const Scaffold(
        backgroundColor:
        lightBackground,
        body: Center(
          child:
          CircularProgressIndicator(
            color: primaryColor,
          ),
        ),
      );
    }

    final currentUser = loggedUser;

    if (currentUser == null) {
      return const Scaffold(
        backgroundColor:
        lightBackground,
        body: Center(
          child:
          CircularProgressIndicator(
            color: primaryColor,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor:
      lightBackground,

      body: SafeArea(
        child: CustomScrollView(
          physics:
          const BouncingScrollPhysics(),
          slivers: [
            // Profile
            _buildProfileHeader(
              currentUser,
            ),

            // Election countdown
            _buildElectionCountdown(),

            // AI Assistant
            _buildAIAssistantBanner(),

            // Quick Access
            // _buildQuickAccess(
            //   currentUser,
            // ),

            // News Header
            _buildNewsHeader(),

            // Election News
            _buildElectionNews(),

            const SliverToBoxAdapter(
              child: SizedBox(
                height: 20,
              ),
            ),
          ],
        ),
      ),

      // =======================================================================
      // BOTTOM NAVIGATION
      // =======================================================================

      bottomNavigationBar:
      Container(
        decoration: BoxDecoration(
          color: cardBackground,
          border: Border(
            top: BorderSide(
              color: Colors.black
                  .withValues(
                alpha: 0.08,
              ),
            ),
          ),
        ),
        child:
        BottomNavigationBar(
          currentIndex:
          _currentBottomNavIndex,
          onTap:
          _onBottomNavTapped,
          type:
          BottomNavigationBarType
              .fixed,
          backgroundColor:
          Colors.transparent,
          elevation: 0,
          selectedItemColor:
          primaryColor,
          unselectedItemColor:
          mutedText,
          selectedLabelStyle:
          const TextStyle(
            fontSize: 11,
            fontWeight:
            FontWeight.bold,
          ),
          unselectedLabelStyle:
          const TextStyle(
            fontSize: 11,
          ),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(
                Icons.home_rounded,
              ),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(
                Icons.auto_awesome_rounded,
              ),
              label: 'AI Chat',
            ),
            BottomNavigationBarItem(
              icon: Icon(
                Icons.domain_verification,
              ),
              label: 'Verify Claims',
            ),
            BottomNavigationBarItem(
              icon: Icon(
                Icons.person_rounded,
              ),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// ELECTION COUNTDOWN CARD
// =============================================================================

class _ElectionCountdownCard
    extends StatefulWidget {
  final String title;
  final String subtitle;
  final DateTime electionDate;
  final Color primaryColor;

  const _ElectionCountdownCard({
    required this.title,
    required this.subtitle,
    required this.electionDate,
    required this.primaryColor,
  });

  @override
  State<_ElectionCountdownCard>
  createState() =>
      _ElectionCountdownCardState();
}

class _ElectionCountdownCardState
    extends State<_ElectionCountdownCard> {
  late Duration _remaining;

  Timer? _timer;

  @override
  void initState() {
    super.initState();

    _calculateRemaining();

    _timer = Timer.periodic(
      const Duration(seconds: 1),
          (_) {
        if (mounted) {
          _calculateRemaining();
        }
      },
    );
  }

  void _calculateRemaining() {
    final now = DateTime.now();

    final difference =
    widget.electionDate
        .difference(now);

    if (!mounted) {
      _remaining = difference.isNegative
          ? Duration.zero
          : difference;
      return;
    }

    setState(() {
      _remaining =
      difference.isNegative
          ? Duration.zero
          : difference;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatElectionDate() {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    final date =
        widget.electionDate;

    return '${months[date.month - 1]} '
        '${date.day}, ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final days =
        _remaining.inDays;

    final hours =
        _remaining.inHours % 24;

    final minutes =
        _remaining.inMinutes % 60;

    final seconds =
        _remaining.inSeconds % 60;

    final bool isToday =
        _remaining == Duration.zero;

    return Container(
      width: double.infinity,
      padding:
      const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(20),
        border: Border.all(
          color: widget.primaryColor
              .withValues(
            alpha: 0.20,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black
                .withValues(
              alpha: 0.025,
            ),
            blurRadius: 10,
            offset:
            const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          // -------------------------------------------------------------------
          // HEADER
          // -------------------------------------------------------------------

          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration:
                BoxDecoration(
                  color: widget
                      .primaryColor
                      .withValues(
                    alpha: 0.10,
                  ),
                  borderRadius:
                  BorderRadius.circular(
                    12,
                  ),
                ),
                child: Icon(
                  Icons
                      .how_to_vote_rounded,
                  color:
                  widget.primaryColor,
                  size: 22,
                ),
              ),

              const SizedBox(
                width: 12,
              ),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
                  children: [
                    Text(
                      widget.title,
                      maxLines: 1,
                      overflow:
                      TextOverflow
                          .ellipsis,
                      style:
                      const TextStyle(
                        color:
                        Color(0xFF1E293B),
                        fontSize: 14,
                        fontWeight:
                        FontWeight
                            .bold,
                      ),
                    ),
                    const SizedBox(
                      height: 3,
                    ),
                    Text(
                      widget.subtitle,
                      maxLines: 1,
                      overflow:
                      TextOverflow
                          .ellipsis,
                      style:
                      const TextStyle(
                        color:
                        Color(0xFF64748B),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(
                width: 8,
              ),

              Container(
                padding:
                const EdgeInsets
                    .symmetric(
                  horizontal: 8,
                  vertical: 5,
                ),
                decoration:
                BoxDecoration(
                  color: widget
                      .primaryColor
                      .withValues(
                    alpha: 0.10,
                  ),
                  borderRadius:
                  BorderRadius.circular(
                    8,
                  ),
                ),
                child: Text(
                  isToday
                      ? 'TODAY'
                      : 'UPCOMING',
                  style: TextStyle(
                    color:
                    widget.primaryColor,
                    fontSize: 9,
                    fontWeight:
                    FontWeight.w800,
                    letterSpacing:
                    0.5,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 18,
          ),

          // -------------------------------------------------------------------
          // COUNTDOWN
          // -------------------------------------------------------------------

          if (isToday)
            Container(
              width: double.infinity,
              padding:
              const EdgeInsets
                  .symmetric(
                vertical: 16,
              ),
              decoration:
              BoxDecoration(
                color: widget
                    .primaryColor
                    .withValues(
                  alpha: 0.08,
                ),
                borderRadius:
                BorderRadius.circular(
                  14,
                ),
              ),
              child: Text(
                'Election Day is here',
                textAlign:
                TextAlign.center,
                style: TextStyle(
                  color:
                  widget.primaryColor,
                  fontSize: 17,
                  fontWeight:
                  FontWeight.bold,
                ),
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  child:
                  _CountdownUnit(
                    value: days,
                    label: 'DAYS',
                    primaryColor:
                    widget
                        .primaryColor,
                  ),
                ),

                const SizedBox(
                  width: 7,
                ),

                Expanded(
                  child:
                  _CountdownUnit(
                    value: hours,
                    label: 'HOURS',
                    primaryColor:
                    widget
                        .primaryColor,
                  ),
                ),

                const SizedBox(
                  width: 7,
                ),

                Expanded(
                  child:
                  _CountdownUnit(
                    value: minutes,
                    label: 'MIN',
                    primaryColor:
                    widget
                        .primaryColor,
                  ),
                ),

                const SizedBox(
                  width: 7,
                ),

                Expanded(
                  child:
                  _CountdownUnit(
                    value: seconds,
                    label: 'SEC',
                    primaryColor:
                    widget
                        .primaryColor,
                  ),
                ),
              ],
            ),

          const SizedBox(
            height: 14,
          ),

          // -------------------------------------------------------------------
          // DATE
          // -------------------------------------------------------------------

          Container(
            width: double.infinity,
            padding:
            const EdgeInsets
                .symmetric(
              horizontal: 12,
              vertical: 9,
            ),
            decoration:
            BoxDecoration(
              color:
              const Color(0xFFF8FAFC),
              borderRadius:
              BorderRadius.circular(
                10,
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons
                      .calendar_today_rounded,
                  color:
                  Color(0xFF94A3B8),
                  size: 13,
                ),
                const SizedBox(
                  width: 7,
                ),
                const Text(
                  'Election Day',
                  style: TextStyle(
                    color:
                    Color(0xFF64748B),
                    fontSize: 11,
                  ),
                ),
                const Spacer(),
                Text(
                  _formatElectionDate(),
                  style:
                  const TextStyle(
                    color:
                    Color(0xFF1E293B),
                    fontSize: 11,
                    fontWeight:
                    FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// COUNTDOWN UNIT
// =============================================================================

class _CountdownUnit
    extends StatelessWidget {
  final int value;
  final String label;
  final Color primaryColor;

  const _CountdownUnit({
    required this.value,
    required this.label,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
      const EdgeInsets.symmetric(
        vertical: 10,
        horizontal: 4,
      ),
      decoration:
      BoxDecoration(
        color:
        const Color(0xFFF8FAFC),
        borderRadius:
        BorderRadius.circular(
          12,
        ),
        border: Border.all(
          color: Colors.black
              .withValues(
            alpha: 0.05,
          ),
        ),
      ),
      child: Column(
        children: [
          Text(
            value
                .toString()
                .padLeft(2, '0'),
            style: TextStyle(
              color: primaryColor,
              fontSize: 20,
              fontWeight:
              FontWeight.w800,
              height: 1,
            ),
          ),
          const SizedBox(
            height: 5,
          ),
          Text(
            label,
            style:
            const TextStyle(
              color:
              Color(0xFF94A3B8),
              fontSize: 8,
              fontWeight:
              FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// QUICK ACCESS ITEM
// =============================================================================

class _QuickAccessItem
    extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _QuickAccessItem({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration:
        BoxDecoration(
          color: Colors.white,
          borderRadius:
          BorderRadius.circular(
            16,
          ),
          border: Border.all(
            color: Colors.black
                .withValues(
              alpha: 0.08,
            ),
          ),
        ),
        child: Column(
          mainAxisAlignment:
          MainAxisAlignment
              .center,
          children: [
            Container(
              padding:
              const EdgeInsets.all(
                10,
              ),
              decoration:
              BoxDecoration(
                color: const Color(
                  0xFF22C55E,
                ).withValues(
                  alpha: 0.12,
                ),
                shape:
                BoxShape.circle,
              ),
              child: Icon(
                icon,
                color:
                const Color(
                  0xFF22C55E,
                ),
                size: 22,
              ),
            ),
            const SizedBox(
              height: 8,
            ),
            Text(
              label,
              textAlign:
              TextAlign.center,
              style:
              const TextStyle(
                color:
                Color(0xFF1E293B),
                fontSize: 11,
                fontWeight:
                FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}