import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:network_manager/network_manager.dart';
import 'package:network_manager/src/http_method.dart';
import 'package:network_manager/src/target_type.dart';

class MockDio extends Mock implements Dio {

  @override
  BaseOptions get options => BaseOptions();

  @override
  Interceptors get interceptors => Interceptors();

  @override
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
    Object? data,
  }) => super.noSuchMethod(
        Invocation.method(
          #get,
          [path],
          {
            #queryParameters: queryParameters,
            #options: options,
            #cancelToken: cancelToken,
            #onReceiveProgress: onReceiveProgress,
            #data: data,
          },
        ),
        returnValue: Future.value(Response<T>(requestOptions: RequestOptions(path: path))),
      );
}

class TestNetworkManager extends NetworkManager {
  // final Future<List<ConnectivityResult>> Function()? connectivityOverride;
  TestNetworkManager({super.dioClient});
  @override
  @override
  Future<T?> request<T>(
    TargetType target, {
    Map<String, dynamic>? body,
    T Function(dynamic data)? fromJson,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? params,
  }) {
    // Override connectivity check for test
    // if (connectivityOverride != null) {
    //   return connectivityOverride!().then((results) {
    //     if (results.isEmpty || results.every((r) => r == ConnectivityResult.none)) {
    //       throw NetworkManagerException(message: 'No internet connection');
    //     }
    //     return super.request<T>(
    //       target,
    //       body: body,
    //       fromJson: fromJson,
    //       headers: headers,
    //       params: params,
    //     );
    //   });
    // }
    return super.request<T>(
      target,
      body: body,
      fromJson: fromJson,
      headers: headers,
      params: params,
    );
  }
}

class FakeTarget extends TargetType {
  @override
  String get baseUrl => 'https://api.example.com';
  @override
  HttpMethod get httpMethod => HttpMethod.GET;
  @override
  String get endPoint => '/test';
  @override
  bool get isAuthorized => false;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
    // Mock NetworkService.checkConnectivity to always return wifi for all tests
  // setUpAll(() {
  //   NetworkService._connectivity = () async => [ConnectivityResult.wifi];
  // });

  group('NetworkManager', () {
    late MockDio mockDio;
    late TestNetworkManager manager;
    final mockTarget = FakeTarget();
    late String url;

    setUp(() {
      mockDio = MockDio();
      manager = TestNetworkManager(dioClient: mockDio);
      url = mockTarget.baseUrl + mockTarget.endPoint;
    });

    test('returns data on GET success', () async {
      when(
        mockDio.get(
          url,
          queryParameters: anyNamed('queryParameters'),
          data: anyNamed('data'),
        ),
      ).thenAnswer(
        (_) async => Response(
          data: {'result': 'ok'},
          statusCode: 200,
          requestOptions: RequestOptions(path: '/test'),
        ),
      );
      final result = await manager.request<Map<String, dynamic>>(mockTarget);
      expect(result, isA<Map<String, dynamic>>());
      expect(result?['result'], 'ok');

      final intResult = await manager.request(
        mockTarget,
        fromJson: (data) => data,
      );

      expect(intResult, isA<Map<String, dynamic>>());
      // expect(intResult, 22);
    });


    test('throws NetworkManagerException on HTTP error', () async {
      when(mockDio.get(url, queryParameters: anyNamed('queryParameters'), data: anyNamed('data')))
          .thenAnswer((_) async => Response(
                data: {'error': 'bad'},
                statusCode: 404,
                statusMessage: 'Not Found',
                requestOptions: RequestOptions(path: '/test'),
              ));
      expect(
        () => manager.request<Map<String, dynamic>>(mockTarget),
        throwsA(isA<NetworkManagerException>()),
      );
    });

    test('throws NetworkManagerException on DioException', () async {
      when(mockDio.get(url, queryParameters: anyNamed('queryParameters'), data: anyNamed('data')))
          .thenThrow(DioException(
            requestOptions: RequestOptions(path: '/test'),
            message: 'Dio error',
          ));
      expect(
        () => manager.request<Map<String, dynamic>>(mockTarget),
        throwsA(isA<NetworkManagerException>()),
      );
    });

    // test('throws NetworkManagerException on no connectivity', () async {
    //   manager = TestNetworkManager(dioClient: mockDio, connectivityOverride: () async => [ConnectivityResult.none]);
    //   expect(
    //     () => manager.request<Map<String, dynamic>>(mockTarget),
    //     throwsA(predicate((e) => e is NetworkManagerException && e.message == 'No internet connection')),
    //   );
    // });
  });
}
