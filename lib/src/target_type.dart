
import 'package:network_manager/src/http_method.dart';

abstract class TargetType {

  String get baseUrl;

  HttpMethod get httpMethod;

  String get endPoint;

  bool get isAuthorized;

}
