import 'package:flutter/foundation.dart';
import 'package:simple_logger/simple_logger.dart';

class Log {
  static SimpleLogger logger = SimpleLogger();
  static init() {
    logger.levelPrefixes = {};
    logger.mode = LoggerMode.log;
    logger.setLevel(kDebugMode ? Level.ALL : Level.OFF,
        includeCallerInfo: true);
  }

  static log(Object message) {
    logger.log(Level.ALL, message);
    debugPrint(message.toString());
  }

  static info(Object message) {
    logger.info(message);
    debugPrint(message.toString());
  }

  static error(Object message) {
    logger.log(Level.SEVERE, message);
    debugPrint(message.toString());
  }

  static debug(Object message) {
    logger.log(Level.FINE, message);
    debugPrint(message.toString());
  }

  static warn(Object message) {
    logger.log(Level.WARNING, message);
    debugPrint(message.toString());
  }
}
