export 'cameras.dart';

import 'package:flutter/material.dart';

class CameraPage extends StatefulWidget {
  const CameraPage({Key? key}) : super(key: key);

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {

  List<String> cameraNames = [];
  List<String> cameraDetails = [];

  bool userAddingCamera = false;

  ListView createListView() {
    //createButton();
    return ListView(
      scrollDirection: Axis.vertical,
      children: [
        for (int i=0; i<cameraNames.length; i++) newCameraTab(cameraNames[i], cameraDetails[i]),
        Padding(
          padding:EdgeInsets.all(50), 
          child: ElevatedButton(
            style: ButtonStyle(backgroundColor: WidgetStateProperty.all<Color>(Colors.transparent)),
            onPressed: switchInstance,
            child: Text('+ Add Camera'),
          )
        )
      ]
    );
  }

  Padding newCameraTab(String cameraName, String cameraDetails) {
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
            Text(cameraDetails)
          ]
        )
      )
    );
  }

  void switchInstance() {
    setState(() {userAddingCamera=!userAddingCamera;});
    return;
  }

  void addCamera(String cameraName, String cameraDetail) {
    if (cameraName == '' || cameraDetails == '') {return;}
    setState(() {
      cameraNames.add(cameraName);
      cameraDetails.add(cameraDetail);
      switchInstance();
    });
  }
  
  ListView addNewCameraTab() {
    final myControllerA = TextEditingController();
    final myControllerB = TextEditingController();

    return ListView(
      scrollDirection: Axis.vertical,
      children: [
        Padding(
          padding:EdgeInsets.all(20),
          child:
            TextField(
              controller: myControllerA,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Enter camera name (e.g. Freezer Aisle Camera)',
              )
            ),
        ),
        Padding(
          padding:EdgeInsets.all(20),
          child: TextField(
            controller: myControllerB,
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Enter Camera Details (e.g. Active From 09:00 - 17:00)',
            )
          ),
        ),
        Padding(
          padding:EdgeInsets.all(25), 
          child: FloatingActionButton(
            onPressed: () {addCamera(myControllerA.text, myControllerB.text);},
            child: Text('Finish Camera Setup'),
          )
        ),
        Padding(
          padding:EdgeInsets.all(25), 
          child: FloatingActionButton(
            onPressed: () {switchInstance();},
            child: Text('Cancel'),
          )
        )
      ]
    );
  }
  
  @override
  Widget build(BuildContext context) {
    if (userAddingCamera) {
      return addNewCameraTab();
    } else {
      return createListView();
    }
  }
}
