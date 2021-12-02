import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_segmentation/utils.dart';
import 'package:tflite/tflite.dart';
import 'package:image/image.dart' as Img;

class CameraViewPage extends StatefulWidget {
  // private camera object: get assigned to global one
  final List<CameraDescription> cameras;

  CameraViewPage(this.cameras);

  @override
  _CameraViewPageState createState() => new _CameraViewPageState();
}

class _CameraViewPageState extends State<CameraViewPage> {
  final List<int> _colors = [
    Colors.transparent.value,
    Colors.transparent.value,
    Colors.transparent.value,
    Colors.transparent.value,
    Colors.transparent.value,
    Colors.transparent.value,
    Colors.transparent.value,
    // Colors.transparent.value,
    Colors.white.value,
    Colors.transparent.value,
    Colors.transparent.value,
    Colors.transparent.value,
    Colors.transparent.value,
    Colors.transparent.value,
    Colors.transparent.value,
    Colors.transparent.value,
    Colors.transparent.value,
    Colors.transparent.value,
    Colors.transparent.value,
    Colors.transparent.value,
    Colors.transparent.value,
    Colors.transparent.value,
  ];

  late CameraController controller;
  Uint8List? recognitions;
  int whichCamera = 0;

  /// gets called when widget is initiated
  @override
  void initState() {
    super.initState();
    // loadModel();
    _initiateCamera(this.whichCamera);
  }

  /// gets called when the widget comes to an end
  @override
  void dispose() {
    this.controller.dispose();
    super.dispose();
  }

  /// load tflite model for deeplab v3
  _loadModel() async {
    String? res = await Tflite.loadModel(
      model: "assets/deeplabv3_257_mv_gpu.tflite",
      labels: "assets/deeplabv3_257_mv_gpu.txt",
    );
    print(res);
  }

  /// initiate camera controller
  void _initiateCamera(int whichCamera) {
    this.controller =
    new CameraController(widget.cameras[whichCamera], ResolutionPreset.low);
    if (widget.cameras == null || widget.cameras.length < 1) {
      print('No camera is found');
    } else {
      this.controller.initialize().then((_) {
        if (!mounted) {
          return;
        }
        setState(() {});

        this.controller.startImageStream((CameraImage img) {
          Tflite.runSegmentationOnFrame(
            bytesList: img.planes.map((plane) {
              return plane.bytes;
            }).toList(),
            // required
            imageHeight: img.height,
            // defaults to 1280
            imageWidth: img.width,
            // defaults to 720
            imageMean: 127.5,
            // defaults to 0.0
            imageStd: 127.5,
            // defaults to 255.0
            rotation: 90,
            // defaults to 90, Android only
            outputType: "png",
            // defaults to "png"
            asynch: true,
            // defaults to true
            labelColors: _colors,
          ).then((rec) async {
            if (rec != null /* && recognitions == null*/) {
              this.recognitions = await Utils.changeBackgroundOfImage(
                bytes: rec,
                removeColorRGB: [255, 255, 255],
                addColorRGB: [0, 0, 0, 0],
              );

              setState(() {
                // print('-- RESULT: $rec');
                // this.recognitions = rec;
              });
            }
          });
        });
      });
    }
  }

  /// gets called everytime the widget need to re-render or build
  @override
  Widget build(BuildContext context) {
    Size? tmp = MediaQuery.of(context).size;
    var screenW;
    var screenH;

    if (tmp == null) {
      screenW = 0;
    } else {
      screenW = tmp.width;
      screenH = tmp.height;
      tmp = this.controller.value.previewSize;
    }

    setState(() {});

    return Scaffold(
      appBar: AppBar(
          centerTitle: true, title: const Text('Real time Segmentation')),
      floatingActionButton: Stack(
        children: <Widget>[
          Padding(
            padding: EdgeInsets.all(10),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: FloatingActionButton(
                heroTag: '1',
                child: Icon(Icons.people),
                tooltip: 'Selfie camera',
                backgroundColor: Colors.redAccent,
                onPressed: () {
                  setState(() {
                    this.whichCamera = 2;
                  });
                  _initiateCamera(this.whichCamera);
                },
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(10),
            child: Align(
              alignment: Alignment.bottomRight,
              child: FloatingActionButton(
                heroTag: '2',
                child: Icon(Icons.camera),
                tooltip: 'Main camera',
                backgroundColor: Colors.redAccent,
                onPressed: () {
                  setState(() {
                    this.whichCamera = 0;
                  });
                  _initiateCamera(this.whichCamera);
                },
              ),
            ),
          )
        ],
      ),
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            child: _cameraShow(),
          ),
          Positioned(
            top: 0,
            left: 0,
            width: screenW,
            height: 550,
            child: _segmentationResults(),
          ),
        ],
      ),
    );
  }

  /// widget for rendering the realtime camera on screen
  Widget _cameraShow() {
    if (this.controller == null || !this.controller.value.isInitialized) {
      return Container(
        child: Text("Not inialized"),
      );
    }

    var tmp = MediaQuery.of(context).size;
    var screenW;
    var screenH;

    if (tmp == null) {
      screenW = 0;
    } else {
      screenW = tmp.width;
      screenH = tmp.height;
      tmp = this.controller.value.previewSize!;
    }

    return Container(
      width: screenW,
      height: 550,
      child: CameraPreview(this.controller),
      // constraints: BoxConstraints(
      //   maxHeight: 550,
      //   maxWidth: screenW,
      // ),
    );
  }

  Widget _renderSegmentPortion() {
    if (this.whichCamera == 2) {
      return RotatedBox(
        quarterTurns: 2,
        child: Image.memory(this.recognitions!, fit: BoxFit.fill),
      );
    } else {
      return Opacity(
        opacity: 1,
        child: Image.memory(
          this.recognitions!,
          fit: BoxFit.fill,
          // color: Colors.transparent,
          // colorBlendMode: BlendMode.srcATop,
          gaplessPlayback: true,
        ),
      );
    }
  }

  /// widget for segmentation renders
  Widget _segmentationResults() {
    return this.recognitions == null
        ? Center(
      child: Text('Not initialized'),
    )
        : _renderSegmentPortion();
  }
}
