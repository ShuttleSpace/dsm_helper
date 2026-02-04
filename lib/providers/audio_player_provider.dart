import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';

class AudioPlayerProvider with ChangeNotifier {
  late Player _player;
  String _url = '';
  String _name = '';
  Player get player => _player;
  String get url => _url;
  String get name => _name;
  AudioPlayerProvider() {
    _player = Player();
  }
  void setPlayer(Player player) async {
    _player = player;
    notifyListeners();
  }

  void setUrl(String url, String name) async {
    _url = url;
    _name = name;
  }
}
