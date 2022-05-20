import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:nyoba/pages/intro/intro_screen.dart';
import 'package:nyoba/pages/home/home_screen.dart';
import 'package:nyoba/provider/home_provider.dart';
import 'package:nyoba/services/session.dart';
import 'package:nyoba/utils/utility.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'package:path/path.dart' as p;

class SplashScreen extends StatefulWidget {
  final Future Function()? onLinkClicked;
  SplashScreen({Key? key, this.onLinkClicked}) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool loadHomeSuccess = true;

  String? _versionName;

  bool isVideo = false;
  late VideoPlayerController _controller;

  Future startSplashScreen() async {
    final home = Provider.of<HomeProvider>(context, listen: false);
    final ext = p.extension(home.splashscreen.image!);
    printLog(ext, name: 'Extension Splash');
    var duration = Duration(milliseconds: 2500);

    if (ext == '.mp4') {
      var videoDuration;
      setState(() {
        isVideo = true;
      });
      _controller = VideoPlayerController.network(home.splashscreen.image!)
        ..initialize().then((_) {
          setState(() {
            videoDuration = _controller.value.duration;
            printLog(videoDuration.toString(), name: 'DurationVideo');
            duration = videoDuration;
          });
          _controller.play();
          navigateScreen(duration);
        });
    } else if (ext == '.gif') {
      duration = Duration(milliseconds: 5000);
      navigateScreen(duration);
    } else {
      navigateScreen(duration);
    }
  }

  Future navigateScreen(duration) async {
    printLog(duration.toString(), name: 'Duration');
    final home = Provider.of<HomeProvider>(context, listen: false);

    return Timer(duration, () {
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) {
        if (home.introStatus == 'show') {
          return IntroScreen(
            intro: home.intro,
          );
        } else {
          if (!Session.data.containsKey('isIntro')) {
            Session.data.setBool('isLogin', false);
            Session.data.setBool('isIntro', false);
          }
          return Session.data.getBool('isIntro')!
              ? HomeScreen()
              : IntroScreen(
                  intro: home.intro,
                );
        }
      }));
      if (widget.onLinkClicked != null) {
        print("URL Available");
        if (home.introStatus == 'show') {
          Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) {
            return HomeScreen();
          }));
        }
        widget.onLinkClicked!();
      }
    });
  }

  Future _init() async {
    final _packageInfo = await PackageInfo.fromPlatform();

    context.read<HomeProvider>().setPackageInfo(_packageInfo);

    return _packageInfo.version;
  }

  @override
  void initState() {
    super.initState();
    printLog(widget.onLinkClicked.toString());
    loadHome();
  }

  @override
  void setState(fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  loadHome() async {
    await Provider.of<HomeProvider>(context, listen: false)
        .fetchHome(context)
        .then((value) async {
      final appColors =
          Provider.of<HomeProvider>(context, listen: false).appColors;
      this.setState(() {
        loadHomeSuccess = value!;
      });
      appColors.forEach((element) {
        setState(() {
          if (element.title == 'primary') {
            primaryColor = HexColor(element.description!);
          } else {
            secondaryColor = HexColor(element.description!);
          }
        });
      });
      if (loadHomeSuccess) {
        if (mounted) await startSplashScreen();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final home = Provider.of<HomeProvider>(context, listen: false);

    return Scaffold(
        body: home.loading
            ? Container()
            : loadHomeSuccess
                ? isVideo
                    ? videoSplashScreen()
                    : imageSplashScreen()
                : buildError(context));
  }

  imageSplashScreen() {
    final home = Provider.of<HomeProvider>(context, listen: false);

    return Container(
        decoration: BoxDecoration(
            image: DecorationImage(
                fit: BoxFit.cover,
                image: CachedNetworkImageProvider(home.splashscreen.image!))),
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        child: Column(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    home.splashscreen.title!,
                    style: TextStyle(fontSize: 22, color: Colors.grey),
                  ),
                  Text(
                    home.splashscreen.description!,
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            ),
            FutureBuilder(
              future: _init(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  _versionName = snapshot.data as String?;
                  return Text(
                    'Version ' + _versionName!,
                  );
                } else {
                  return Container();
                }
              },
            ),
          ],
        ));
  }

  videoSplashScreen() {
    return Center(
      child: _controller.value.isInitialized
          ? SizedBox(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height,
              child: VideoPlayer(_controller),
            )
          : Container(),
    );
  }
}
