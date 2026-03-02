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
Future<List<String>> callApi() async {
  
  String user = "testUser";
  String filePath = "lib/temp_folder/test_clip.mp4";

  try {
    //final result = (await http.get(Uri.http('localhost:5000','/gen_url',{'user':user,'file_path':file_path},)));//.toString();
    final result = (await http.get(Uri.http('localhost:5000','/fetch_incidents',{'user':user},)));

    final List data = jsonDecode(result.body);
    
    return List<String>.from(data.skip(1));
  
  } catch (e) {
    print(e);
    return [];
  }

}

