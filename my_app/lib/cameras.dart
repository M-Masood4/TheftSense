export 'cameras.dart';

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'main.dart';

class CameraPage extends StatefulWidget {
  const CameraPage({Key? key}) : super(key: key);

  @override
  State<CameraPage> createState() => _CameraPageState();
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
  
  SizedBox testA = SizedBox(
        height: 250,
        child: Center(child: CircularProgressIndicator()),
      );

  List<String> cameraNames = [];
  List<String> cameraDetails = [];

  bool userAddingCamera = false;
  String errorMsg = '';
  String storePrevCamName = '';
  String storePrevCamDetails = '';

  //This is the list of cameras
  ListView createListView() {
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

  void switchInstance() async {

    //priv_cameras = await availableCameras();

    if (!userAddingCamera) {
      try {
        await _setupCameraController();
      } catch (e) {
        debugPrint(e.toString());
      }
    } else { await _disposeCamera(); }

    if (!mounted) return;
     
    setState(() {userAddingCamera=!userAddingCamera;});
    return;
  }

  Future<void> _disposeCamera() async {
    if (cameraController != null) {
      await cameraController!.dispose();
      cameraController = null;
    }
  }
  
  Future<void> _setupCameraController() async {
    priv_cameras = await availableCameras();
    if (priv_cameras.isNotEmpty) {
      setState(() {
        cameras = priv_cameras;
        cameraController = CameraController(
          priv_cameras.first, 
          ResolutionPreset.low,
          enableAudio: false,
        );
      });
      cameraController?.initialize().then((_) {
        setState(() {});
      });
    }
  }
  
  Widget _buildUI() {
    if (cameraController == null || cameraController?.value.isInitialized == false) {
      return const Center(child: CircularProgressIndicator());
    } 
    /*
    return SafeArea(
      child: SizedBox.expand(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          //crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              height:100,
              width:100,
              child:CameraPreview(cameraController!),
            )
          ],
        )
      )
    );
    */
    return AspectRatio(
      aspectRatio: cameraController!.value.aspectRatio,
      child: CameraPreview(cameraController!),
    );
  }

  /// addCamera() is called by addNewCameraTab()
  /// when the user finishes camera setup. 
  void addCamera(String cameraName, String cameraDetail) {
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
      switchInstance();
    });
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
        Text('Camera Setup'),

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
        Text(errorMsg, style:TextStyle(color:Colors.red)),
        
        //something, list of active cams
        _buildUI(),
        

        //Button A
        Padding(
          padding:EdgeInsets.all(25), 
          child: FloatingActionButton(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            onPressed: () {addCamera(myControllerA.text, myControllerB.text);},
            child: Text('Finish Camera Setup'),
          )
        ),
        
        //Button B
        Padding(
          padding:EdgeInsets.all(25), 
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
  
  @override
  Widget build(BuildContext context) {

    if (true) {
      testA = SizedBox(
        height: 250,
        child: Center(child: CircularProgressIndicator()),
      );
      print('waiting');
    }
    
    if (userAddingCamera) {
      return addNewCameraTab();
    } else {
      return createListView();
    }
    
  }
}
