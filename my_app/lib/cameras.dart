export 'cameras.dart';

import 'package:flutter/material.dart';

class CameraPage extends StatelessWidget {
  
    @override
    Widget build(BuildContext context) {
      return ListView(
      scrollDirection: Axis.vertical,
      
      children: [
        for (int i = 0; i < 3; i++) 
          Padding(
            padding:EdgeInsetsGeometry.all(10), 
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: const Color.fromARGB(255, 203, 196, 196),
              ),
              //color:Colors.grey,
              height: 75,
              child: Row(
                children: [
                  SizedBox(width:25),
                  Icon(Icons.camera_alt_outlined),
                  SizedBox(width:25),
                  Text('Camera $i'),
                  SizedBox(width: 50),
                  Text('Camera Details')
                ]
              )
            )
          )
          // add cameras button below cameras
          
      ]
    );
  }
}
