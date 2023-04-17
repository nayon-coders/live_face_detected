import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:ui';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:real_time_face_detection/showImage.dart';

late List<CameraDescription> _cameras;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  _cameras = await availableCameras();

  // Ensure that plugin services are initialized so that `availableCameras()`
  // can be called before `runApp()`



  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);



  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});



  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late CameraController controller;
  late Size size;
  CameraImage? img;
  dynamic _scannedFaces;
  dynamic faceDetector;
  bool isBusy = false;
  late CameraDescription description = _cameras[0];
  late CameraLensDirection camDirection = CameraLensDirection.front;



  late Future<void> _initializeControllerFuture;

  @override
  void initState() {
    super.initState();
    initializeCamera();
    camDirection = CameraLensDirection.front;

   // _initializeControllerFuture = controller.initialize();

  }



  @override
  void dispose() {
    controller.dispose();
    faceDetector.close();
    // Dispose of the controller when the widget is disposed.
    controller.dispose();
    super.dispose();
  }

  toggleCameraDirection() async {
    if (camDirection == CameraLensDirection.back) {
      description = _cameras[1];
      camDirection = CameraLensDirection.front;
    } else {
      description = _cameras[0];
      camDirection = CameraLensDirection.back;
    }
    await controller.stopImageStream();
    setState(() {
      controller;
    });
    initializeCamera();
  }

  bool isFaceDetected = false;

  initializeCamera() async {
    final options =
        FaceDetectorOptions(enableContours: true, enableLandmarks: true);
    faceDetector = FaceDetector(options: options);
    controller = CameraController(description, ResolutionPreset.high);
    await controller.initialize().then((_) {
      if (!mounted) {
        return;
      }
      controller.startImageStream((image) => {
            if (!isBusy) {isBusy = true, img = image, doFaceDetectionOnFrame()}
          });
    }).catchError((Object e) {
      if (e is CameraException) {
        switch (e.code) {
          case 'CameraAccessDenied':
            print('Camera Access Denied');
            break;
          default:
            print('Other Access Denied');
            break;
        }
      }
    });
  }

  doFaceDetectionOnFrame() async {
    InputImage frameImg = getInputImage();
    List<Face> faces = await faceDetector.processImage(frameImg);
    print('${faces.length} 💥💥');

    if(faces.length == 1){
      setState(() {
        isFaceDetected = true;
      });
    }else{
      setState(() {
        isFaceDetected = false;
      });
    }
    setState(() {
      isBusy = false;
      _scannedFaces = faces;
    });
  }

  InputImage getInputImage() {
    final WriteBuffer allBytes = WriteBuffer();
    for (final Plane plane in img!.planes) {
      allBytes.putUint8List(plane.bytes);
    }
    final bytes = allBytes.done().buffer.asUint8List();
    final Size imageSize = Size(img!.width.toDouble(), img!.height.toDouble());
    final camera = description;
    final imageRotation =
        InputImageRotationValue.fromRawValue(camera.sensorOrientation);
    // if (imageRotation == null) return;

    final inputImageFormat =
        InputImageFormatValue.fromRawValue(img!.format.raw);
    // if (inputImageFormat == null) return null;

    final planeData = img!.planes.map(
      (Plane plane) {
        return InputImagePlaneMetadata(
          bytesPerRow: plane.bytesPerRow,
          height: plane.height,
          width: plane.width,
        );
      },
    ).toList();

    final inputImageData = InputImageData(
      size: imageSize,
      imageRotation: imageRotation!,
      inputImageFormat: inputImageFormat!,
      planeData: planeData,
    );

    final inputImage =
        InputImage.fromBytes(bytes: bytes, inputImageData: inputImageData);

    return inputImage;
  }

  Widget buildResult() {

    if (_scannedFaces == null || !controller.value.isInitialized) {
      print("face detected");
      setState(() {
        isFaceDetected = true;
      });
      return Text('');
    }
    //Passing the height as width and width as height. Reasons???????????
    final Size imgSize = Size(
      controller.value.previewSize!.height,
      controller.value.previewSize!.width,
    );
    CustomPainter paint =
        FaceDetectorPainter(imgSize, _scannedFaces, camDirection);
    return CustomPaint(
      painter: paint,
    );
  }


  @override
  Widget build(BuildContext context) {
    List<Widget> stackChildren = [];
    size = MediaQuery.of(context).size;


    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Face Detector',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        margin: const EdgeInsets.only(top: 0),
        color: Colors.transparent,
        child: Stack(
          children: [
            Positioned(
              height: size.height - 250.0,
              width: size.width,
              top: 0.0,
              left: 0.0,
              child: Container(
                child: (controller.value.isInitialized)
                    ? AspectRatio(
                  aspectRatio: controller.value.aspectRatio,
                  child: CameraPreview(controller),
                )
                    : Container(),
              ),
            ),

            //build result
            Positioned(
              top: 0,
              width: size.width,
              height: size.height - 250,
              left: 0,
              child: buildResult(),
            ),

            //rotate
            Positioned(
              top: size.height -250,
              right: 0,
              // width: size.width,
              // height: 250,
              child: Container(
                margin: const EdgeInsets.only(bottom: 80),
                child: IconButton(
                  icon:  Icon(
                   Icons.cached
                  ),
                  iconSize: 50,
                  color: Colors.black,
                  onPressed: () {
                    toggleCameraDirection();
                  },
                ),
              ),
            ),

            isFaceDetected ? Positioned(
              top: size.height - 250,
              right: 0,
              width: size.width,
              //height: 250,
              child:  Container(
                margin: const EdgeInsets.only(bottom: 80),
                child: IconButton(
                  icon: const Icon(
                    Icons.camera,
                  ),
                  iconSize: 80,
                  color: Colors.black,
                  onPressed: () async{
                    // Take the Picture in a try / catch block. If anything goes wrong,
                    // catch the error.
                    if(isFaceDetected) {
                      _initializeControllerFuture = controller.initialize();
                      try {
                        // Ensure that the camera is initialized.
                        await _initializeControllerFuture;

                        // Attempt to take a picture and then get the location
                        // where the image file is saved.
                        final image = await controller.takePicture();

                        Navigator.push(context, MaterialPageRoute(builder: (
                            context) => ShowImage(image: File(image.path))));
                        print("camera image ===== ${image.path}");
                      } catch (e) {
                        // If an error occurs, log the error to the console.
                        print("this is error $e");
                      }
                    }else{
                      print("face not detected from camera");
                    }

                  },
                ),
              ),
            ) : Positioned(
                top: size.height -200,
                right: 0,
                width: size.width,
                child: Center(child: Text("Face not detected",
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.red,
                    fontWeight: FontWeight.bold
                  ),
                ))),
          ],
        ),
      ),
    );
  }
}

