import 'package:dio/dio.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:retrofit/retrofit.dart';
import 'package:preset/utils/http_client.dart';

part 'api_client.g.dart';

@RestApi(baseUrl: 'https://httpbin.org')
abstract class ApiClient {
  factory ApiClient(Dio dio, {String? baseUrl}) = _ApiClient;

  factory ApiClient.withDefaults() => ApiClient(HttpClient.instance);

  @POST('/post')
  Future<HttpResponse<HttpBinResponse>> postTest(
    @Body() Map<String, dynamic> data,
  );
}

@JsonSerializable()
class HttpBinResponse {
  const HttpBinResponse({
    this.args,
    this.data,
    this.files,
    this.form,
    this.headers,
    this.json,
    this.origin,
    this.url,
  });

  factory HttpBinResponse.fromJson(Map<String, dynamic> json) =>
      _$HttpBinResponseFromJson(json);

  final Map<String, dynamic>? args;
  final dynamic data;
  final Map<String, dynamic>? files;
  final Map<String, dynamic>? form;
  final Map<String, dynamic>? headers;
  final dynamic json;
  final String? origin;
  final String? url;

  Map<String, dynamic> toJson() => _$HttpBinResponseToJson(this);
}
