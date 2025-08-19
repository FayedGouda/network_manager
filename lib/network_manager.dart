import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:network_manager/src/target_type.dart';
import 'package:network_manager/src/http_method.dart';
import 'package:network_manager/src/network_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

export 'src/target_type.dart';
export 'src/http_method.dart';
/// Custom exception for network errors
class NetworkManagerException implements Exception {
  final int? statusCode;
  final String message;
  final dynamic data;

  NetworkManagerException({this.statusCode, required this.message, this.data});

  @override
  String toString() => 'NetworkManagerException($statusCode): $message';
}

typedef JSON = Map<String, dynamic>;

abstract class NetworkManager {
  final Dio dio;
  NetworkManager({Dio? dioClient, String? token, String? lang}) : dio = dioClient ?? Dio() {
    dio.options.headers['content-Type'] = 'text/plain; charset=UTF-8';
    if (token != null) dio.options.headers['Authorization'] = 'Bearer $token';
    if (lang != null) dio.options.headers['Accept-Language'] = lang;
    dio.options.connectTimeout = const Duration(seconds: 30);
    dio.interceptors.add(
      PrettyDioLogger(
        requestHeader: true,
        requestBody: true,
        responseBody: true,
        responseHeader: false,
        error: true,
        compact: true,
        maxWidth: 90,
      ),
    );
  }

  /// High-level request method using TargetType abstraction
  /// Sends a network request and returns a response of type [T].
  ///
  /// Returns a [Future] that completes with the response data of type [T], or `null` if the request fails or no data is returned.
  ///
  /// The specific behavior, such as request method, headers, and body, should be defined in the implementation.
  ///
  /// Type parameter [T] represents the expected response type.
  Future<T?> request<T>(
    TargetType target, {
    T Function(dynamic data)? fromJson,
    Map<String, dynamic>? params,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? body,
  }) async {
    // Check connectivity before making request
    // final connectivity = await NetworkService.checkConnectivity();
    // if (connectivity.isEmpty ||
    //     connectivity.every((result) => result == ConnectivityResult.none)) {
    //   throw NetworkManagerException(message: 'No internet connection');
    // }

    final String url = target.baseUrl + target.endPoint;

    // Set headers
    if (headers != null) {
      dio.options.headers.addAll(headers);
    }
    // Optionally add authorization logic here
    // if (target.isAuthorized) { ... }

    try {
      Response response;
      switch (target.httpMethod) {
        case HttpMethod.GET:
          response = await dio.get(
            url,
            queryParameters: params,
            data: _jsonEncode(body),
          );
          break;
        case HttpMethod.POST:
          response = await dio.post(
            url,
            queryParameters: params,
            data: _jsonEncode(body),
          );
          break;
        case HttpMethod.PUT:
          response = await dio.put(
            url,
            queryParameters: params,
            data: _jsonEncode(body),
          );
          break;
        case HttpMethod.DELETE:
          response = await dio.delete(
            url,
            queryParameters: params,
            data: _jsonEncode(body),
          );
          break;
        case HttpMethod.PATCH:
          response = await dio.patch(
            url,
            queryParameters: params,
            data: _jsonEncode(body),
          );
          break;
      }

      // Handle HTTP status code errors
      if (response.statusCode == null || response.statusCode! >= 400) {
        throw NetworkManagerException(
          statusCode: response.statusCode,
          message: response.statusMessage ?? 'HTTP error',
          data: response.data,
        );
      }

      if (fromJson != null && response.data != null) {
        return fromJson(response.data);
      }
      return response.data as T?;
    } on DioException catch (e) {
      throw NetworkManagerException(
        statusCode: e.response?.statusCode,
        message: e.message ?? 'Network error',
        data: e.response?.data,
      );
    } catch (e) {
      throw NetworkManagerException(message: e.toString());
    }
  }

  String _jsonEncode(JSON? json) {
    return jsonEncode(json);
  }

  // Optionally, add generic response parsing helpers here for testability
}
