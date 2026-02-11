import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:garden/extensions/datetime.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';

class Log {
  static final Logger _logger = Logger(
      printer: HybridPrinter(
        SimplePrinter(),
        // debug: PrettyPrinter(
        //     methodCount: 2,
        //     errorMethodCount: 8,
        //     lineLength: 120,
        //     colors: true,
        //     printEmojis: false,
        //     dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart),
      ),
      output: MultiOutput(
          [ConsoleOutput(), if (!kIsWeb || !kIsWasm) RotateLogOutput()]));

  static log(Object message, {Level level = Level.trace}) {
    _logger.log(level, message);
    debugPrint(message.toString());
  }

  static info(Object message) {
    _logger.i(message);
    debugPrint(message.toString());
  }

  static error(Object message) {
    _logger.e(message);
    debugPrint(message.toString());
  }

  static debug(Object message) {
    _logger.d(message);
    debugPrint(message.toString());
  }

  static warn(Object message) {
    _logger.w(message);
    debugPrint(message.toString());
  }

  Future<void> clear() async {
    final dir = await RotateLogOutput.createLogDir();
    await for (FileSystemEntity f in dir.list()) {
      final paths = f.path.split(separator);
      if (paths.isNotEmpty) {
        final logName = paths.last.replaceAll('.log', '');
        final logDate = DateTime.tryParse(logName);
        final today = DateTime.now();
        if (logDate != null) {
          final overDays = today.difference(logDate).inDays;
          Log.debug('overDays: $overDays');
          if (overDays > 7) {
            await f.delete();
          }
        }
      }
    }
  }
}

class RotateLogOutput extends LogOutput {
  final Encoding _encoding = utf8;
  IOSink? _sink;
  String? _currentDate;

  @override
  Future<void> init() async {
    await _logDir();
    return super.init();
  }

  @override
  void output(OutputEvent event) async {
    _logDir().whenComplete(() {
      if (_sink != null) {
        _sink!.writeAll(event.lines, Platform.isWindows ? '\r\n' : '\n');
      }
    });
  }

  @override
  Future<void> destroy() async {
    await _sink?.flush();
    await _sink?.close();
  }

  static Future<Directory> createLogDir() async {
    final Directory directory = await getApplicationDocumentsDirectory();
    final Directory dir = Directory('${directory.path}$separator/log');
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    return dir;
  }

  Future<void> _logDir() async {
    String today = _today();
    if (today != _currentDate) {
      final Directory dir = await createLogDir();
      final file = File('${dir.path}$separator$today.log');
      _sink = file.openWrite(mode: FileMode.append, encoding: _encoding);
      _currentDate = today;
    }
  }

  String _today() {
    return DateTime.now().format("yyyyMMdd");
  }
}
