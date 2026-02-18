export 'auto_test.dart';

import 'dart:convert';
import 'package:http/http.dart' as http;

Future<void> callApi() async {
  final response = await http.get(
    Uri.parse('http://3.250.190.187:8000/run?name=Jackie'),
  );

  final data = jsonDecode(response.body);
  print(data['result']);
}

