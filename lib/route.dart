import 'package:fluro/fluro.dart';
import 'package:workcake/components/apps/app_screen_macOS.dart';
import 'login_macOS.dart';
import 'main_screen_macOS.dart';

class AppRoutes {
  static FluroRouter router = FluroRouter();

  static Handler _loginMacOS = Handler(
      handlerFunc: (context, Map<String, dynamic> params) => LoginMacOS());

  static Handler _mainScreenMacOS = Handler(
      handlerFunc: (context, Map<String, dynamic> params) => MainScreenMacOS());

  static Handler _listApps = Handler(
      handlerFunc: (context, Map<String, dynamic> params) => AppsScreenMacOS());

  static void setupRouter() {
    router.define('/list-apps', handler: _listApps, transitionType: TransitionType.fadeIn);
    router.define('/login-macos', handler: _loginMacOS);
    router.define('/main_screen_macOS', handler: _mainScreenMacOS, transitionType: TransitionType.fadeIn);
  }
}
