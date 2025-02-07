import 'package:flutter/foundation.dart';
import 'package:fluwx/fluwx.dart';

class FluwxProvider with ChangeNotifier {
  Fluwx _fluwx;
  FluwxProvider(this._fluwx);
  Fluwx get wx => _fluwx;
}
