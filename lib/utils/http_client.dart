import 'package:dio/dio.dart';

class HttpClient {
  HttpClient._() {
    _dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: <String, dynamic>{
        'Content-Type': 'application/json',
      },
    ));
  }

  static final HttpClient _instance = HttpClient._();

  static Dio get instance => _instance._dio;

  late final Dio _dio;
}
