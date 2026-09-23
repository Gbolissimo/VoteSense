import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../../utils/globals.dart';

class ClaimVerificationScreen extends StatefulWidget {
  const ClaimVerificationScreen({super.key});

  @override
  State<ClaimVerificationScreen> createState() => _ClaimVerificationScreenState();
}

class _ClaimVerificationScreenState extends State<ClaimVerificationScreen> {
  final TextEditingController _claimController = TextEditingController();

  bool _isLoading = false;
  bool _isConfigLoading = true;

  String? _fetchedApiKey;
  String? _fetchedApiVersion;
  String? _fetchedModel;

  XFile? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  VerificationResult? _verificationResult;

  // Updated to primary green and light mode backgrounds
  static const Color primaryColor = Color(0xFF22C55E);
  static const Color lightBackground = Color(0xFFF8FAFC);
  static const Color cardBackground = Colors.white;

  @override
  void initState() {
    super.initState();
    _loadConfiguration();
  }

  Future<void> _loadConfiguration() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('AI').doc('api').get();
      if (doc.exists) {
        setState(() {
          _fetchedApiKey = doc['key'];
          _fetchedApiVersion = doc['version'] ?? 'v1beta';
          _fetchedModel = doc['model'] ?? 'gemini-2.5-flash';
          _isConfigLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Config Error: $e");
      setState(() => _isConfigLoading = false);
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = pickedFile;
      });
    }
  }

  Future<void> _verifyClaim() async {
    final text = _claimController.text.trim();
    if ((text.isEmpty && _selectedImage == null) || _isLoading || _fetchedApiKey == null) return;

    setState(() {
      _isLoading = true;
      _verificationResult = null;
    });

    try {
      final result = await _callGeminiVerificationApi(text);
      if (mounted) {
        setState(() {
          _verificationResult = result;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Verification Error: $e");
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to verify claim. Please try again.')),
        );
      }
    }
  }

  Future<VerificationResult> _callGeminiVerificationApi(String claimText) async {
    final url = Uri.parse('https://generativelanguage.googleapis.com/$_fetchedApiVersion/models/$_fetchedModel:generateContent?key=$_fetchedApiKey');

    final String systemInstruction = '''
You are VoteSense AI, an expert election and civic fact-checker for Nigeria. 
Analyze the provided text claim or image description for accuracy regarding Nigerian elections, political statements, or civic procedures.
You must categorize the status strictly into one of three options:
1. "true" (Accurate and verified by facts, Electoral Act, or official INEC sources)
2. "unverified" (False, misleading, fabricated, or lacks concrete evidence/proof)
3. "stale" (Outdated information, old news, or historically accurate at a past date but no longer applicable to current electoral laws/guidelines)

Return your response EXCLUSIVELY as a valid JSON object with no extra conversational text or markdown formatting blocks around it if possible, using this exact format:
{
  "status": "true" | "unverified" | "stale",
  "summary": "Short 1-2 sentence breakdown of the verification.",
  "authority": "Relevant legal authority such as Section X of the Electoral Act 2022, INEC Guidelines, or 1999 Constitution."
}
''';

    List<dynamic> parts = [];

    if (_selectedImage != null) {
      final bytes = await _selectedImage!.readAsBytes();
      final base64Image = base64Encode(bytes);
      parts.add({
        "inline_data": {
          "mime_type": "image/jpeg",
          "data": base64Image
        }
      });
    }

    parts.add({
      "text": claimText.isEmpty ? "Analyze the attached image/flyer for election fact-checking." : claimText
    });

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "system_instruction": {"parts": [{"text": systemInstruction}]},
        "contents": [
          {
            "role": "user",
            "parts": parts
          }
        ],
        "generationConfig": {
          "temperature": 0.2,
          "responseMimeType": "application/json"
        }
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final rawJsonString = data['candidates']?[0]?['content']?['parts']?[0]?['text'] ?? '{}';

      final cleanedJsonString = rawJsonString.replaceAll('```json', '').replaceAll('```', '').trim();
      final parsedData = jsonDecode(cleanedJsonString);

      return VerificationResult(
        status: parsedData['status'] ?? 'unverified',
        summary: parsedData['summary'] ?? 'No verification summary provided.',
        authority: parsedData['authority'] ?? 'INEC Guidelines / Electoral Act',
      );
    } else {
      throw Exception('API Error: ${response.statusCode}');
    }
  }

  void _resetForm() {
    setState(() {
      _claimController.clear();
      _selectedImage = null;
      _verificationResult = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isConfigLoading) {
      return const Scaffold(
        backgroundColor: lightBackground,
        body: Center(child: CircularProgressIndicator(color: primaryColor)),
      );
    }

    return Scaffold(
      backgroundColor: lightBackground,
      appBar: AppBar(
        backgroundColor: cardBackground,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1E293B), size: 18),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: const Text('Claim Verification', style: TextStyle(color: Color(0xFF1E293B), fontSize: 18, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Verify Election & Civic Claims',
              style: TextStyle(color: Color(0xFF1E293B), fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            const Text(
              'Input a text statement or upload a screenshot/flyer to check authenticity against Nigerian electoral laws.',
              style: TextStyle(color: Color(0xFF64748B), fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 20),

            // Input TextField Card
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cardBackground,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _claimController,
                maxLines: 4,
                style: const TextStyle(color: Color(0xFF1E293B), fontSize: 14),
                decoration: const InputDecoration(
                  hintText: 'e.g., Can voters use digital copies of their PVCs to vote on election day?',
                  hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Image Picker Section
            if (_selectedImage != null)
              Stack(
                children: [
                  Container(
                    height: 150,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      image: DecorationImage(
                        image: FileImage(File(_selectedImage!.path)),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: CircleAvatar(
                      backgroundColor: Colors.black54,
                      child: IconButton(
                        icon: const Icon(Icons.close, color: Colors.white, size: 18),
                        onPressed: () => setState(() => _selectedImage = null),
                      ),
                    ),
                  ),
                ],
              )
            else
              OutlinedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.image_outlined, color: primaryColor),
                label: const Text('Upload Image / Flyer', style: TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.w600)),
                style: OutlinedButton.styleFrom(
                  backgroundColor: cardBackground,
                  side: BorderSide(color: Colors.black.withValues(alpha: 0.12)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),

            const SizedBox(height: 24),

            // Verify Button
            ElevatedButton(
              onPressed: _isLoading ? null : _verifyClaim,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                elevation: 4,
                shadowColor: primaryColor.withValues(alpha: 0.3),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: _isLoading
                  ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              )
                  : const Text('Verify Claim', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            ),

            const SizedBox(height: 24),

            // Results Section
            if (_verificationResult != null) _buildResultCard(),

            const SizedBox(height: 24),

          ],
        ),
      ),
    );
  }

  Widget _buildResultCard() {
    final status = _verificationResult!.status.toLowerCase();

    Color statusColor;
    String statusLabel;
    IconData statusIcon;

    if (status == 'true') {
      statusColor = Colors.green[700]!;
      statusLabel = 'VERIFIED TRUE';
      statusIcon = Icons.check_circle_rounded;
    } else if (status == 'stale') {
      statusColor = Colors.orange[800]!;
      statusLabel = 'STALE / OUTDATED';
      statusIcon = Icons.history_rounded;
    } else {
      statusColor = Colors.redAccent;
      statusLabel = 'UNVERIFIED / FALSE';
      statusIcon = Icons.cancel_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withValues(alpha: 0.4), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(statusIcon, color: statusColor, size: 22),
              const SizedBox(width: 8),
              Text(
                statusLabel,
                style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 15, letterSpacing: 0.5),
              ),
            ],
          ),
          Divider(color: Colors.black.withValues(alpha: 0.08), height: 24),
          const Text('Analysis Summary:', style: TextStyle(color: Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(
            _verificationResult!.summary,
            style: const TextStyle(color: Color(0xFF1E293B), fontSize: 14, height: 1.4),
          ),
          const SizedBox(height: 16),
          const Text('Legal Authority / Source:', style: TextStyle(color: Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(
            _verificationResult!.authority,
            style: const TextStyle(color: primaryColor, fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: _resetForm,
              icon: const Icon(Icons.refresh, size: 16, color: Color(0xFF64748B)),
              label: const Text('Check Another Claim', style: TextStyle(color: Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.w600)),
            ),
          )
        ],
      ),
    );
  }
}

class VerificationResult {
  final String status;
  final String summary;
  final String authority;

  VerificationResult({required this.status, required this.summary, required this.authority});
}