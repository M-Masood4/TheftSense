export 'cameras.dart';

import 'package:flutter/material.dart';

class CameraPage extends StatefulWidget {
  const CameraPage({Key? key}) : super(key: key);

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {

  List<Widget> listChildren = [];
  List<String> cameraNames = [];

  ListView createListView() {
    //createButton();
    return ListView(
      scrollDirection: Axis.vertical,
      children: [
        for (int i=0; i<cameraNames.length; i++) newCameraTab(cameraNames[i]),
        Padding(
          padding:EdgeInsets.all(50), 
          child: ElevatedButton(
            style: ButtonStyle(backgroundColor: WidgetStateProperty.all<Color>(Colors.transparent)),
            onPressed: AddCamera,
            child: Text('+ Add Camera'),
          )
        )
      ]
    );
  }

  Padding newCameraTab(String cameraName) {
    return Padding(
      padding:EdgeInsets.all(10), 
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: const Color.fromARGB(255, 203, 196, 196),
        ),
        height: 75,
        child: Row(
          children: [
            SizedBox(width:25),
            Icon(Icons.camera_alt_outlined),
            SizedBox(width:25),
            Text(cameraName),
            SizedBox(width: 50),
            Text('Camera Details')
          ]
        )
      )
    );
  }

  void AddCamera() {
    setState(() {
      int num = cameraNames.length;
      cameraNames.add('Camera $num');
    });
  }

  void createButton() {
    if (listChildren.isEmpty) {
      print('listChildren is empty');
      Padding button = Padding(
        padding:EdgeInsets.all(50), 
        child: ElevatedButton(
          style: ButtonStyle(backgroundColor: WidgetStateProperty.all<Color>(Colors.transparent)),
          onPressed: AddCamera,
          child: Text('+ Add Camera'),
        )
      );
      listChildren.add(button);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return createListView();
  }
}
