import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../utils/globals.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState
    extends State<NotificationsScreen> {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  // ===========================================================================
  // VOTESENSE THEME
  // ===========================================================================

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

  static const Color borderColor =
  Color(0xFFE2E8F0);

  // ===========================================================================
  // DELETE NOTIFICATION
  // ===========================================================================

  Future<void> _deleteNotification(
      String docId,
      ) async {
    final bool? confirm =
    await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: cardBackground,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius:
            BorderRadius.circular(18),
          ),
          title: const Text(
            'Delete Notification',
            style: TextStyle(
              color: primaryText,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            'Are you sure you want to delete this notification?',
            style: TextStyle(
              color: secondaryText,
              fontSize: 14,
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(ctx, false),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: secondaryText,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            TextButton(
              onPressed: () =>
                  Navigator.pop(ctx, true),
              child: const Text(
                'Delete',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    try {
      await _firestore
          .collection('notifications')
          .doc(docId)
          .delete();

      if (!mounted) return;

      _showSnackBar(
        'Notification deleted.',
        isError: false,
      );
    } catch (e) {
      debugPrint(
        'Failed to delete notification: $e',
      );

      _showSnackBar(
        'Failed to delete notification.',
      );
    }
  }

  // ===========================================================================
  // ADD NOTIFICATION
  // ===========================================================================

  void _showAddNotificationBottomSheet() {
    final titleController =
    TextEditingController();

    final messageController =
    TextEditingController();

    final formKey =
    GlobalKey<FormState>();

    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: cardBackground,
      shape:
      const RoundedRectangleBorder(
        borderRadius:
        BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (
              context,
              setModalState,
              ) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom:
                MediaQuery.of(context)
                    .viewInsets
                    .bottom +
                    24,
              ),
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize:
                    MainAxisSize.min,
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      // -------------------------------------------------------
                      // HEADER
                      // -------------------------------------------------------

                      Row(
                        mainAxisAlignment:
                        MainAxisAlignment
                            .spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(
                                Icons
                                    .notifications_active_rounded,
                                color:
                                primaryColor,
                                size: 22,
                              ),
                              SizedBox(
                                width: 10,
                              ),
                              Text(
                                'New Notification',
                                style:
                                TextStyle(
                                  color:
                                  primaryText,
                                  fontSize:
                                  20,
                                  fontWeight:
                                  FontWeight
                                      .bold,
                                ),
                              ),
                            ],
                          ),
                          IconButton(
                            onPressed: () =>
                                Navigator.pop(
                                  context,
                                ),
                            icon:
                            const Icon(
                              Icons
                                  .close_rounded,
                              color:
                              secondaryText,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(
                        height: 20,
                      ),

                      // -------------------------------------------------------
                      // TITLE
                      // -------------------------------------------------------

                      _buildLabel('Title'),

                      const SizedBox(
                        height: 8,
                      ),

                      TextFormField(
                        controller:
                        titleController,
                        style:
                        const TextStyle(
                          color:
                          primaryText,
                          fontSize: 14,
                        ),
                        validator: (value) {
                          if (value == null ||
                              value
                                  .trim()
                                  .isEmpty) {
                            return 'Enter a title';
                          }

                          return null;
                        },
                        decoration:
                        _inputDecoration(
                          hintText:
                          'e.g. Election Update',
                          prefixIcon:
                          Icons
                              .title_rounded,
                        ),
                      ),

                      const SizedBox(
                        height: 18,
                      ),

                      // -------------------------------------------------------
                      // MESSAGE
                      // -------------------------------------------------------

                      _buildLabel('Message'),

                      const SizedBox(
                        height: 8,
                      ),

                      TextFormField(
                        controller:
                        messageController,
                        maxLines: 4,
                        style:
                        const TextStyle(
                          color:
                          primaryText,
                          fontSize: 14,
                          height: 1.4,
                        ),
                        validator: (value) {
                          if (value == null ||
                              value
                                  .trim()
                                  .isEmpty) {
                            return 'Enter a message';
                          }

                          return null;
                        },
                        decoration:
                        _inputDecoration(
                          hintText:
                          'Type your notification details...',
                          prefixIcon:
                          Icons
                              .message_outlined,
                        ),
                      ),

                      const SizedBox(
                        height: 24,
                      ),

                      // -------------------------------------------------------
                      // SUBMIT
                      // -------------------------------------------------------

                      SizedBox(
                        width:
                        double.infinity,
                        height: 52,
                        child:
                        ElevatedButton(
                          style:
                          ElevatedButton
                              .styleFrom(
                            backgroundColor:
                            primaryColor,
                            foregroundColor:
                            Colors.white,
                            elevation: 0,
                            shape:
                            RoundedRectangleBorder(
                              borderRadius:
                              BorderRadius
                                  .circular(
                                15,
                              ),
                            ),
                          ),
                          onPressed:
                          isSubmitting
                              ? null
                              : () async {
                            if (!formKey
                                .currentState!
                                .validate()) {
                              return;
                            }

                            setModalState(
                                  () =>
                              isSubmitting =
                              true,
                            );

                            try {
                              await _firestore
                                  .collection(
                                'notifications',
                              )
                                  .add({
                                'title':
                                titleController
                                    .text
                                    .trim(),
                                'message':
                                messageController
                                    .text
                                    .trim(),
                                'createdAt':
                                FieldValue
                                    .serverTimestamp(),
                                'createdBy':
                                _auth
                                    .currentUser
                                    ?.uid ??
                                    'anonymous',
                              });

                              if (!mounted) {
                                return;
                              }

                              Navigator.pop(
                                context,
                              );

                              _showSnackBar(
                                'Notification published successfully!',
                                isError:
                                false,
                              );
                            } catch (e) {
                              debugPrint(
                                'Failed to add notification: $e',
                              );

                              setModalState(
                                    () =>
                                isSubmitting =
                                false,
                              );

                              _showSnackBar(
                                'Failed to add notification.',
                              );
                            }
                          },
                          child: isSubmitting
                              ? const SizedBox(
                            width: 20,
                            height: 20,
                            child:
                            CircularProgressIndicator(
                              strokeWidth:
                              2,
                              color:
                              Colors.white,
                            ),
                          )
                              : const Text(
                            'Post Notification',
                            style:
                            TextStyle(
                              color:
                              Colors.white,
                              fontSize:
                              15,
                              fontWeight:
                              FontWeight
                                  .bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ===========================================================================
  // SNACKBAR
  // ===========================================================================

  void _showSnackBar(
      String message, {
        bool isError = true,
      }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .hideCurrentSnackBar();

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        backgroundColor:
        isError
            ? const Color(0xFFDC2626)
            : primaryColor,
        behavior:
        SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape:
        RoundedRectangleBorder(
          borderRadius:
          BorderRadius.circular(12),
        ),
        content: Text(
          message,
          style:
          const TextStyle(
            color: Colors.white,
            fontWeight:
            FontWeight.w500,
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // NOTIFICATION CARD
  // ===========================================================================

  Widget _buildNotificationCard({
    required String docId,
    required Map<String, dynamic> data,
  }) {
    final dynamic timestampValue =
    data['createdAt'];

    Timestamp? timestamp;

    if (timestampValue is Timestamp) {
      timestamp = timestampValue;
    }

    final String title =
        data['title']?.toString() ??
            'No Title';

    final String message =
        data['message']?.toString() ??
            'No Message';

    return GestureDetector(
      onLongPress:
      globalStatus == 'admin'
          ? () => _deleteNotification(
        docId,
      )
          : null,
      child: Container(
        padding:
        const EdgeInsets.all(16),
        decoration:
        BoxDecoration(
          color: cardBackground,
          borderRadius:
          BorderRadius.circular(16),
          border: Border.all(
            color: borderColor,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black
                  .withValues(
                alpha: 0.025,
              ),
              blurRadius: 8,
              offset:
              const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            // ---------------------------------------------------------------
            // ICON
            // ---------------------------------------------------------------

            Container(
              width: 42,
              height: 42,
              decoration:
              BoxDecoration(
                color: primaryColor
                    .withValues(
                  alpha: 0.10,
                ),
                borderRadius:
                BorderRadius.circular(
                  12,
                ),
              ),
              child: const Icon(
                Icons
                    .notifications_active_outlined,
                color: primaryColor,
                size: 21,
              ),
            ),

            const SizedBox(
              width: 14,
            ),

            // ---------------------------------------------------------------
            // CONTENT
            // ---------------------------------------------------------------

            Expanded(
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment
                    .start,
                children: [
                  Row(
                    crossAxisAlignment:
                    CrossAxisAlignment
                        .start,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style:
                          const TextStyle(
                            color:
                            primaryText,
                            fontSize: 15,
                            fontWeight:
                            FontWeight
                                .bold,
                          ),
                        ),
                      ),

                      if (timestamp !=
                          null) ...[
                        const SizedBox(
                          width: 8,
                        ),
                        Text(
                          _formatTimestamp(
                            timestamp,
                          ),
                          style:
                          const TextStyle(
                            color:
                            mutedText,
                            fontSize: 10,
                            fontWeight:
                            FontWeight
                                .w500,
                          ),
                        ),
                      ],
                    ],
                  ),

                  const SizedBox(
                    height: 7,
                  ),

                  Text(
                    message,
                    textAlign: TextAlign.justify,
                    style:
                    const TextStyle(
                      color:
                      secondaryText,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // EMPTY STATE
  // ===========================================================================

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment:
        MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration:
            BoxDecoration(
              color: primaryColor
                  .withValues(
                alpha: 0.08,
              ),
              shape: BoxShape.circle,
              border: Border.all(
                color: primaryColor
                    .withValues(
                  alpha: 0.12,
                ),
              ),
            ),
            child: const Icon(
              Icons
                  .notifications_none_rounded,
              color: primaryColor,
              size: 38,
            ),
          ),

          const SizedBox(
            height: 18,
          ),

          const Text(
            'No notifications yet',
            style: TextStyle(
              color: primaryText,
              fontSize: 17,
              fontWeight:
              FontWeight.bold,
            ),
          ),

          const SizedBox(
            height: 6,
          ),

          const Text(
            'You’ll see important app updates here.',
            textAlign:
            TextAlign.center,
            style: TextStyle(
              color: secondaryText,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // LABEL
  // ===========================================================================

  Widget _buildLabel(
      String text,
      ) {
    return Text(
      text,
      style: const TextStyle(
        color: primaryText,
        fontSize: 13,
        fontWeight:
        FontWeight.w600,
      ),
    );
  }

  // ===========================================================================
  // INPUT DECORATION
  // ===========================================================================

  InputDecoration _inputDecoration({
    required String hintText,
    required IconData prefixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle:
      const TextStyle(
        color: mutedText,
        fontSize: 13,
      ),
      filled: true,
      fillColor:
      lightBackground,
      prefixIcon: Icon(
        prefixIcon,
        color: secondaryText,
        size: 19,
      ),
      contentPadding:
      const EdgeInsets
          .symmetric(
        horizontal: 16,
        vertical: 15,
      ),
      border:
      OutlineInputBorder(
        borderRadius:
        BorderRadius.circular(
          14,
        ),
        borderSide:
        const BorderSide(
          color: borderColor,
        ),
      ),
      enabledBorder:
      OutlineInputBorder(
        borderRadius:
        BorderRadius.circular(
          14,
        ),
        borderSide:
        const BorderSide(
          color: borderColor,
        ),
      ),
      focusedBorder:
      OutlineInputBorder(
        borderRadius:
        BorderRadius.circular(
          14,
        ),
        borderSide:
        const BorderSide(
          color: primaryColor,
          width: 1.5,
        ),
      ),
      errorBorder:
      OutlineInputBorder(
        borderRadius:
        BorderRadius.circular(
          14,
        ),
        borderSide:
        const BorderSide(
          color: Colors.red,
        ),
      ),
      focusedErrorBorder:
      OutlineInputBorder(
        borderRadius:
        BorderRadius.circular(
          14,
        ),
        borderSide:
        const BorderSide(
          color: Colors.red,
          width: 1.5,
        ),
      ),
    );
  }

  // ===========================================================================
  // TIMESTAMP
  // ===========================================================================

  String _formatTimestamp(
      Timestamp timestamp,
      ) {
    final date =
    timestamp.toDate();

    final now =
    DateTime.now();

    final difference =
    now.difference(date);

    if (difference.inMinutes < 1) {
      return 'Just now';
    }

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    }

    if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    }

    if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    }

    return '${date.day}/${date.month}/${date.year}';
  }

  // ===========================================================================
  // BUILD
  // ===========================================================================

  @override
  Widget build(
      BuildContext context,
      ) {
    return Scaffold(
      backgroundColor:
      lightBackground,

      // -----------------------------------------------------------------------
      // APP BAR
      // -----------------------------------------------------------------------

      appBar: AppBar(
        backgroundColor:
        lightBackground,
        surfaceTintColor:
        Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,

        leading: IconButton(
          icon: const Icon(
            Icons
                .arrow_back_ios_new_rounded,
            color: primaryText,
            size: 18,
          ),
          onPressed: () =>
              Navigator.maybePop(
                context,
              ),
        ),

        title: const Text(
          'Notifications',
          style: TextStyle(
            color: primaryText,
            fontSize: 18,
            fontWeight:
            FontWeight.bold,
          ),
        ),
      ),

      // -----------------------------------------------------------------------
      // ADMIN ADD BUTTON
      // -----------------------------------------------------------------------

      floatingActionButton:
      globalStatus == 'admin'
          ? FloatingActionButton
          .extended(
        onPressed:
        _showAddNotificationBottomSheet,
        backgroundColor:
        primaryColor,
        elevation: 3,
        icon: const Icon(
          Icons.add_rounded,
          color:
          Colors.white,
        ),
        label: const Text(
          'Add',
          style:
          TextStyle(
            color:
            Colors.white,
            fontWeight:
            FontWeight
                .bold,
          ),
        ),
      )
          : null,

      // -----------------------------------------------------------------------
      // BODY
      // -----------------------------------------------------------------------

      body: SafeArea(
        child: Padding(
          padding:
          const EdgeInsets.fromLTRB(
            20,
            8,
            20,
            0,
          ),
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment
                .start,
            children: [

              // ---------------------------------------------------------------
              // NOTIFICATIONS
              // ---------------------------------------------------------------

              Expanded(
                child:
                StreamBuilder<
                    QuerySnapshot>(
                  stream:
                  _firestore
                      .collection(
                    'notifications',
                  )
                      .orderBy(
                    'createdAt',
                    descending:
                    true,
                  )
                      .snapshots(),
                  builder:
                      (
                      context,
                      snapshot,
                      ) {
                    // ---------------------------------------------------------
                    // LOADING
                    // ---------------------------------------------------------

                    if (snapshot
                        .connectionState ==
                        ConnectionState
                            .waiting) {
                      return const Center(
                        child:
                        CircularProgressIndicator(
                          color:
                          primaryColor,
                          strokeWidth:
                          2.5,
                        ),
                      );
                    }

                    // ---------------------------------------------------------
                    // ERROR
                    // ---------------------------------------------------------

                    if (snapshot.hasError) {
                      debugPrint(
                        'Notifications error: '
                            '${snapshot.error}',
                      );

                      return Center(
                        child: Column(
                          mainAxisAlignment:
                          MainAxisAlignment
                              .center,
                          children: [
                            Container(
                              width: 64,
                              height: 64,
                              decoration:
                              BoxDecoration(
                                color: Colors
                                    .red
                                    .withValues(
                                  alpha:
                                  0.08,
                                ),
                                shape:
                                BoxShape
                                    .circle,
                              ),
                              child:
                              const Icon(
                                Icons
                                    .error_outline_rounded,
                                color:
                                Colors.red,
                                size: 30,
                              ),
                            ),
                            const SizedBox(
                              height: 14,
                            ),
                            const Text(
                              'Unable to load notifications',
                              style:
                              TextStyle(
                                color:
                                primaryText,
                                fontSize:
                                15,
                                fontWeight:
                                FontWeight
                                    .w600,
                              ),
                            ),
                            const SizedBox(
                              height: 5,
                            ),
                            const Text(
                              'Please try again later.',
                              style:
                              TextStyle(
                                color:
                                secondaryText,
                                fontSize:
                                13,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    // ---------------------------------------------------------
                    // EMPTY
                    // ---------------------------------------------------------

                    final docs =
                        snapshot.data
                            ?.docs ??
                            [];

                    if (docs.isEmpty) {
                      return _buildEmptyState();
                    }

                    // ---------------------------------------------------------
                    // LIST
                    // ---------------------------------------------------------

                    return ListView.separated(
                      physics:
                      const BouncingScrollPhysics(),
                      padding:
                      const EdgeInsets
                          .only(
                        bottom: 100,
                      ),
                      itemCount:
                      docs.length,
                      separatorBuilder:
                          (
                          context,
                          index,
                          ) =>
                      const SizedBox(
                        height: 12,
                      ),
                      itemBuilder:
                          (
                          context,
                          index,
                          ) {
                        final doc =
                        docs[index];

                        final rawData =
                        doc.data();

                        if (rawData
                        is! Map<
                            String,
                            dynamic>) {
                          return const SizedBox
                              .shrink();
                        }

                        return _buildNotificationCard(
                          docId:
                          doc.id,
                          data:
                          rawData,
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}