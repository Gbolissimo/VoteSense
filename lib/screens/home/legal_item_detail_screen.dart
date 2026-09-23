import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/recent_legal_item.dart';

class LegalItemDetailScreen extends StatefulWidget {
  final RecentLegalItem item;

  const LegalItemDetailScreen({
    super.key,
    required this.item,
  });

  @override
  State<LegalItemDetailScreen> createState() =>
      _LegalItemDetailScreenState();
}

class _LegalItemDetailScreenState
    extends State<LegalItemDetailScreen> {
  // ---------------------------------------------------------------------------
  // VOTESENSE THEME
  // ---------------------------------------------------------------------------

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

  bool _isLoading = false;

  // ---------------------------------------------------------------------------
  // COPY
  // ---------------------------------------------------------------------------

  Future<void> _copyToClipboard() async {
    final text = [
      widget.item.title,
      if (widget.item.source.isNotEmpty)
        'Source: ${widget.item.source}',
      if (widget.item.fetchedAt.isNotEmpty)
        'Updated: ${widget.item.fetchedAt}',
      '',
      widget.item.description,
    ].join('\n');

    await Clipboard.setData(
      ClipboardData(text: text),
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'News copied to clipboard',
        ),
        backgroundColor: primaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // OPEN SOURCE
  // ---------------------------------------------------------------------------

  Future<void> _openSource() async {
    final rawUrl = widget.item.url.trim();

    if (rawUrl.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      String urlString = rawUrl;

      if (!urlString.startsWith('http://') &&
          !urlString.startsWith('https://')) {
        urlString = 'https://$urlString';
      }

      final uri = Uri.parse(urlString);

      await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Could not open the original article.',
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // ---------------------------------------------------------------------------
  // BUILD
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightBackground,

      appBar: AppBar(
        backgroundColor: lightBackground,
        surfaceTintColor: Colors.transparent,
        elevation: 0,

        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: primaryText,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),

        title: const Text(
          'Election Update',
          style: TextStyle(
            color: primaryText,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),

        actions: [
          Container(
            margin: const EdgeInsets.only(
              right: 12,
              top: 8,
              bottom: 8,
            ),
            decoration: BoxDecoration(
              color: cardBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.black.withValues(
                  alpha: 0.08,
                ),
              ),
            ),
            child: IconButton(
              tooltip: 'Copy',
              icon: const Icon(
                Icons.copy_rounded,
                color: secondaryText,
                size: 19,
              ),
              onPressed: _copyToClipboard,
            ),
          ),
        ],
      ),

      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          20,
          8,
          20,
          40,
        ),
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            // -----------------------------------------------------------------
            // TAG + CATEGORY
            // -----------------------------------------------------------------

            Row(
              children: [
                if (widget.item.tag.isNotEmpty)
                  Container(
                    padding:
                    const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(
                        alpha: 0.10,
                      ),
                      borderRadius:
                      BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize:
                      MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.campaign_rounded,
                          color: primaryColor,
                          size: 14,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          widget.item.tag,
                          style: const TextStyle(
                            color: primaryColor,
                            fontSize: 11,
                            fontWeight:
                            FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                if (widget.item.tag.isNotEmpty &&
                    widget.item.category.isNotEmpty)
                  const SizedBox(width: 10),

                if (widget.item.category.isNotEmpty)
                  Expanded(
                    child: Text(
                      widget.item.category,
                      maxLines: 1,
                      overflow:
                      TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: secondaryText,
                        fontSize: 12,
                        fontWeight:
                        FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 18),

            // -----------------------------------------------------------------
            // TITLE
            // -----------------------------------------------------------------

            Text(
              widget.item.title.isNotEmpty
                  ? widget.item.title
                  : 'Untitled Election Update',
              style: const TextStyle(
                color: primaryText,
                fontSize: 25,
                fontWeight: FontWeight.w800,
                height: 1.3,
                letterSpacing: -0.3,
              ),
            ),

            const SizedBox(height: 16),

            // -----------------------------------------------------------------
            // DATE
            // -----------------------------------------------------------------

            if (widget.item.fetchedAt.isNotEmpty)
              Row(
                children: [
                  const Icon(
                    Icons.schedule_rounded,
                    color: mutedText,
                    size: 15,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Updated ${widget.item.fetchedAt}',
                    style: const TextStyle(
                      color: secondaryText,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),

            const SizedBox(height: 24),

            // -----------------------------------------------------------------
            // SUMMARY
            // -----------------------------------------------------------------

            const Text(
              'NEWS SUMMARY',
              style: TextStyle(
                color: primaryText,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
              ),
            ),

            const SizedBox(height: 12),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cardBackground,
                borderRadius:
                BorderRadius.circular(18),
                border: Border.all(
                  color: Colors.black.withValues(
                    alpha: 0.07,
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(
                      alpha: 0.025,
                    ),
                    blurRadius: 8,
                    offset:
                    const Offset(0, 2),
                  ),
                ],
              ),
              child: SelectableText(
                widget.item.description.isNotEmpty
                    ? widget.item.description
                    : 'No detailed summary is available for this update.',
               textAlign: TextAlign.justify,
                style: const TextStyle(
                  color: Color(0xFF334155),
                  fontSize: 15,
                  height: 1.7,
                ),
              ),
            ),

            const SizedBox(height: 24),

            // -----------------------------------------------------------------
            // SOURCE
            // -----------------------------------------------------------------

            if (widget.item.source.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardBackground,
                  borderRadius:
                  BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.black.withValues(
                      alpha: 0.07,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color:
                        primaryColor.withValues(
                          alpha: 0.10,
                        ),
                        borderRadius:
                        BorderRadius.circular(
                          11,
                        ),
                      ),
                      child: const Icon(
                        Icons.public_rounded,
                        color: primaryColor,
                        size: 20,
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Source',
                            style: TextStyle(
                              color: mutedText,
                              fontSize: 11,
                              fontWeight:
                              FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            widget.item.source,
                            maxLines: 1,
                            overflow:
                            TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: primaryText,
                              fontSize: 14,
                              fontWeight:
                              FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 20),

            // -----------------------------------------------------------------
            // READ FULL STORY
            // -----------------------------------------------------------------

            if (widget.item.url.isNotEmpty)
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed:
                  _isLoading ? null : _openSource,
                  style:
                  ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    disabledBackgroundColor:
                    primaryColor.withValues(
                      alpha: 0.45,
                    ),
                    elevation: 0,
                    shape:
                    RoundedRectangleBorder(
                      borderRadius:
                      BorderRadius.circular(16),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                    width: 21,
                    height: 21,
                    child:
                    CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                      : const Row(
                    mainAxisAlignment:
                    MainAxisAlignment
                        .center,
                    children: [
                      Icon(
                        Icons
                            .open_in_new_rounded,
                        color: Colors.white,
                        size: 19,
                      ),
                      SizedBox(width: 9),
                      Text(
                        'Read Full Story',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight:
                          FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 24),

            // -----------------------------------------------------------------
            // VOTESENSE INFORMATION
            // -----------------------------------------------------------------

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: primaryColor.withValues(
                  alpha: 0.05,
                ),
                borderRadius:
                BorderRadius.circular(16),
                border: Border.all(
                  color: primaryColor.withValues(
                    alpha: 0.12,
                  ),
                ),
              ),
              child: Row(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color:
                      primaryColor.withValues(
                        alpha: 0.10,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.info_outline_rounded,
                      color: primaryColor,
                      size: 18,
                    ),
                  ),

                  const SizedBox(width: 12),

                  const Expanded(
                    child: Text(
                      'VoteSense provides election news for civic education and informational purposes. For the complete article, please refer to the original source.',
                      textAlign: TextAlign.justify,
                      style: TextStyle(
                        color: secondaryText,
                        fontSize: 12,
                        height: 1.5,
                      ),
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
}