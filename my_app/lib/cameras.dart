export 'cameras.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'main.dart';
//import 'dart:io';

class CameraPage extends StatefulWidget {
  const CameraPage({Key? key}) : super(key: key);

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class Camera {
  
}

class _CameraPageState extends State<CameraPage> {

  @override
  void initState() {
    super.initState();
    //_setupCameraController();
  }

  @override
  void dispose() {
    _disposeCamera();
    super.dispose();
  }

  //List<CameraDescription> _cameras = [];
  //List<CameraDescription> cameras = [];
  CameraController? cameraController;
  int cameraSelectorIndex = 0;
  
  SizedBox testA = SizedBox(
        height: 250,
        child: Center(child: CircularProgressIndicator()),
      );

  List<String> cameraNames = [];
  List<String> cameraDetails = [];
  List<XFile> thumbnails = [];
  int pressToDelete = 0;

  bool userAddingCamera = false;
  bool userViewingCamera = false;
  String errorMsg = '';
  String storePrevCamName = '';
  String storePrevCamDetails = '';

  /// createListView() is called by build() when the user is not
  /// setting up a camera. It creates a list of all active camera
  /// tabs and a button to begin setting up a new camera.
  ListView createListView() {
    return ListView(
      scrollDirection: Axis.vertical,
      children: [  
        for (int i=0; i<cameraNames.length; i++) newCameraTab(cameraNames[i], cameraDetails[i], i),
        Padding(
          padding:EdgeInsets.all(50), 
          child: ElevatedButton(
            style: ButtonStyle(backgroundColor: WidgetStateProperty.all<Color>(Colors.transparent)),
            onPressed: () {switchInstance();},
            child: Text('+ Add Camera'),
          )
        ),
        if (cameraNames.isEmpty) Center(child:Text('You have no cameras setup, why not start now?')),
      ]
    );
  }

