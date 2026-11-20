import 'dart:math';

extension IntExt on int {
  DateTime get toDateTime => DateTime.fromMillisecondsSinceEpoch(this * 1000);

  /// 时间转时长
  Map<String, int> formatTime() {
    int seconds = this % 60;
    int minutes = this ~/ 60 % 60;
    int hours = this ~/ 60 ~/ 60;
    return {
      "hours": hours,
      "minutes": minutes,
      "seconds": seconds,
    };
  }

  String timeRemaining() {
    int hour = this / 60 ~/ 60;
    int minute = (this - hour * 60 * 60) ~/ 60;
    int second = this ~/ 60;
    return "${hour.toString().padLeft(2, "0")}:${minute.toString().padLeft(2, "0")}:${second.toString().padLeft(2, "0")}";
  }
}

extension NumExt on num {
  /// 格式化文件大小。DSM 返回的字节数可能是 int 或 double（dynamic）。
  String formatSize({int fixed = 2, int format = 1024, bool showByte = false}) {
    if (this == 0) {
      return "0${showByte ? 'Bytes' : ''}";
    } else if (this < format) {
      return "${toInt()}${showByte ? 'Bytes' : ''}";
    } else if (this < pow(format, 2)) {
      return "${(this / format).toStringAsFixed(fixed)}K";
    } else if (this < pow(format, 3)) {
      return "${(this / pow(format, 2)).toStringAsFixed(fixed)}M";
    } else if (this < pow(format, 4)) {
      return "${(this / pow(format, 3)).toStringAsFixed(fixed)}G";
    } else {
      return "${(this / pow(format, 4)).toStringAsFixed(fixed)}T";
    }
  }

  double chartInterval() {
    if (this < 1024) {
      return 102.4;
    } else if (this < 1024 * 2) {
      return 102.4 * 2;
    } else if (this < 1024 * 5) {
      return 1024.0;
    } else if (this < 1024 * 10) {
      return 1024.0 * 2;
    } else if (this < pow(1024, 2)) {
      return 1024.0 * 200;
    } else if (this < pow(1024, 2) * 5) {
      return 1.0 * pow(1024, 2);
    } else if (this < pow(1024, 2) * 10) {
      return 2.0 * pow(1024, 2);
    } else if (this < pow(1024, 2) * 20) {
      return 4.0 * pow(1024, 2);
    } else if (this < pow(1024, 2) * 40) {
      return 8.0 * pow(1024, 2);
    } else if (this < pow(1024, 2) * 50) {
      return 10.0 * pow(1024, 2);
    } else if (this < pow(1024, 2) * 100) {
      return 20.0 * pow(1024, 2);
    } else {
      return 50.0 * pow(1024, 2);
    }
  }
}
