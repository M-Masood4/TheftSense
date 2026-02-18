export 'cameras.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'main.dart';
import 'package:idb_shim/idb_browser.dart';
import 'package:idb_shim/idb.dart';

// global variables
List<String> cameraNames = [];
List<String> cameraDetails = [];
List<XFile> thumbnails = [];

class CameraPage extends StatefulWidget {
  const CameraPage({Key? key}) : super(key: key);

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _disposeCamera();
    super.dispose();
  }

  CameraController? cameraController;
  int cameraSelectorIndex = 0;
  //start: debug vars
  int attempt = 6;
  bool app_fresh_start = true;
  //end: debug var

  //List<String> cameraNames = [];
  //List<String> cameraDetails = [];
  //List<XFile> thumbnails = [];
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
    Row row;

    if (cameraNames.isEmpty) {row = Row();}
    else { row = Row(
            children: [
              Text('${cameraNames.length} cameras active', style: const TextStyle(fontSize: 14, color: Colors.green)),
              SizedBox(width:10),
              Icon(Icons.circle, color: Colors.grey, size: 5),
              SizedBox(width:10),
              Text('0 problems', style: const TextStyle(fontSize: 14, color: Colors.grey))
            ]
          );
    }

    return ListView(
      scrollDirection: Axis.vertical,
      children: [ 

        Padding(
          padding: EdgeInsetsGeometry.fromLTRB(15, 5, 5, 1),
          child: row
        ),

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

  /// called by createListView(), creates a 'tab' for
  /// each camera that is currently registered.
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
            border: Border.all(color: Colors.green, width:2),
            borderRadius: BorderRadius.circular(12),
            color: const Color.fromARGB(255, 196, 191, 191),
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
              Icon(Icons.menu_book_sharp),
              SizedBox(width:5),
              Text(cameraName),
              SizedBox(width: 50),
              Text(cameraDetails)
            ]
          )
        )
      )
    );
  }

  /// fetch all camera information before creating list
  Future<void> getDbData() async {
    final factory = getIdbFactory();
    print('called getDbData');
    final db = await factory!.open('setup_cameras', version: attempt);

    final txn = db.transaction('setup_cameras', idbModeReadOnly);
    final store = txn.objectStore('setup_cameras');

    final items = await store.getAll();

    //await txn.completed;

    //setState(() {
    cameraNames = [];
    cameraDetails = [];
    thumbnails = [];

    for (int i=0; i<items.length; i++) {
      final map = items[i] as Map;
      cameraNames.add(map['camName']);
      cameraDetails.add(map['camDetails']);
      thumbnails.add(XFile.fromData(map['thumbnail']));
    }
    //});
    
    print('names $cameraNames');
    print('dets $cameraDetails');
    print('thumbs $thumbnails');

    await txn.completed;
  }

  /// switch sub-pages between 'cameras' and the
  /// sub-page to setup a camera.
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

  /// switch sub-pages between 'cameras' and the
  /// sub-page to view active cameras
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

  /// called by either switchInstance() function, 
  /// handles disposal of cameraController after 
  /// use to prevent errors.
  Future<void> _disposeCamera() async {
    if (cameraController != null) {
      await cameraController!.dispose();
      cameraController = null;
    }
  }
  
  /// sets up a cameraController so the connected
  /// camera can be viewed through the app
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

  /// changes the cameraSelectorIndex to switch the
  /// camera being currently viewed, used in the
  /// sub-page to setup cameras.
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
            Container(
              decoration: BoxDecoration(
                border:(Border.all(color:Colors.grey, width: 10))
                
              ),
              width: MediaQuery.of(context).size.width*0.83,
              height: MediaQuery.of(context).size.height*0.5,
              child:
                Expanded(
                  child:
                    AspectRatio(
                      aspectRatio: cameraController!.value.aspectRatio,
                      child: CameraPreview(cameraController!),
                    )
                ),
              )
            
          ]
        )
    );
  }

  /// addCamera() is called by addNewCameraTab()
  /// when the user finishes camera setup. 
  Future<void> addCamera(String cameraName, String cameraDetail) async {
    storePrevCamDetails = cameraDetail;
    storePrevCamName = cameraName;
    
    bool exit = false;
    setState(() {
      if (cameraName == '' || cameraDetail == '') {
        errorMsg = "Camera Details Required";
        exit = true;
      } else if (cameraNames.contains(cameraName)) {
        errorMsg = "Camera Name Already Exists";
        exit = true;
      }
    });

    if (!exit) {

      storePrevCamDetails = '';
      storePrevCamName = '';
      errorMsg = '';

      try {
        XFile new_thumbnail = await addToThumbnails();

        await _db(cameraName, cameraDetail, new_thumbnail);
      } catch (e) { print(e); } 

      switchInstance();
    }
  }

  /*
  Future<void> pickAndReadFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['txt'],
      allowMultiple: false,
    );

    if (result == null) {
      return;
    }

    PlatformFile file = result.files.first;

    print('${file.name}');
    print('${file.size} bytes');
    print('${file.extension}');
  }

  Future<void> _saveFile() async {
    try {
      const String content = 'Hello';
      Uint8List bytes = Uint8List.fromList(content.codeUnits);

      await FileSaver.instance.saveFile(
        name: 'test',
        bytes: bytes,
        ext: 'txt',
        mimeType: MimeType.text,
      );
    } catch (e) {
      print(e);
    }
  }
  */

  /// create a database to store vital information
  /// that needs to persist across app instances.
  /// NB: data DOES NOT persist when debugging, if
  /// you want to test this properly:
  /// 
  /// flutter build web
  /// cd build/web
  /// python3 -m http.server 8080
  Future<void> _db(String db_camName, String db_camDetails, XFile db_thumbnail) async {
    Uint8List bytes = await db_thumbnail.readAsBytes();

    if (app_fresh_start) { 
      cameraNames = [];
      cameraDetails = [];
      thumbnails = [];
      await getIdbFactory()!.deleteDatabase('setup_cameras');
      app_fresh_start = false;
    }
    
    final factory = getIdbFactory(); // for flutter web apps

    final db = await factory!.open(
      'setup_cameras',
      version: attempt,
      onUpgradeNeeded: (VersionChangeEvent e) {
        final db = e.database;

        if (!db.objectStoreNames.contains('setup_cameras')) {
          final store = db.createObjectStore(
            'setup_cameras',
            keyPath: 'id',
            autoIncrement: true,
          );

          store.createIndex('camName', 'camName', unique: true);
          store.createIndex('camDetails', 'camDetails', unique: false);
          store.createIndex('thumbnail', 'thumbnail', unique: false);
        }
      },
    );
    
    final txn = db.transaction('setup_cameras', idbModeReadWrite);
    final store = txn.objectStore('setup_cameras');

    await store.add({
      'camName': db_camName,
      'camDetails': db_camDetails,
      'thumbnail': bytes,  
    });

    await txn.completed;
    return;
  }

  Future<XFile> addToThumbnails() async {
    XFile file = await cameraController!.takePicture();
    Future.delayed(Duration(milliseconds: 500));
    setState(() {thumbnails.add(file);});
    //print(thumbnails);
    return file;
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

        Padding(
          padding: EdgeInsetsGeometry.fromLTRB(50, 5, 5, 5),
          child:
            Row(
              children: [
                Icon(Icons.videocam, size: 16, color: Colors.grey[600],),
                SizedBox(width:10),
                Center(child:Text(cameraNames[cameraSelectorIndex].toString())),
              ]
            ),
        ),

        Padding(
          padding: EdgeInsetsGeometry.fromLTRB(50, 5, 5, 5),
          child:
            Row(
              children: [
                Icon(Icons.menu_book, size: 16, color: Colors.grey[600],),
                SizedBox(width:10),
                Center(child:Text(cameraDetails[cameraSelectorIndex].toString())),
              ]
            ),
        ),

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
      return FutureBuilder(
        future: getDbData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          return createListView();
        }
      );
    }
  }
}
