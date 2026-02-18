export 'auto_test.dart';

import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'history.dart';

Future<void> callApi() async {
  /*
  final response = await http.get(
    Uri.parse('http://3.250.190.187:8000/run?name=Jackie'),
  );

  final data = jsonDecode(response.body);
  print(data['result']);
  */

  String result = (await http.get(Uri.parse('http://localhost:5000/gen_url'))).toString();

  Incident test = new Incident(
    id: result,
    timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
    cameraName: 'TEST CAMERA',
    severity: IncidentSeverity.critical,
    description: 'TEST INCIDENT',
    reviewed: false,
  );

  print(test.id);

}

