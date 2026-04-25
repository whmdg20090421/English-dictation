import 'package:flutter/foundation.dart';
import 'db/data_manager.dart';

class AppState extends ChangeNotifier {
  static final AppState instance = AppState._internal();
  AppState._internal();

  String currentAccountId = "default";
  String currentView = 'home';
  List<Map<String, dynamic>> selectedWords = [];
  String testMode = '';
  List<Map<String, dynamic>> testQueue = [];
  int currentQIndex = 0;
  List<Map<String, dynamic>> scoreLog = [];
  bool authDialogOpen = false;
  bool isSubmitting = false;
  bool resultSaved = false;

  Map<int, dynamic> userAnswers = <int, dynamic>{};
  double perQTime = 20.0;
  double totalTime = 0.0;
  double qTimeLeft = 20.0;
  double totLeft = 0.0;

  bool allowBackward = true;
  bool allowHint = false;
  String guestPassword = "";
  Set<String> adminExpandedPaths = {};
  Set<String> browserExpandedPaths = {};

  void init() {
    if (DataManager.instance.accounts.isNotEmpty) {
      currentAccountId = DataManager.instance.accounts.keys.first;
    } else {
      currentAccountId = "default";
    }
  }

  void changeView(String viewName) {
    currentView = viewName;
    notifyListeners();
  }

  void update() {
    notifyListeners();
  }
}
