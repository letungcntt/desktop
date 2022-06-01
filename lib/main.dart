import 'dart:io';

import 'package:context_menus/context_menus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:flutter_portal/flutter_portal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:workcake/common/themes.dart';
import 'package:workcake/components/call_center/room.dart';
import 'package:workcake/components/dialog_ui.dart';
import 'package:workcake/emoji/emoji.dart';
import 'package:workcake/hive/direct/direct.model.dart';
import 'package:workcake/isar/message_conversation/service.dart';
import 'package:workcake/media_conversation/isolate_media.dart';
import 'package:workcake/objectbox.g.dart';
import 'package:workcake/route.dart';
import 'package:workcake/service_locator.dart';
import 'common/drop_zone.dart';
import 'data_channel_webrtc/device_socket.dart';
import 'generated/l10n.dart';
import 'package:provider/provider.dart';
import 'package:workcake/common/utils.dart';
import 'package:workcake/components/splash_screen.dart';
import 'package:hive/hive.dart';

import 'isar/message_conversation/service.dart';
import 'login_macOS.dart';
import 'main_screen_macOS.dart';
import 'media_conversation/service_box.dart';
import 'models/device_provider.dart';
import 'models/models.dart';
// import 'package:dart_vlc/dart_vlc.dart';

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = new MyHttpOverrides();
  // DartVLC.initialize();

  NetworkInterface.list(includeLoopback: false, type: InternetAddressType.any)
  .then((List<NetworkInterface> interfaces) {
    interfaces.forEach((interface) {
      interface.addresses.forEach((address) {
        Utils.checkDebugMode(address.address);
      });
    });
  });

  AppRoutes.setupRouter();
  setupServiceLocator();
  setupDialogUI();
  var newDir = await getApplicationSupportDirectory();
  var newPath = newDir.path + "/pancake_chat_data";
  Hive.init(newPath);
  Hive.registerAdapter(DirectModelAdapter());
  try {
    await Hive.openBox('direct');
    await Hive.openLazyBox("pairKey");
    await Hive.openLazyBox("messageConversation");
    await Hive.openBox("windows");
    await Hive.openBox("recentEmoji");
    await Hive.openBox("recentIssueCreated");
    await Hive.openBox('lastSelected');
    await Hive.openBox("queueMessages");
    await Hive.openBox("invitationHistory");
    DeviceSocket.instance.initPanchatDeviceSocket();
    await Utils.initPairKeyBox();
    await MessageConversationServices.getIsar();
    
    MessageConversationServices.restoreBackUp();
    Utils.getDeviceInfo();

    var newDir = await getApplicationSupportDirectory();
    var newPath = newDir.path + "/pancake_chat_data";
    IsolateMedia.storeObjectBox = Store(getObjectBoxModel(), directory: newPath);
    ServiceBox.box =  IsolateMedia.storeObjectBox;
    IsolateMedia.mainSendPort = await IsolateMedia.createIsolate();
  } catch (e) {
    print(")___$e");
    // await Hive.deleteFromDisk();
  }

  runApp(PancakeChat());
}

class PancakeChat extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => new Auth()),
        ChangeNotifierProvider(create: (_) => new Workspaces()),
        ChangeNotifierProvider(create: (_) => new Channels()),
        ChangeNotifierProvider(create: (_) => new Messages()),
        ChangeNotifierProvider(create: (_) => new DirectMessage()),
        ChangeNotifierProvider(create: (_) => new User()),
        ChangeNotifierProvider(create: (_) => new Work()),
        ChangeNotifierProvider(create: (_) => new Friend()),
        ChangeNotifierProvider(create: (_) => new Windows()),
        ChangeNotifierProvider(create: (_) => new P2PModel()),
        ChangeNotifierProvider(create: (_) => new RoomsModel()),
        ChangeNotifierProvider(create: (_) => new Boards()),
        ChangeNotifierProvider(create: (_) => new Threads()),
        ChangeNotifierProvider(create: (_) => new DeviceProvider())
      ],
      child: Consumer<Auth>(
        builder: (ctx, auth, _) => Portal(
          child: StreamBuilder(
            stream: StreamDropzone.instance.currentTheme,
            builder: (context, snapshot) {
              Utils.setGlobalContext(context);
              auth.onChangeCurrentTheme(snapshot.data, false);
              final locale = auth.locale;

              return Phoenix(
                child: Builder(
                  builder: (context) {
                    Utils.loginContext = context;
                    return MaterialApp(
                      debugShowCheckedModeBanner: false,
                      navigatorKey: StackedService.navigatorKey,
                      localizationsDelegates: [
                        S.delegate,
                        GlobalMaterialLocalizations.delegate,
                        GlobalWidgetsLocalizations.delegate,
                        GlobalCupertinoLocalizations.delegate,
                      ],
                      supportedLocales: S.delegate.supportedLocales,
                      locale: Locale(locale),
                      theme: auth.theme == ThemeType.DARK
                          ? Themes.darkTheme
                          : Themes.lightTheme,
                      home: ContextMenuOverlay(
                        cardBuilder: (_, children) => Container(
                          decoration: BoxDecoration(
                            color: auth.theme == ThemeType.DARK ? Color(0xff1E1E1E) : Colors.white,
                            border: auth.theme != ThemeType.DARK ? Border.all(
                              color: Color(0xffEAE8E8)
                            ) : null,
                            borderRadius: BorderRadius.all(Radius.circular(6))
                          ),
                          padding: EdgeInsets.all(6),
                          child: Column(children: children)
                        ),
                        buttonBuilder: (_, config, [__]) => Container(
                          padding: EdgeInsets.symmetric(vertical: 2),
                          child: HoverItem(
                            radius: 4.0,
                            isRound: true,
                            colorHover: auth.theme == ThemeType.DARK ? Color(0xff0050b3) : Color(0xff91d5ff),
                            child: InkWell(
                              onTap: config.onPressed,
                              child: Container(
                                width: double.infinity,
                                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: EdgeInsets.only(right: 8),
                                      child: config.icon,
                                    ),
                                    Text(
                                      config.label,
                                      style: TextStyle(
                                        color: auth.theme == ThemeType.DARK ? Color(0xffDBDBDB) : Color(0xff5E5E5E),
                                        fontSize: 12
                                      ),
                                    )
                                  ],
                                )
                              ),
                            ),
                          ),
                        ),
                        child: auth.isAuth
                          ? MainScreenMacOS() 
                          : FutureBuilder(
                              future: auth.tryAutoLogin(),
                              builder: (ctx, authResultSnapshot) =>
                                  authResultSnapshot.connectionState == ConnectionState.waiting
                                      ? SplashScreen()
                                      : LoginMacOS()),
                      ),
                      onGenerateRoute: AppRoutes.router.generator
                    );
                  }
                ),
              );
            }
          )
        )
      )
    );
  }
}