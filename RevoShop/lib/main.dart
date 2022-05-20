import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:country_code_picker/country_localizations.dart';
import 'package:dart_ipify/dart_ipify.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:nyoba/app_localizations.dart';
import 'package:nyoba/deeplink/deeplink_config.dart';
import 'package:nyoba/pages/home/home_screen.dart';
import 'package:nyoba/pages/notification/notification_screen.dart';
import 'package:nyoba/provider/app_provider.dart';
import 'package:nyoba/provider/blog_provider.dart';
import 'package:nyoba/provider/coupon_provider.dart';
import 'package:nyoba/provider/flash_sale_provider.dart';
import 'package:nyoba/provider/general_settings_provider.dart';
import 'package:nyoba/provider/home_provider.dart';
import 'package:nyoba/provider/login_provider.dart';
import 'package:nyoba/provider/notification_provider.dart';
import 'package:nyoba/provider/order_provider.dart';
import 'package:nyoba/provider/product_provider.dart';
import 'package:nyoba/provider/register_provider.dart';
import 'package:nyoba/provider/review_provider.dart';
import 'package:nyoba/provider/search_provider.dart';
import 'package:nyoba/provider/user_provider.dart';
import 'package:nyoba/provider/wallet_provider.dart';
import 'package:nyoba/provider/wishlist_provider.dart';
import 'package:nyoba/services/session.dart';
import 'package:nyoba/utils/global_variable.dart';
import 'package:provider/provider.dart';

import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:nyoba/provider/banner_provider.dart';
import 'package:nyoba/provider/category_provider.dart';
import 'package:uni_links/uni_links.dart';

