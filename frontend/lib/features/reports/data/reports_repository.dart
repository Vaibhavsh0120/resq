import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../domain/incident_report.dart';

abstract interface class ReportsRepository {
  Future<String> submit(IncidentReportDraft report);
}

class ApiReportsRepository implements ReportsRepository {
  ApiReportsRepository({http.Client? client})
    : _client = client ?? http.Client();

  static const _baseUrl = String.fromEnvironment(
    'RESQ_API_BASE_URL',
    defaultValue: 'http://localhost:8080',
  );

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
}

class ReportSubmissionException implements Exception {
  const ReportSubmissionException(this.message);
  final String message;
  @override
  String toString() => message;
}
