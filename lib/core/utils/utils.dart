import 'package:flutter/material.dart';

class Utils {
  double width(context) {
    return MediaQuery.of(context).size.width;
  }

  double height(context) {
    return MediaQuery.of(context).size.height;
  }

  Orientation orientation(context) {
    return MediaQuery.of(context).orientation;
  }
}
