import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

Future<Response<dynamic>> api(String name,
    {String method = "GET", dynamic data}) async {
  return await Dio().request("http://blog.junwen38.com:5000/api" + name,
      data: data, options: Options(method: method));
}

void handleError(BuildContext context, DioError e, {String operation = "操作"}) {
  if (e.response == null) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(e.message),
    ));
  } else {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text("HTTP${e.response.statusCode}: $operation失败"),
    ));
  }
}
