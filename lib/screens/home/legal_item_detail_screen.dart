import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
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

  static const Color primaryColor = Color(0xFF22C55E);
  static const Color lightBackground = Color(0xFFF8FAFC);
  static const Color cardBackground = Colors.white;
  static const Color primaryText = Color(0xFF1E293B);
  static const Color secondaryText = Color(0xFF64748B);
  static const Color mutedText = Color(0xFF94A3B8);

  bool _isLoading = false;
  bool _isConfigLoading = true;
  bool _isTranslating = false;
  String _selectedLanguage = 'English';

  String? _fetchedApiKey;
  String _fetchedApiVersion = 'v1beta';
  String _fetchedModel = 'gemini-2.5-flash';

  final Map<String, Map<String, String>> _translationCache = {};

  String? _translatedTitle;
  String? _translatedDescription;

  final List<String> _languages = [
    'English',
    'Pidgin',
    'Yoruba',
    'Hausa',
    'Igbo',
  ];

  @override
  void initState() {
    super.initState();
    _loadConfiguration();
  }

  Future<void> _loadConfiguration() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('AI').doc('api').get();
      if (doc.exists && mounted) {
        setState(() {
          _fetchedApiKey = doc['key'];
          _fetchedApiVersion = doc['version'] ?? 'v1beta';
          _fetchedModel = doc['model'] ?? 'gemini-2.5-flash';
          _isConfigLoading = false;
        });
      } else {
        if (mounted) setState(() => _isConfigLoading = false);
      }
    } catch (e) {
      debugPrint("Config Error: $e");
      if (mounted) setState(() => _isConfigLoading = false);
    }
  }

  Future<void> _changeLanguage(String lang) async {
    if (_selectedLanguage == lang) return;

    setState(() {
      _selectedLanguage = lang;
      if (lang == 'English') {
        _isTranslating = false;
        _translatedTitle = null;
        _translatedDescription = null;
        return;
      }
    });

    if (_translationCache.containsKey(lang)) {
      setState(() {
        _translatedTitle = _translationCache[lang]!['title'];
        _translatedDescription = _translationCache[lang]!['description'];
      });
      return;
    }

    if (_fetchedApiKey == null || _fetchedApiKey!.isEmpty) {
      _showErrorSnackBar("API Key not configured.");
      return;
    }

    setState(() {
      _isTranslating = true;
    });

    try {
      final model = GenerativeModel(
        model: _fetchedModel,
        apiKey: _fetchedApiKey!,
      );

      final prompt = '''
You are an expert professional translator specializing in Nigerian local languages and dialects. 
Translate the following news title and description accurately into fluent and natural ${lang.toLowerCase() == 'pidgin' ? 'Nigerian Pidgin English' : lang}.

CRITICAL: Return ONLY valid JSON format containing exact keys "title" and "description". Do not include markdown codeblocks like ```json, just raw JSON string.

Title: ${widget.item.title}
Description: ${widget.item.description}
''';

      final content = [Content.text(prompt)];
      final response = await model.generateContent(content);
      final responseText = response.text?.trim() ?? '';

      ParsedTranslation parsed = _parseGeminiResponse(responseText, widget.item.title, widget.item.description);

      _translationCache[lang] = {
        'title': parsed.title,
        'description': parsed.description,
      };

      if (mounted) {
        setState(() {
          _translatedTitle = parsed.title;
          _translatedDescription = parsed.description;
        });
      }
    } catch (e) {
      debugPrint("Translation Error: $e");
      _showErrorSnackBar("Could not complete translation.");
    } finally {
      if (mounted) {
        setState(() {
          _isTranslating = false;
        });
      }
    }
  }

  ParsedTranslation _parseGeminiResponse(String raw, String fallbackTitle, String fallbackDesc) {
    try {
      String cleaned = raw
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();

      final startIndex = cleaned.indexOf('{');
      final endIndex = cleaned.lastIndexOf('}');
      if (startIndex != -1 && endIndex != -1 && endIndex > startIndex) {
        cleaned = cleaned.substring(startIndex, endIndex + 1);
      }

      final Map<String, dynamic> decoded = jsonDecode(cleaned);
      return ParsedTranslation(
        title: decoded['title']?.toString().isNotEmpty == true ? decoded['title'] : fallbackTitle,
        description: decoded['description']?.toString().isNotEmpty == true ? decoded['description'] : fallbackDesc,
      );
    } catch (e) {
      debugPrint("JSON Parse Error: $e -> Raw text was: $raw");
    }

    return ParsedTranslation(title: fallbackTitle, description: raw.isNotEmpty ? raw : fallbackDesc);
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  String get _displayTitle =>
      _translatedTitle ?? (widget.item.title.isNotEmpty ? widget.item.title : 'Untitled Election Update');

  String get _displayDescription =>
      _translatedDescription ?? (widget.item.description.isNotEmpty ? widget.item.description : 'No detailed summary is available for this update.');

  Future<void> _copyToClipboard() async {
    final text = [
      _displayTitle,
      if (widget.item.source.isNotEmpty) 'Source: ${widget.item.source}',
      if (widget.item.fetchedAt.isNotEmpty) 'Updated: ${widget.item.fetchedAt}',
      'Language: $_selectedLanguage',
      '',
      _displayDescription,
    ].join('\n');

    await Clipboard.setData(ClipboardData(text: text));

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('News copied to clipboard'),
        backgroundColor: primaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _openSource() async {
    final rawUrl = widget.item.url.trim();
    if (rawUrl.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      String urlString = rawUrl;
      if (!urlString.startsWith('http://') && !urlString.startsWith('https://')) {
        urlString = 'https://$urlString';
      }

      final uri = Uri.parse(urlString);
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      _showErrorSnackBar('Could not open the original article.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

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
            margin: const EdgeInsets.only(right: 12, top: 8, bottom: 8),
            decoration: BoxDecoration(
              color: cardBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
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
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // TAG + CATEGORY
            Row(
              children: [
                if (widget.item.tag.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.campaign_rounded, color: primaryColor, size: 14),
                        const SizedBox(width: 6),
                        Text(
                          widget.item.tag,
                          style: const TextStyle(
                            color: primaryColor,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                if (widget.item.tag.isNotEmpty && widget.item.category.isNotEmpty)
                  const SizedBox(width: 10),
                if (widget.item.category.isNotEmpty)
                  Expanded(
                    child: Text(
                      widget.item.category,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: secondaryText,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 18),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: cardBackground,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.black.withValues(alpha: 0.07)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.translate_rounded, color: primaryColor, size: 16),
                      const SizedBox(width: 6),
                      const Text(
                        'Translate Update',
                        style: TextStyle(
                          color: primaryText,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      if (_isConfigLoading || _isTranslating)
                        const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: primaryColor,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: _languages.map((lang) {
                        final isSelected = _selectedLanguage == lang;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(lang),
                            selected: isSelected,
                            onSelected: (_isConfigLoading || _isTranslating)
                                ? null
                                : (selected) {
                              if (selected) _changeLanguage(lang);
                            },
                            selectedColor: primaryColor.withValues(alpha: 0.15),
                            backgroundColor: lightBackground,
                            labelStyle: TextStyle(
                              color: isSelected ? primaryColor : secondaryText,
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: BorderSide(
                                color: isSelected
                                    ? primaryColor.withValues(alpha: 0.4)
                                    : Colors.black.withValues(alpha: 0.06),
                              ),
                            ),
                            showCheckmark: false,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            Text(
              _displayTitle,
              style: const TextStyle(
                color: primaryText,
                fontSize: 22,
                fontWeight: FontWeight.w800,
                height: 1.35,
                letterSpacing: -0.2,
              ),
            ),

            const SizedBox(height: 16),

            if (widget.item.fetchedAt.isNotEmpty)
              Row(
                children: [
                  const Icon(Icons.schedule_rounded, color: mutedText, size: 15),
                  const SizedBox(width: 6),
                  Text(
                    'Updated ${widget.item.fetchedAt}',
                    style: const TextStyle(color: secondaryText, fontSize: 12),
                  ),
                ],
              ),

            const SizedBox(height: 24),

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
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.black.withValues(alpha: 0.07)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.025),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: _isTranslating
                  ? const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: CircularProgressIndicator(color: primaryColor),
                ),
              )
                  : SelectableText(
                _displayDescription,
                textAlign: TextAlign.justify,
                style: const TextStyle(
                  color: Color(0xFF334155),
                  fontSize: 14.5,
                  height: 1.65,
                ),
              ),
            ),

            const SizedBox(height: 24),

            if (widget.item.source.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardBackground,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.black.withValues(alpha: 0.07)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: const Icon(Icons.public_rounded, color: primaryColor, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Source',
                            style: TextStyle(color: mutedText, fontSize: 11, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            widget.item.source,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: primaryText, fontSize: 14, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 20),

            if (widget.item.url.isNotEmpty)
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _openSource,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    disabledBackgroundColor: primaryColor.withValues(alpha: 0.45),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                    width: 21,
                    height: 21,
                    child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                  )
                      : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.open_in_new_rounded, color: Colors.white, size: 19),
                      SizedBox(width: 9),
                      Text(
                        'Read Full Story',
                        style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 24),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: primaryColor.withValues(alpha: 0.12)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.10),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.info_outline_rounded, color: primaryColor, size: 18),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'VoteSense provides election news for civic education and informational purposes. For the complete article, please refer to the original source.',
                      textAlign: TextAlign.justify,
                      style: TextStyle(color: secondaryText, fontSize: 12, height: 1.5),
                    ),
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
}

class ParsedTranslation {
  final String title;
  final String description;
  ParsedTranslation({required this.title, required this.description});
}