Future<void> _messageHandler(RemoteMessage message) async {
  print("Handling a background message: ${message.messageId}");
  await Firebase.initializeApp();
  final NotificationAppLaunchDetails? notificationAppLaunchDetails = !kIsWeb &&
          Platform.isLinux
      ? null
      : await flutterLocalNotificationsPlugin.getNotificationAppLaunchDetails();
  String initialRoute = "Initial Route";
  if (notificationAppLaunchDetails?.didNotificationLaunchApp ?? false) {
    selectedNotificationPayload = notificationAppLaunchDetails!.payload;
    initialRoute = "Initial Route : $selectedNotificationPayload";
    print(initialRoute);
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await Session.init();

  final ipv4 = await Ipify.ipv4();
  Session.data.setString('ip', ipv4);

  AppNotifier appLanguage = AppNotifier();
  await appLanguage.fetchLocale();

  final NotificationAppLaunchDetails? notificationAppLaunchDetails = !kIsWeb &&
          Platform.isLinux
      ? null
      : await flutterLocalNotificationsPlugin.getNotificationAppLaunchDetails();
  String initialRoute = "Initial Route";
  if (notificationAppLaunchDetails?.didNotificationLaunchApp ?? false) {
    selectedNotificationPayload = notificationAppLaunchDetails!.payload;
    initialRoute = "Initial Route : $selectedNotificationPayload";
    print(initialRoute);
  }
  FirebaseMessaging.onBackgroundMessage(_messageHandler);
  runApp(Phoenix(
      child: MultiProvider(
    providers: [
      ChangeNotifierProvider<BannerProvider>(
        create: (context) => BannerProvider(),
      ),
      ChangeNotifierProvider<CategoryProvider>(
        create: (context) => CategoryProvider(),
      ),
      ChangeNotifierProvider<FlashSaleProvider>(
        create: (context) => FlashSaleProvider(),
      ),
      ChangeNotifierProvider<BlogProvider>(
        create: (context) => BlogProvider(),
      ),
      ChangeNotifierProvider<LoginProvider>(
        create: (context) => LoginProvider(),
      ),
      ChangeNotifierProvider<UserProvider>(
        create: (context) => UserProvider(),
      ),
      ChangeNotifierProvider<ProductProvider>(
        create: (context) => ProductProvider(),
      ),
      ChangeNotifierProvider<GeneralSettingsProvider>(
        create: (context) => GeneralSettingsProvider(),
      ),
      ChangeNotifierProvider<RegisterProvider>(
        create: (context) => RegisterProvider(),
      ),
      ChangeNotifierProvider<WishlistProvider>(
        create: (context) => WishlistProvider(),
      ),
      ChangeNotifierProvider<SearchProvider>(
        create: (context) => SearchProvider(),
      ),
      ChangeNotifierProvider<OrderProvider>(
        create: (context) => OrderProvider(),
      ),
      ChangeNotifierProvider<CouponProvider>(
        create: (context) => CouponProvider(),
      ),
      ChangeNotifierProvider<ReviewProvider>(
        create: (context) => ReviewProvider(),
      ),
      ChangeNotifierProvider<NotificationProvider>(
        create: (context) => NotificationProvider(),
      ),
      ChangeNotifierProvider<AppNotifier>(
        create: (context) => AppNotifier(),
      ),
      ChangeNotifierProvider<HomeProvider>(
        create: (context) => HomeProvider(),
      ),
      ChangeNotifierProvider<WalletProvider>(
        create: (context) => WalletProvider(),
      ),
    ],
    child: MyApp(
      appLanguage: appLanguage,
      notificationAppLaunchDetails: notificationAppLaunchDetails,
    ),
  )));
}

class MyApp extends StatefulWidget {
  // This widget is the root of your application.
  final AppNotifier? appLanguage;

  MyApp({Key? key, this.appLanguage, this.notificationAppLaunchDetails})
      : super(key: key);
  final NotificationAppLaunchDetails? notificationAppLaunchDetails;

  bool get didNotificationLaunchApp =>
      notificationAppLaunchDetails?.didNotificationLaunchApp ?? false;
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  StreamSubscription? _sub;

  @override
  void initState() {
    super.initState();
    _requestPermissions();
    _configureDidReceiveLocalNotificationSubject();
    _configureSelectNotificationSubject();
    _handleIncomingLinks();
  }

  void _requestPermissions() {
    flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
    flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            MacOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
  }

  void _configureDidReceiveLocalNotificationSubject() {
    didReceiveLocalNotificationSubject.stream
        .listen((ReceivedNotification receivedNotification) async {
      await showDialog(
        context: context,
        builder: (BuildContext context) => CupertinoAlertDialog(
          title: receivedNotification.title != null
              ? Text(receivedNotification.title!)
              : null,
          content: receivedNotification.body != null
              ? Text(receivedNotification.body!)
              : null,
          actions: <Widget>[
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () async {
                Navigator.of(context, rootNavigator: true).pop();
                /*await Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (BuildContext context) =>
                        SecondPage(receivedNotification.payload),
                  ),
                );*/
              },
              child: const Text('Ok'),
            )
          ],
        ),
      );
    });
  }

  void _configureSelectNotificationSubject() {
    selectNotificationSubject.stream.listen((String? payload) async {
      debugPrint("Payload : $payload");
      var _payload = json.decode(payload!);
      if (_payload['type'] == 'order') {
        await Navigator.of(GlobalVariable.navState.currentContext!).push(
            MaterialPageRoute(builder: (context) => NotificationScreen()));
      } else {
        print("Else");
        Uri uri = Uri.parse(_payload['click_action']);
        DeeplinkConfig().pathUrl(uri, context, false);
      }
    });
    FirebaseMessaging.onMessageOpenedApp.listen((message) async {
      print('Reload onMessageOpenedApp!');
      debugPrint('Message Open Click ' + message.data.toString());

      if (message.data['type'] == 'order') {
        Navigator.of(GlobalVariable.navState.currentContext!).push(
            MaterialPageRoute(builder: (context) => NotificationScreen()));
      } else {
        print("Else");
        Uri uri = Uri.parse(message.data['click_action']);
        DeeplinkConfig().pathUrl(uri, context, false);
      }
    });
  }

  void _handleIncomingLinks() {
    if (!kIsWeb) {
      _sub = uriLinkStream.listen((Uri? uri) {
        if (!mounted) return;
        print('Uri: $uri');
        DeeplinkConfig().pathUrl(uri!, context, false);
      }, onError: (Object err) {
        if (!mounted) return;
        print('Error: $err');
      });
    }
  }

  @override
  void dispose() {
    didReceiveLocalNotificationSubject.close();
    selectNotificationSubject.close();
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(360, 690),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (child) {
        return ChangeNotifierProvider<AppNotifier?>(
            create: (_) => widget.appLanguage, child: child);
      },
      child: Consumer<AppNotifier>(
        builder: (context, value, _) => MaterialApp(
          navigatorKey: GlobalVariable.navState,
          debugShowCheckedModeBanner: false,
          locale: value.appLocal,
          title: 'RevoShop',
          routes: <String, WidgetBuilder>{
            'HomeScreen': (BuildContext context) => HomeScreen(),
          },
          theme: value.getTheme(),
          supportedLocales: [
            Locale('en', 'US'),
            Locale('id', ''),
            Locale('es', ''),
            Locale('fr', ''),
            Locale('zh', ''),
            Locale('ja', ''),
            Locale('ko', ''),
            Locale('ar', ''),
            Locale('te', ''),
            Locale("af"),
            Locale("am"),
            Locale("ar"),
            Locale("az"),
            Locale("be"),
            Locale("bg"),
            Locale("bn"),
            Locale("bs"),
            Locale("ca"),
            Locale("cs"),
            Locale("da"),
            Locale("de"),
            Locale("el"),
            Locale("en"),
            Locale("es"),
            Locale("et"),
            Locale("fa"),
            Locale("fi"),
            Locale("fr"),
            Locale("gl"),
            Locale("ha"),
            Locale("he"),
            Locale("hi"),
            Locale("hr"),
            Locale("hu"),
            Locale("hy"),
            // Locale("id"),
            Locale("is"),
            Locale("it"),
            Locale("ja"),
            Locale("ka"),
            Locale("kk"),
            Locale("km"),
            Locale("ko"),
            Locale("ku"),
            Locale("ky"),
            Locale("lt"),
            Locale("lv"),
            Locale("mk"),
            Locale("ml"),
            Locale("mn"),
            Locale("ms"),
            Locale("nb"),
            Locale("nl"),
            Locale("nn"),
            Locale("no"),
            Locale("pl"),
            Locale("ps"),
            Locale("pt"),
            Locale("ro"),
            Locale("ru"),
            Locale("sd"),
            Locale("sk"),
            Locale("sl"),
            Locale("so"),
            Locale("sq"),
            Locale("sr"),
            Locale("sv"),
            Locale("ta"),
            Locale("te"),
            Locale("tg"),
            Locale("th"),
            Locale("tk"),
            Locale("tr"),
            Locale("tt"),
            Locale("uk"),
            Locale("ug"),
            Locale("ur"),
            Locale("uz"),
            Locale("vi"),
            Locale("zh")
          ],
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            CountryLocalizations.delegate,
          ],
          home: Builder(
            builder: (context) {
              return FutureBuilder(
                  future: DeeplinkConfig().initUniLinks(context),
                  builder: (_, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Container();
                    }
                    return snapshot.data as Widget;
                  });
            },
          ),
        ),
      ),
    );
  }
}
