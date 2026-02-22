export 'auto_test.dart';

import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'history.dart';

/// callApi() calls the function in the flask app
/// to upload a video to the S3 bucket and generate
/// a url which is used as the id in the new incident.
/// NOTE: Flask app must be running first, flutter web
/// can't start flask on its own so manually run it
/// first with: python py_gen_vid_url.py
Future<void> callApi() async {
  
  String user = "Jack";
  String file_path = "lib/temp_folder/test_clip.mp4";
  //C:\Users\Jack\OneDrive\Desktop\Team_Software_Project_New\GroupProject\my_app\lib\temp_folder\test_clip.mp4
  //String result = (await http.get(Uri.parse('http://localhost:5000/gen_url?user=$user&file_path=$file_path'))).toString();

  final result = (await http.get(Uri.http('localhost:5000','/gen_url',{'user':user,'file_path':file_path},)));//.toString();


  Incident test = new Incident(
    id: "e",
    timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
    cameraName: 'TEST CAMERA',
    severity: IncidentSeverity.critical,
    description: 'TEST INCIDENT',
    reviewed: false,
  );

  print('debug: ${result.body}');
  print('debug: ${test.id}');

}

