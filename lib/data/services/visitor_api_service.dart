import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/errors/api_exception.dart';
import '../models/visitor_model.dart';

class VisitorApiService {
  final http.Client _client;
  final String baseUrl;

  VisitorApiService({
    required this.baseUrl,
    http.Client? client,
  }) : _client = client ?? http.Client();

  Uri _uri([String? id]) {
    final base = baseUrl.replaceFirst(RegExp(r'/$'), '');
    final path = id == null ? base : '$base/${Uri.encodeComponent(id)}';

    return Uri.parse(path);
  }

  Future<dynamic> _request(
      Future<http.Response> Function() call,
      Set<int> acceptedStatuses,
      ) async {
    try {
      final response = await call().timeout(
        const Duration(seconds: 15),
      );

      if (!acceptedStatuses.contains(response.statusCode)) {
        throw ApiException(
          'Request failed (${response.statusCode}). '
              'Please try again.',
          statusCode: response.statusCode,
        );
      }

      if (response.body.trim().isEmpty) return null;

      try {
        return jsonDecode(response.body);
      } on FormatException {
        throw const ApiException(
          'The server returned an invalid response.',
        );
      }
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw const ApiException(
        'The request timed out. Please try again.',
      );
    } on http.ClientException {
      throw const ApiException(
        'Unable to connect to the server. Check your network.',
      );
    } on FormatException {
      throw const ApiException('Invalid API URL.');
    } on Exception {
      throw const ApiException(
        'Unable to connect to the server. Check your network.',
      );
    }
  }

  Future<List<Visitor>> getVisitors() async {
    final result = await _request(
          () => _client.get(_uri()),
      {200},
    );

    if (result is! List) {
      throw const ApiException(
        'Invalid visitor list returned by the server.',
      );
    }

    return result.map((item) {
      if (item is! Map<String, dynamic>) {
        throw const ApiException(
          'Invalid visitor record returned by the server.',
        );
      }
      return Visitor.fromJson(item);
    }).toList();
  }

  Future<Visitor> getVisitor(String id) async {
    final result = await _request(
          () => _client.get(_uri(id)),
      {200},
    );

    if (result is! Map<String, dynamic>) {
      throw const ApiException('Visitor details were invalid.');
    }

    return Visitor.fromJson(result);
  }

  Future<Visitor> createVisitor(Visitor visitor) async {
    final result = await _request(
          () => _client.post(
        _uri(),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(visitor.toJson()),
      ),
      {200, 201},
    );

    if (result is! Map<String, dynamic>) {
      throw const ApiException(
        'Unable to read the created visitor.',
      );
    }

    return Visitor.fromJson(result);
  }

  Future<Visitor> updateVisitor(Visitor visitor) async {
    final result = await _request(
          () => _client.put(
        _uri(visitor.id),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(visitor.toJson()),
      ),
      {200},
    );

    if (result is! Map<String, dynamic>) {
      throw const ApiException(
        'Unable to read the updated visitor.',
      );
    }

    return Visitor.fromJson(result);
  }

  Future<void> deleteVisitor(String id) async {
    await _request(
          () => _client.delete(_uri(id)),
      {200, 204},
    );
  }

  void dispose() {
    _client.close();
  }
}