class FaceDetectorPainter extends CustomPainter {
  FaceDetectorPainter(this.absoluteImgSize, this.faces, this.camDire);
  List<Face> faces;
  final Size absoluteImgSize;
  CameraLensDirection camDire;

  @override
  void paint(Canvas canvas, Size size) {
    final double scaleX = size.width / absoluteImgSize.width;
    final double scaleY = size.height / absoluteImgSize.height;

    Paint p = Paint();
    p.style = PaintingStyle.stroke;
    p.color = Colors.green;
    p.strokeWidth = 6.0;

    for (Face f in faces) {
      canvas.drawRect(
          Rect.fromLTRB(
            (camDire == CameraLensDirection.front)
                ? (absoluteImgSize.width - f.boundingBox.right) * scaleX
                : f.boundingBox.left * scaleX,
            f.boundingBox.top * scaleY,
            (camDire == CameraLensDirection.front)
                ? (absoluteImgSize.width - f.boundingBox.left) * scaleX
                : f.boundingBox.right * scaleX,
            f.boundingBox.bottom * scaleY,
          ),
          p);
    }

    Paint p2 = Paint();
    p2.style = PaintingStyle.stroke;
    p2.color = Colors.blue;
    p2.strokeWidth = 3.0;
    for (Face f in faces) {
      Map<FaceContourType, FaceContour?> con = f.contours;
      List<Offset> offsetPoints = <Offset>[];
      con.forEach((key, value) {
        if (value != null) {
          List<Point<int>> points = value.points;
          for (Point p in points) {
            Offset offset = Offset(
              (camDire == CameraLensDirection.front)
                  ? (absoluteImgSize.width - p.x.toDouble()) * scaleX
                  : p.x.toDouble() * scaleX,
              p.y.toDouble() * scaleY,
            );
            offsetPoints.add(offset);
          }
          canvas.drawPoints(PointMode.points, offsetPoints, p2);
        }
      });
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
