import 'dart:io';

import 'package:flutter/material.dart';
class ShowImage extends StatefulWidget {
  final dynamic image;
  const ShowImage({Key? key, required this.image}) : super(key: key);

  @override
  State<ShowImage> createState() => _ShowImageState();
}

class _ShowImageState extends State<ShowImage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Image.file(widget.image,),
    );
  }
}