  Padding newCameraTab(String cameraName, String cameraDetails, int thumbnailsIndex) {
    return Padding(
      padding:EdgeInsets.all(10),
      child: FloatingActionButton(
        onPressed: () {
          print('$thumbnailsIndex');
          switchInstance_viewCams(thumbnailsIndex); 
        }, 
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: const Color.fromARGB(255, 203, 196, 196),
          ),
          height: 75,
          child: Row(
            children: [
              SizedBox(width:25),
              //Icon(Icons.camera_alt_outlined),
              Padding(
                padding: EdgeInsets.all(10),
                child: SizedBox(
                  height:200, 
                  child: Image.network(thumbnails[thumbnailsIndex].path),
                ),
              ),
              SizedBox(width:25),
              Text(cameraName),
              SizedBox(width: 50),
              Text(cameraDetails)
            ]
          )
        )
      )
    );
  }

  void switchInstance() async {
    if (!userAddingCamera) {
      try {
        await _setupCameraController(0);
      } catch (e) {
        debugPrint(e.toString());
      }
    } else { await _disposeCamera(); }

    if (!mounted) return;
     
    setState(() {userAddingCamera=!userAddingCamera;});
    return;
  }

  void switchInstance_viewCams(int entryPoint) async {
    cameraSelectorIndex = entryPoint;
    if (!userViewingCamera) {
      try {
        await _setupCameraController(entryPoint);
      } catch (e) {
        debugPrint(e.toString());
      }
    } else { await _disposeCamera(); }

    if (!mounted) return;
     
    setState(() {userViewingCamera=!userViewingCamera;});
    return;
  }

  Future<void> _disposeCamera() async {
    if (cameraController != null) {
      await cameraController!.dispose();
      cameraController = null;
    }
  }
  
  Future<void> _setupCameraController(int entryPoint) async {
    priv_cameras = await availableCameras();
    if (priv_cameras.isNotEmpty) {
      setState(() {
        cameras = priv_cameras;
        cameraController = CameraController(
          entryPoint == 0 ? priv_cameras[cameraSelectorIndex] : priv_cameras[entryPoint], 
          ResolutionPreset.low,
          enableAudio: false,
        );
      });
      cameraController?.initialize().then((_) {
        setState(() {});
      });
    }
  }

  void changeCam(int i) {
    if (cameraSelectorIndex+i >= cameras.length) {
      cameraSelectorIndex = 0;
    } else if (cameraSelectorIndex+i < 0) {
      cameraSelectorIndex = cameras.length - 1;
    } else {
      cameraSelectorIndex += i;
    }

    debugPrint(cameraSelectorIndex.toString());

    switchInstance();
    Future.delayed(Duration(seconds: 1), () {switchInstance();});
    debugPrint(thumbnails.length.toString());
  }
  
  /// _buildUI() returns a loading thingy if it cannot find
  /// any cameras, otherwise it will automatically load
  /// the first camera that the system is connected to, plus
  /// buttons to switch cameras.
  Widget _buildUI() {
    if (cameraController == null || cameraController?.value.isInitialized == false) {
      return const Center(child: CircularProgressIndicator());
    } 
    
    return Padding(
      padding: EdgeInsetsGeometry.fromLTRB(50, 5, 50, 5),
      child: 
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            IconButton(
              icon: Icon(Icons.chevron_left), 
              color: Colors.black,
              onPressed: () {changeCam(-1);},
            ),
        
            Expanded(
              child:
                AspectRatio(
                  aspectRatio: cameraController!.value.aspectRatio,
                  child: CameraPreview(cameraController!),
                )
            ),

            IconButton(
              icon: Icon(Icons.chevron_right), 
              color: Colors.black, 
              onPressed: () {changeCam(1);},
            ),
          ]
        )
    );
  }

  Widget _displayOneCamera() {
    if (cameraController == null || cameraController?.value.isInitialized == false) {
      return const Center(child: CircularProgressIndicator());
    } 

    return Padding(
      padding: EdgeInsetsGeometry.fromLTRB(50, 5, 50, 5),
      child: 
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child:
                AspectRatio(
                  aspectRatio: cameraController!.value.aspectRatio,
                  child: CameraPreview(cameraController!),
                )
            ),
          ]
        )
    );
  }

  /// addCamera() is called by addNewCameraTab()
  /// when the user finishes camera setup. 
  Future<void> addCamera(String cameraName, String cameraDetail) async {
    storePrevCamDetails = cameraDetail;
    storePrevCamName = cameraName;

    setState(() {
      if (cameraName == '' || cameraDetail == '') {
        errorMsg = "Camera Details Required";
        return;
      } else if (cameraNames.contains(cameraName)) {
        errorMsg = "Camera Name Already Exists";
        return;
      }

      storePrevCamDetails = '';
      storePrevCamName = '';
      errorMsg = '';

      cameraNames.add(cameraName);
      cameraDetails.add(cameraDetail);

      //await addToThumbnails();
      
      //switchInstance();
    });
    await addToThumbnails();
    switchInstance();
    
  }

  Future<void> addToThumbnails() async {
    XFile file = await cameraController!.takePicture();
    Future.delayed(Duration(milliseconds: 500));
    setState(() {thumbnails.add(file);});
    print(thumbnails);
  }

  /// This is the sub-page to add a new camera.
  /// It contains fields to submit camera details.
  ListView addNewCameraTab() {
    final myControllerA = TextEditingController();
    final myControllerB = TextEditingController();
    if (storePrevCamName != '') myControllerA.text = storePrevCamName;
    if (storePrevCamDetails != '') myControllerB.text = storePrevCamDetails;

    return ListView(
      scrollDirection: Axis.vertical,
      children: [
        //Page Header
        Padding(
          padding:EdgeInsetsGeometry.fromLTRB(10,0,0,0),
          child: Text('Camera Setup'),
        ),

        //Input Field A
        Padding(
          padding:EdgeInsets.all(10),
          child:
            TextField(
              controller: myControllerA,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Enter camera name (e.g. Freezer Aisle Camera)',
              )
            ),
        ),

        //Input Field B
        Padding(
          padding:EdgeInsets.all(10),
          child: TextField(
            controller: myControllerB,
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Enter Camera Details (e.g. Active From 09:00 - 17:00)',
            )
          ),
        ),

        //Error Message
        Padding(
          padding:EdgeInsetsGeometry.fromLTRB(10,0,0,0),
          child: Text(errorMsg, style:TextStyle(color:Colors.red)),
        ),
        
        //provide details on currently selected camera
        Center(child:Text(cameras[cameraSelectorIndex].name.toString())),

        //something, list of active cams
        _buildUI(),

        //Button A
        Padding(
          padding:EdgeInsets.all(15), 
          child: FloatingActionButton(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            onPressed: () {addCamera(myControllerA.text, myControllerB.text);},
            child: Text('Finish Camera Setup'),
          )
        ),
        
        //Button B
        Padding(
          padding:EdgeInsets.all(15), 
          child: FloatingActionButton(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            onPressed: () {switchInstance();},
            child: Text('Cancel'),
          )
        )
      ]
    );
  }
  
  ListView viewingCameraTab() {
    pressToDelete = 0;
    return ListView(
      scrollDirection: Axis.vertical,
      children: [
        _displayOneCamera(),
        Center(child:Text(cameraNames[cameraSelectorIndex].toString())),
        Center(child:Text(cameraDetails[cameraSelectorIndex].toString())),
        Padding(
          padding:EdgeInsets.all(15), 
          child: FloatingActionButton(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            onPressed: () {switchInstance_viewCams(0); },
            child: Text('Cancel'),
          )
        ),
        Padding(
          padding:EdgeInsets.all(15), 
          child: FloatingActionButton(
            backgroundColor: Colors.red,
            foregroundColor: Colors.black,
            onPressed: () { 
              pressToDelete += 1;
              if (pressToDelete >= 2) {
                pressToDelete = 0;
                cameraNames.removeAt(cameraSelectorIndex);
                cameraDetails.removeAt(cameraSelectorIndex);
                thumbnails.removeAt(cameraSelectorIndex);
                switchInstance_viewCams(0);
              }
            },
            child: Text('Delete Camera (Press Twice)'),
          )
        )
      ]
    );
  }

  @override
  Widget build(BuildContext context) {
    if (userAddingCamera) {
      return addNewCameraTab();
    } else if (userViewingCamera) {
      return viewingCameraTab();
    } else {
      return createListView();
    }
  }
}
