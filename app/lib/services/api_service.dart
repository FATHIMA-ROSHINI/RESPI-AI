import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/analysis_result.dart';

class ApiService {
  static const String _defaultIp = '10.148.71.238';
  static String? _computerIp;

  static Future<void> init() async {
    _computerIp = await _discoverBackendIp();
    debugPrint('Backend IP discovered: $_computerIp');
  }

  static Future<String> _discoverBackendIp() async {
    try {
      final response = await http
          .get(Uri.parse('http://$_defaultIp:8000/health'))
          .timeout(const Duration(seconds: 3));
      
      if (response.statusCode == 200) {
        return _defaultIp;
      }
    } catch (e) {
      debugPrint('Default IP failed, scanning network...');
    }

    for (int i = 1; i <= 254; i++) {
      try {
        final ip = '192.168.1.$i';
        final response = await http
            .get(Uri.parse('http://$ip:8000/health'))
            .timeout(const Duration(milliseconds: 500));
        
        if (response.statusCode == 200) {
          debugPrint('Found backend at: $ip');
          return ip;
        }
      } catch (_) {
        continue;
      }
    }

    return _defaultIp;
  }

  static String get _baseUrl {
    final ip = _computerIp ?? _defaultIp;
    return 'http://$ip:8000';
  }

  static Future<String> get _wsUrl async {
    final ip = _computerIp ?? _defaultIp;
    return 'ws://$ip:8000/api/ws-analyze';
  }

  static Future<AnalysisResult> analyzeAudio(String filePath) async {
    if (_computerIp == null) await init();
    
    final baseUrl = _computerIp ?? _defaultIp;
    final uri = Uri.parse('http://$baseUrl:8000/api/analyze');
    final request = http.MultipartRequest('POST', uri);

    request.files.add(await http.MultipartFile.fromPath('file', filePath));

    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return AnalysisResult.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to analyze audio: ${response.body}');
      }
    } catch (e) {
      rethrow;
    }
  }

  static Future<WebSocketChannel> connectStreaming() async {
    if (_computerIp == null) await init();
    
    final url = await _wsUrl;
    return WebSocketChannel.connect(Uri.parse(url));
  }
}