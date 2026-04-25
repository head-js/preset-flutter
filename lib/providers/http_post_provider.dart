import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:preset/api/api_client.dart';

class HttpPostState {
  const HttpPostState({
    this.isLoading = false,
    this.response = '',
  });

  final bool isLoading;
  final String response;

  HttpPostState copyWith({
    bool? isLoading,
    String? response,
  }) {
    return HttpPostState(
      isLoading: isLoading ?? this.isLoading,
      response: response ?? this.response,
    );
  }
}

class HttpPostNotifier extends StateNotifier<HttpPostState> {
  HttpPostNotifier() : super(const HttpPostState());

  final ApiClient _apiClient = ApiClient.withDefaults();

  Future<void> sendPost(Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true, response: '');

    try {
      final response = await _apiClient.postTest(data);

      state = state.copyWith(
        isLoading: false,
        response:
            'Success!\n'
            'URL: ${response.data.url}\n'
            'Origin: ${response.data.origin}\n'
            'Data: ${response.data.json}',
      );
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        response:
            'Error: ${e.type.toString()}\n'
            'Message: ${e.message}\n'
            'StatusCode: ${e.response?.statusCode ?? "-"}',
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        response: 'Error: ${e.toString()}',
      );
    }
  }
}

final httpPostNotifierProvider =
    StateNotifierProvider<HttpPostNotifier, HttpPostState>((ref) {
  return HttpPostNotifier();
});