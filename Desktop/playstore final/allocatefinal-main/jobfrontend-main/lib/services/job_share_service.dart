import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';

import '../config/api_config.dart';
import '../utils/api_json_decode.dart';

/// Share published jobs with one HTTPS smart link (`/share/job/{id}`).
/// That page opens the app when installed, otherwise the Play Store.
class JobShareService {
  JobShareService._();
  static final JobShareService instance = JobShareService._();

  static const String _defaultShareHost = 'https://joballocate.tech';

  String get _base => ApiConfig.baseUrl;

  Future<Map<String, dynamic>> fetchSharePayload(String jobId) async {
    final r = await http.get(
      Uri.parse('$_base/jobs/$jobId/share'),
      headers: {'Accept': 'application/json'},
    );
    final json = decodeApiJsonObject(r);
    if (r.statusCode >= 200 &&
        r.statusCode < 300 &&
        json['success'] == true &&
        json['data'] is Map) {
      return Map<String, dynamic>.from(json['data'] as Map);
    }
    throw Exception(json['message']?.toString() ?? 'Could not load share link');
  }

  Map<String, dynamic> _fallbackPayload({
    required String jobId,
    required String title,
    required String companyName,
    String? location,
  }) {
    final webLink = '$_defaultShareHost/share/job/$jobId';
    final loc = location?.trim();
    final lines = [
      'Check out this job on JobAllocate!',
      '',
      title,
      'at $companyName${loc != null && loc.isNotEmpty ? ' · $loc' : ''}',
      '',
      webLink,
    ];
    return {
      'web_link': webLink,
      'app_link': 'joballocate://job/$jobId',
      'share_text': lines.join('\n'),
    };
  }

  Future<void> shareJob({
    required String jobId,
    required String title,
    required String companyName,
    String? location,
  }) async {
    Map<String, dynamic> payload;
    try {
      payload = await fetchSharePayload(jobId);
    } catch (_) {
      payload = _fallbackPayload(
        jobId: jobId,
        title: title,
        companyName: companyName,
        location: location,
      );
    }

    var text = payload['share_text']?.toString().trim() ?? '';
    final webLink = payload['web_link']?.toString().trim();

    // Prefer a single HTTPS smart link (never raw API / admin URLs alone).
    if (text.isEmpty && webLink != null && webLink.isNotEmpty) {
      text = webLink;
    }
    if (text.isEmpty) {
      text = '$_defaultShareHost/share/job/$jobId';
    }

    // If API still returned a custom-scheme-only share, append/replace with HTTPS.
    if (!text.contains('http://') && !text.contains('https://')) {
      final link = (webLink != null && webLink.startsWith('http'))
          ? webLink
          : '$_defaultShareHost/share/job/$jobId';
      text = '$text\n\n$link';
    }

    await Share.share(text);
  }
}
