import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:http/http.dart' as http;
import 'package:jippydriver_driver/constant/constant.dart';
import 'package:jippydriver_driver/themes/app_them_data.dart';
import 'package:jippydriver_driver/utils/preferences.dart';

class TermsAndConditionScreen extends StatefulWidget {
  final String? type;

  const TermsAndConditionScreen({super.key, this.type});

  @override
  State<TermsAndConditionScreen> createState() => _TermsAndConditionScreenState();
}

class _TermsAndConditionScreenState extends State<TermsAndConditionScreen> {
  String _content = '';
  bool _loading = true;

  bool get _isPrivacy => widget.type == "privacy";

  @override
  void initState() {
    super.initState();
    _loadContent();
  }

  String _sanitizeHtml(String input) {
    // Remove control characters and invalid surrogate code units that can break parsers
    return input.replaceAll(RegExp(r'[\u0000-\u001F\uD800-\uDFFF]'), '');
  }

  Future<void> _loadContent() async {
    // Use in-memory Constant first (set by FireStoreUtils.getSettings at login/home)
    String content =
        _isPrivacy ? Constant.privacyPolicy : Constant.termsAndConditions;

    // If empty, fall back to cached SharedPreferences values
    if (content.isEmpty) {
      final cached = _isPrivacy
          ? Preferences.getString(Preferences.cachedPrivacyPolicy)
          : Preferences.getString(Preferences.cachedTermsAndConditions);
      content = cached;
    }

    // If still empty, fetch settings directly using raw http (bypassing HttpClientService encoding issues)
    if (content.isEmpty) {
      try {
        final uri = Uri.parse('${Constant.baseUrl}driver-sql/settings');
        final response =
            await http.get(uri).timeout(const Duration(seconds: 10));
        if (response.statusCode == 200) {
          // Clean invalid chars and surrogate pairs before decoding
          final cleaned = String.fromCharCodes(
            response.body.runes.where(
              (int rune) =>
                  rune == 0x9 || // tab
                  rune == 0xA || // LF
                  rune == 0xD || // CR
                  (rune >= 0x20 &&
                      rune <= 0x10FFFF &&
                      (rune < 0xD800 || rune > 0xDFFF)),
            ),
          );

          final jsonResponse =
              json.decode(cleaned) as Map<String, dynamic>;
          final data =
              jsonResponse['data'] as Map<String, dynamic>?;
          if (data != null) {
            String html = '';
            if (_isPrivacy) {
              final pp = data['privacyPolicy'] as Map<String, dynamic>?;
              html = (pp?['privacy_policy'] ?? '').toString();
            } else {
              final tc = data['termsAndConditions'] as Map<String, dynamic>?;
              html = (tc?['termsAndConditions'] ?? '').toString();
            }

            if (html.isNotEmpty) {
              content = html;
              // Also update global constants & cache for next time
              if (_isPrivacy) {
                Constant.privacyPolicy = html;
                await Preferences.setString(
                    Preferences.cachedPrivacyPolicy, html);
              } else {
                Constant.termsAndConditions = html;
                await Preferences.setString(
                    Preferences.cachedTermsAndConditions, html);
              }
            }
          }
        }
      } catch (_) {
        // Swallow network/parse errors in production; we'll just show whatever we have
      }
    }

    if (mounted) {
      final sanitized = _sanitizeHtml(content);
      setState(() {
        _content = sanitized;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppThemeData.grey50,
      appBar: AppBar(
        backgroundColor: AppThemeData.grey50,
        elevation: 0,
        title: Text(
          _isPrivacy ? 'Privacy Policy' : 'Terms & Conditions',
          style: const TextStyle(color: Colors.black87),
        ),
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Html(
                  shrinkWrap: true,
                  data: _content,
                ),
              ),
      ),
    );
  }
}
