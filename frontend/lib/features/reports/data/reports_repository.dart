import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../../../core/config/app_config.dart';

import '../domain/incident_report.dart';

abstract interface class ReportsRepository {
  Future<String> submit(IncidentReportDraft report);
  Future<void> uploadPhoto({
    required String reportId,
    required List<int> bytes,
    required String filename,
  });
}

class ApiReportsRepository implements ReportsRepository {
  ApiReportsRepository({http.Client? client})
    : _client = client ?? http.Client();

  static const _baseUrl = AppConfig.apiBaseUrl;

  final http.Client _client;

  @override
  Future<String> submit(IncidentReportDraft report) async {
    final token = await FirebaseAuth.instance.currentUser?.getIdToken();
    if (token == null) {
      throw const ReportSubmissionException('Sign in to submit a report.');
    }
    final response = await _client.post(
      Uri.parse('$_baseUrl/v1/reports'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(report.toJson()),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw const ReportSubmissionException(
        'The report could not be submitted. Try again.',
      );
    }
    return (jsonDecode(response.body) as Map<String, dynamic>)['id'] as String;
  }

  @override
  Future<void> uploadPhoto({
    required String reportId,
    required List<int> bytes,
    required String filename,
  }) async {
    final token = await FirebaseAuth.instance.currentUser?.getIdToken();
    if (token == null) {
      throw const ReportSubmissionException('Sign in to upload a photo.');
    }
    final request =
        http.MultipartRequest(
            'POST',
            Uri.parse('$_baseUrl/v1/reports/$reportId/photo-upload'),
          )
          ..headers['Authorization'] = 'Bearer $token'
          ..files.add(
            http.MultipartFile.fromBytes('photo', bytes, filename: filename),
          );
    final response = await request.send();
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw const ReportSubmissionException(
        'The report was saved, but its photo could not be uploaded. Try again.',
      );
    }
  }
}

class ReportSubmissionException implements Exception {
  const ReportSubmissionException(this.message);
  final String message;
  @override
  String toString() => message;
}
