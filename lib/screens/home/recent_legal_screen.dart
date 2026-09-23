import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../models/recent_legal_item.dart';
import '../../utils/globals.dart';
import 'legal_item_detail_screen.dart';

class RecentLegalScreen extends StatefulWidget {
  const RecentLegalScreen({super.key});

  @override
  State<RecentLegalScreen> createState() => _RecentLegalScreenState();
}

class _RecentLegalScreenState extends State<RecentLegalScreen> {
  // ===========================================================================
  // VOTESENSE THEME
  // ===========================================================================

  static const Color primaryColor = Color(0xFF22C55E);
  static const Color lightBackground = Color(0xFFF8FAFC);
  static const Color cardBackground = Colors.white;
  static const Color primaryText = Color(0xFF1E293B);
  static const Color secondaryText = Color(0xFF64748B);
  static const Color mutedText = Color(0xFF94A3B8);
  static const Color borderColor = Color(0xFFE2E8F0);

  // ===========================================================================
  // CONTROLLERS
  // ===========================================================================

  final TextEditingController _searchController =
  TextEditingController();

  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ===========================================================================
  // NAVIGATION
  // ===========================================================================

  Future<void> _navigateTo(Widget screen) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => screen,
      ),
    );
  }

  // ===========================================================================
  // EDIT NEWS
  // ===========================================================================

  Future<void> _editNews(RecentLegalItem item) async {
    final titleController =
    TextEditingController(text: item.title);

    final descriptionController =
    TextEditingController(text: item.description);

    final categoryController =
    TextEditingController(text: item.category);

    final tagController =
    TextEditingController(text: item.tag);

    final sourceController =
    TextEditingController(text: item.source);

    /*
     * If your RecentLegalItem model has a url/link field,
     * you can initialise another controller here.
     *
     * Example:
     *
     * final urlController =
     *     TextEditingController(text: item.url);
     */

    final formKey = GlobalKey<FormState>();

    bool isSaving = false;

    await showDialog(
      context: context,
      barrierDismissible: !isSaving,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: cardBackground,
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              titlePadding: const EdgeInsets.fromLTRB(
                24,
                24,
                24,
                8,
              ),
              contentPadding: const EdgeInsets.fromLTRB(
                24,
                12,
                24,
                8,
              ),
              actionsPadding: const EdgeInsets.fromLTRB(
                16,
                4,
                16,
                16,
              ),
              title: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(
                        alpha: 0.10,
                      ),
                      borderRadius:
                      BorderRadius.circular(11),
                    ),
                    child: const Icon(
                      Icons.edit_rounded,
                      color: primaryColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Edit Election News',
                      style: TextStyle(
                        color: primaryText,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 500,
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildEditField(
                          controller: titleController,
                          label: 'Title',
                          hint: 'Enter news title',
                          icon: Icons.title_rounded,
                          validator: (value) {
                            if (value == null ||
                                value.trim().isEmpty) {
                              return 'Please enter a title';
                            }

                            return null;
                          },
                        ),

                        const SizedBox(height: 14),

                        _buildEditField(
                          controller: descriptionController,
                          label: 'Description',
                          hint: 'Enter news description',
                          icon: Icons.description_outlined,
                          maxLines: 5,
                          validator: (value) {
                            if (value == null ||
                                value.trim().isEmpty) {
                              return 'Please enter a description';
                            }

                            return null;
                          },
                        ),

                        const SizedBox(height: 14),

                        _buildEditField(
                          controller: categoryController,
                          label: 'Category',
                          hint: 'e.g. Election, INEC, Politics',
                          icon: Icons.category_outlined,
                        ),

                        const SizedBox(height: 14),

                        _buildEditField(
                          controller: tagController,
                          label: 'Tag',
                          hint: 'e.g. Breaking, Update, Featured',
                          icon: Icons.sell_outlined,
                        ),

                        const SizedBox(height: 14),

                        _buildEditField(
                          controller: sourceController,
                          label: 'Source',
                          hint: 'e.g. Punch, Vanguard, INEC',
                          icon: Icons.language_rounded,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving
                      ? null
                      : () {
                    Navigator.pop(dialogContext);
                  },
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      color: secondaryText,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: isSaving
                      ? null
                      : () async {
                    if (!formKey.currentState!
                        .validate()) {
                      return;
                    }

                    setDialogState(() {
                      isSaving = true;
                    });

                    try {
                      await FirebaseFirestore.instance
                          .collection('election_news')
                          .doc(item.id)
                          .update({
                        'title':
                        titleController.text.trim(),
                        'description':
                        descriptionController.text.trim(),
                        'category':
                        categoryController.text.trim(),
                        'tag':
                        tagController.text.trim(),
                        'source':
                        sourceController.text.trim(),
                        'updatedAt':
                        FieldValue.serverTimestamp(),
                      });

                      if (!mounted) return;

                      Navigator.pop(dialogContext);

                      _showSnackBar(
                        'Election news updated successfully.',
                        isError: false,
                      );
                    } catch (e) {
                      debugPrint(
                        'Failed to update election news: $e',
                      );

                      setDialogState(() {
                        isSaving = false;
                      });

                      if (!mounted) return;

                      _showSnackBar(
                        'Failed to update election news.',
                      );
                    }
                  },
                  child: isSaving
                      ? const SizedBox(
                    width: 18,
                    height: 18,
                    child:
                    CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                      : const Text(
                    'Save Changes',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    titleController.dispose();
    descriptionController.dispose();
    categoryController.dispose();
    tagController.dispose();
    sourceController.dispose();
  }

  // ===========================================================================
  // EDIT FIELD
  // ===========================================================================

  Widget _buildEditField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: primaryText,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 7),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          cursorColor: primaryColor,
          style: const TextStyle(
            color: primaryText,
            fontSize: 14,
          ),
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              color: mutedText,
              fontSize: 13,
            ),
            prefixIcon: Padding(
              padding: EdgeInsets.only(
                bottom: maxLines > 1 ? 55 : 0,
              ),
              child: Icon(
                icon,
                color: secondaryText,
                size: 19,
              ),
            ),
            filled: true,
            fillColor: lightBackground,
            contentPadding:
            const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 13,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: borderColor,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: borderColor,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: primaryColor,
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Colors.red,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Colors.red,
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // DELETE NEWS
  // ===========================================================================

  Future<void> _deleteItem(String docId) async {
    final bool? confirm =
    await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: cardBackground,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Text(
            'Delete News',
            style: TextStyle(
              color: primaryText,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            'Are you sure you want to delete this election news item?',
            style: TextStyle(
              color: secondaryText,
              fontSize: 14,
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(context, false),
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
                  Navigator.pop(context, true),
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
      await FirebaseFirestore.instance
          .collection('election_news')
          .doc(docId)
          .delete();

      if (!mounted) return;

      _showSnackBar(
        'News deleted successfully.',
        isError: false,
      );
    } catch (e) {
      debugPrint(
        'Failed to delete election news: $e',
      );

      if (!mounted) return;

      _showSnackBar(
        'Failed to delete news.',
      );
    }
  }

  // ===========================================================================
  // BOOKMARK
  // ===========================================================================

  Future<void> _toggleBookmark(
      String docId,
      bool currentStatus,
      ) async {
    try {
      await FirebaseFirestore.instance
          .collection('election_news')
          .doc(docId)
          .update({
        'isBookmarked': !currentStatus,
      });
    } catch (e) {
      debugPrint(
        'Failed to update bookmark: $e',
      );

      if (!mounted) return;

      _showSnackBar(
        'Failed to update bookmark.',
      );
    }
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

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor:
        isError ? const Color(0xFFDC2626) : primaryColor,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        content: Text(
          message,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // SEARCH
  // ===========================================================================

  Widget _buildSearchField() {
    return Container(
      decoration: BoxDecoration(
        color: cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: borderColor,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: 0.025,
            ),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        cursorColor: primaryColor,
        style: const TextStyle(
          color: primaryText,
          fontSize: 14,
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery =
                value.trim().toLowerCase();
          });
        },
        decoration: InputDecoration(
          hintText: 'Search election news...',
          hintStyle: const TextStyle(
            color: mutedText,
            fontSize: 13,
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: secondaryText,
            size: 21,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
            icon: const Icon(
              Icons.clear_rounded,
              color: secondaryText,
              size: 19,
            ),
            onPressed: () {
              _searchController.clear();

              setState(() {
                _searchQuery = '';
              });
            },
          )
              : null,
          border: InputBorder.none,
          contentPadding:
          const EdgeInsets.symmetric(
            vertical: 15,
            horizontal: 4,
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // NEWS CARD
  // ===========================================================================

  Widget _buildNewsCard(
      RecentLegalItem item,
      ) {
    final bool isAdmin =
        globalStatus == 'admin';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                LegalItemDetailScreen(
                  item: item,
                ),
          ),
        );
      },
      onLongPress:
      isAdmin ? () => _deleteItem(item.id) : null,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardBackground,
          borderRadius:
          BorderRadius.circular(16),
          border: Border.all(
            color: borderColor,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                alpha: 0.025,
              ),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            // -----------------------------------------------------------------
            // NEWS ICON
            // -----------------------------------------------------------------

            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color:
                primaryColor.withValues(
                  alpha: 0.10,
                ),
                borderRadius:
                BorderRadius.circular(13),
              ),
              child: const Icon(
                Icons.newspaper_outlined,
                color: primaryColor,
                size: 23,
              ),
            ),

            const SizedBox(width: 14),

            // -----------------------------------------------------------------
            // CONTENT
            // -----------------------------------------------------------------

            Expanded(
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  // Tag
                  if (item.tag.isNotEmpty)
                    Container(
                      padding:
                      const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration:
                      BoxDecoration(
                        color: primaryColor
                            .withValues(
                          alpha: 0.08,
                        ),
                        borderRadius:
                        BorderRadius.circular(
                          6,
                        ),
                      ),
                      child: Text(
                        item.tag,
                        style:
                        const TextStyle(
                          color: primaryColor,
                          fontSize: 10,
                          fontWeight:
                          FontWeight.w700,
                        ),
                      ),
                    ),

                  const SizedBox(height: 7),

                  // Title
                  Text(
                    item.title,
                    style:
                    const TextStyle(
                      color: primaryText,
                      fontSize: 14,
                      fontWeight:
                      FontWeight.w700,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow:
                    TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 7),

                  // Source + Date
                  Row(
                    children: [
                      if (item.source.isNotEmpty) ...[
                        const Icon(
                          Icons.language_rounded,
                          color: mutedText,
                          size: 13,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            item.source,
                            style:
                            const TextStyle(
                              color: secondaryText,
                              fontSize: 11,
                              fontWeight:
                              FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow:
                            TextOverflow
                                .ellipsis,
                          ),
                        ),
                      ],

                      if (item.source.isNotEmpty &&
                          item.fetchedAt.isNotEmpty)
                        Container(
                          width: 3,
                          height: 3,
                          margin:
                          const EdgeInsets
                              .symmetric(
                            horizontal: 8,
                          ),
                          decoration:
                          const BoxDecoration(
                            color: mutedText,
                            shape:
                            BoxShape.circle,
                          ),
                        ),

                      if (item.fetchedAt.isNotEmpty)
                        Text(
                          item.fetchedAt,
                          style:
                          const TextStyle(
                            color: mutedText,
                            fontSize: 11,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 4),

            // -----------------------------------------------------------------
            // ADMIN EDIT
            // -----------------------------------------------------------------

            if (isAdmin)
              IconButton(
                tooltip: 'Edit',
                padding: EdgeInsets.zero,
                constraints:
                const BoxConstraints(
                  minWidth: 36,
                  minHeight: 36,
                ),
                onPressed: () =>
                    _editNews(item),
                icon: const Icon(
                  Icons.edit_outlined,
                  color: primaryColor,
                  size: 19,
                ),
              ),

            // -----------------------------------------------------------------
            // ARROW
            // -----------------------------------------------------------------

            const Icon(
              Icons.chevron_right_rounded,
              color: mutedText,
              size: 21,
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
    final bool hasSearch =
        _searchQuery.isNotEmpty;

    return Center(
      child: Padding(
        padding:
        const EdgeInsets.symmetric(
          horizontal: 30,
        ),
        child: Column(
          mainAxisAlignment:
          MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: primaryColor.withValues(
                  alpha: 0.08,
                ),
                shape: BoxShape.circle,
                border: Border.all(
                  color:
                  primaryColor.withValues(
                    alpha: 0.12,
                  ),
                ),
              ),
              child: const Icon(
                Icons.newspaper_outlined,
                color: primaryColor,
                size: 38,
              ),
            ),

            const SizedBox(height: 18),

            Text(
              hasSearch
                  ? 'No matching news'
                  : 'No election news yet',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: primaryText,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 6),

            Text(
              hasSearch
                  ? 'Try searching with a different keyword.'
                  : 'Election updates and important news will appear here.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: secondaryText,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // ERROR STATE
  // ===========================================================================

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding:
        const EdgeInsets.symmetric(
          horizontal: 30,
        ),
        child: Column(
          mainAxisAlignment:
          MainAxisAlignment.center,
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: Colors.red.withValues(
                  alpha: 0.08,
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                color: Colors.red,
                size: 32,
              ),
            ),

            const SizedBox(height: 14),

            const Text(
              'Unable to load election news',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: primaryText,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 5),

            const Text(
              'Please try again later.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: secondaryText,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // BUILD
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    final bool isAdmin =
        globalStatus == 'admin';

    return Scaffold(
      backgroundColor: lightBackground,

      // -----------------------------------------------------------------------
      // APP BAR
      // -----------------------------------------------------------------------

      appBar: AppBar(
        backgroundColor: lightBackground,
        surfaceTintColor:
        Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,

        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: primaryText,
            size: 18,
          ),
          onPressed: () =>
              Navigator.maybePop(context),
        ),

        title: const Text(
          'Election News',
          style: TextStyle(
            color: primaryText,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),

        centerTitle: true,
      ),

      // -----------------------------------------------------------------------
      // ADMIN ADD BUTTON
      // -----------------------------------------------------------------------

      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
        onPressed: () {
          // Add news screen can be connected here.
        },
        backgroundColor:
        primaryColor,
        elevation: 3,
        icon: const Icon(
          Icons.add_rounded,
          color: Colors.white,
        ),
        label: const Text(
          'Add',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      )
          : null,

      // -----------------------------------------------------------------------
      // BODY
      // -----------------------------------------------------------------------

      body: SafeArea(
        child: Column(
          children: [
            // Search
            Padding(
              padding:
              const EdgeInsets.fromLTRB(
                20,
                8,
                20,
                18,
              ),
              child: _buildSearchField(),
            ),

            // News
            Expanded(
              child:
              StreamBuilder<QuerySnapshot>(
                stream:
                FirebaseFirestore.instance
                    .collection(
                  'election_news',
                )
                    .orderBy(
                  'fetchedAt',
                  descending: true,
                ).limitToLast(100)
                    .snapshots(),
                builder:
                    (context, snapshot) {
                  // -----------------------------------------------------------
                  // LOADING
                  // -----------------------------------------------------------

                  if (snapshot
                      .connectionState ==
                      ConnectionState.waiting) {
                    return const Center(
                      child:
                      CircularProgressIndicator(
                        color: primaryColor,
                        strokeWidth: 2.5,
                      ),
                    );
                  }

                  // -----------------------------------------------------------
                  // ERROR
                  // -----------------------------------------------------------

                  if (snapshot.hasError) {
                    debugPrint(
                      'Election news error: '
                          '${snapshot.error}',
                    );

                    return _buildErrorState();
                  }

                  // -----------------------------------------------------------
                  // DATA
                  // -----------------------------------------------------------

                  final docs =
                      snapshot.data?.docs ??
                          [];

                  List<RecentLegalItem>
                  items = docs
                      .map(
                        (doc) =>
                        RecentLegalItem
                            .fromFirestore(
                          doc,
                        ),
                  )
                      .toList();

                  // -----------------------------------------------------------
                  // SEARCH FILTER
                  // -----------------------------------------------------------

                  items =
                      items.where((item) {
                        if (_searchQuery
                            .isEmpty) {
                          return true;
                        }

                        return item.title
                            .toLowerCase()
                            .contains(
                          _searchQuery,
                        ) ||
                            item.category
                                .toLowerCase()
                                .contains(
                              _searchQuery,
                            ) ||
                            item.tag
                                .toLowerCase()
                                .contains(
                              _searchQuery,
                            ) ||
                            item.description
                                .toLowerCase()
                                .contains(
                              _searchQuery,
                            ) ||
                            item.source
                                .toLowerCase()
                                .contains(
                              _searchQuery,
                            );
                      }).toList();

                  // -----------------------------------------------------------
                  // EMPTY
                  // -----------------------------------------------------------

                  if (items.isEmpty) {
                    return _buildEmptyState();
                  }

                  // -----------------------------------------------------------
                  // LIST
                  // -----------------------------------------------------------

                  return ListView.separated(
                    padding:
                    const EdgeInsets.fromLTRB(
                      20,
                      0,
                      20,
                      100,
                    ),
                    physics:
                    const BouncingScrollPhysics(),
                    itemCount:
                    items.length,
                    separatorBuilder:
                        (context, index) {
                      return const SizedBox(
                        height: 12,
                      );
                    },
                    itemBuilder:
                        (context, index) {
                      return _buildNewsCard(
                        items[index],
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}