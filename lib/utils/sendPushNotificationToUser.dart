import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

Future<void> sendPushNotificationToUser({
  required String recipientFcmToken,
  required String title,
  required String body,
}) async {
  // Replace with your actual PHP backend API endpoint
  final Uri url = Uri.parse('https://wesafe.com.ng/openlawsnig/send_push.php');

  try {
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'recipient_token': recipientFcmToken,
        'title': title,
        'body': body,
      }),
    );

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      debugPrint('Notification Sent Successfully: $responseData');
    } else {
      debugPrint('Failed to send notification. Status: ${response.statusCode}');
      debugPrint('Response: ${response.body}');
    }
  } catch (e) {
    debugPrint('Error calling PHP notification API: $e');
  }
}