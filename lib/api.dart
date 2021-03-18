import 'package:dio/dio.dart';

Future<Response<dynamic>> api(String name,
    {String method = "GET", dynamic data}) async {
  return await Dio().request("http://blog.junwen38.com:5000/api" + name,
      data: data, options: Options(method: method));
}
