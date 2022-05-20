import 'dart:async';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:nyoba/models/login_model.dart';
import 'package:nyoba/models/user_model.dart';
import 'package:nyoba/pages/home/home_screen.dart';
import 'dart:convert';
import 'package:nyoba/services/login_api.dart';
import 'package:nyoba/services/session.dart';
import 'package:nyoba/utils/utility.dart';
import 'package:provider/provider.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import 'home_provider.dart';

class LoginProvider with ChangeNotifier {
  LoginModel? userLogin;
  bool loading = false;
  String? message;
  String? countryCode = '+62';

  AccessToken? fbAccessToken;
  Map<String, dynamic>? fbUserData;

  late FirebaseAuth _firebaseAuth;

  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  Future<Map<String, dynamic>?> login(context, {username, password}) async {
    var result;
    try {
      loading = true;
      await LoginAPI().loginByDefault(username, password).then((data) {
        result = data;

        if (result['cookie'] != null) {
          UserModel user = UserModel.fromJson(result['user']);
          Session().saveUser(user, result['cookie']);
          Session.data.setString("login_type", 'default');
          final home = Provider.of<HomeProvider>(context, listen: false);

          home.isReload = true;
          Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                  builder: (BuildContext context) => HomeScreen()),
              (Route<dynamic> route) => false);
          inputDeviceToken();
        } else {
          snackBar(context, message: result['message'], color: Colors.red);
        }
        loading = false;

        notifyListeners();
        printLog(result.toString());
      });
    } catch (e) {
      print(e.toString());
      loading = false;
      notifyListeners();
      snackBar(context,
          message: 'Opps, something is wrong. Please contact the developer',
          color: Colors.red);
    }
    return result;
  }

  Future<void> signInOTP(context, phone) async {
    loading = true;
    await LoginAPI().loginByOTP(phone).then((data) {
      if (data.statusCode == 200) {
        final responseJson = json.decode(data.body);
        Session.data.setBool('isLogin', true);
        Session.data.setString("cookie", responseJson['cookie']);
        Session.data.setString("login_type", 'otp');

        if (responseJson['user'] != null &&
            responseJson['user'] != "User OTP") {
          Session.data.setString("firstname", responseJson['user']);
        } else {
          Session.data.setString("firstname", responseJson['user_login']);
        }

        final home = Provider.of<HomeProvider>(context, listen: false);

        home.isReload = true;
        loading = false;

        inputDeviceToken();
        notifyListeners();
      } else {
        loading = false;
        notifyListeners();
      }
    });
  }

  Future signInWithGoogle(context) async {
    final FirebaseAuth _auth = FirebaseAuth.instance;
    final GoogleSignIn _googleSignIn = GoogleSignIn();

    GoogleSignInAccount googleSignInAccount = await (_googleSignIn.signIn() as FutureOr<GoogleSignInAccount>);
    GoogleSignInAuthentication googleSignInAuthentication =
        await googleSignInAccount.authentication;

    AuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleSignInAuthentication.accessToken,
      idToken: googleSignInAuthentication.idToken,
    );

    final UserCredential authResult =
        await _auth.signInWithCredential(credential);
    final User? user = authResult.user;

    if (user != null) {
      await LoginAPI()
          .loginByGoogle(googleSignInAuthentication.accessToken)
          .then((data) {
        final responseJson = json.decode(data.body);
        if (data.statusCode == 200) {
          Session.data.setBool('isLogin', true);
          Session.data.setString("cookie", responseJson['cookie']);
          Session.data.setString("username", responseJson['user_login']);
          Session.data.setString("login_type", 'google');

          loading = false;
          final home = Provider.of<HomeProvider>(context, listen: false);
          home.isReload = true;
          inputDeviceToken();
          notifyListeners();
          return responseJson;
        } else {
          loading = false;
          notifyListeners();
          return responseJson;
        }
      });
    }
  }

  String prettyPrint(Map json) {
    JsonEncoder encoder = new JsonEncoder.withIndent('  ');
    String pretty = encoder.convert(json);
    return pretty;
  }

  void _printCredentials() {
    print(
      prettyPrint(fbAccessToken!.toJson()),
    );
  }

  Future<void> signInWithFacebook(context) async {
    final LoginResult result = await FacebookAuth.instance
        .login(); // by the fault we request the email and the public profilea

    if (result.status == LoginStatus.success) {
      fbAccessToken = result.accessToken;

      final userData = await FacebookAuth.instance.getUserData();
      fbUserData = userData;
      _printCredentials();
      await LoginAPI().loginByFacebook(fbAccessToken!.token).then((data) {
        final responseJson = json.decode(data.body);
        if (data.statusCode == 200) {
          Session.data.setBool('isLogin', true);
          Session.data.setString("cookie", responseJson['cookie']);
          Session.data.setString("username", responseJson['user_login']);
          Session.data.setString("login_type", 'facebook');

          final home = Provider.of<HomeProvider>(context, listen: false);
          home.isReload = true;

          loading = false;
          inputDeviceToken();
          notifyListeners();
          return responseJson;
        } else {
          loading = false;
          notifyListeners();
          return responseJson;
        }
      });
    } else {
      print(result.status);
      print(result.message);
    }
  }

  Future<Map<String, dynamic>?> inputDeviceToken() async {
    var result;
    await LoginAPI().inputTokenAPI().then((data) {
      result = data;
      loading = false;
      notifyListeners();
      printLog(result.toString());
    });
    return result;
  }

  Future<bool?> forgotPassword(context, {email}) async {
    bool? isSuccess;
    loading = true;
    var result;
    await LoginAPI().forgotPasswordAPI(email).then((data) {
      result = data;

      if (result['status'] == 'success') {
        isSuccess = true;
      } else {
        isSuccess = false;
        snackBar(context, message: result['message'], color: Colors.red);
      }
      loading = false;

      notifyListeners();
      printLog(result.toString());
    });
    return isSuccess;
  }

  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }

  /// Generates a cryptographically secure random nonce, to be included in a
  /// credential request.
  String generateNonce([int length = 32]) {
    final charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)])
        .join();
  }

  /// Returns the sha256 hash of [input] in hex notation.
  String sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<UserCredential> signInWithApple(context) async {
    // To prevent replay attacks with the credential returned from Apple, we
    // include a nonce in the credential request. When signing in in with
    // Firebase, the nonce in the id token returned by Apple, is expected to
    // match the sha256 hash of `rawNonce`.
    final firebaseAuth = FirebaseAuth.instance;
    final rawNonce = generateNonce();
    final nonce = sha256ofString(rawNonce);
    String? userEmail, userName, displayName;

    final appleCredential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
      nonce: nonce,
    );

    printLog(appleCredential.toString(), name: 'Apple Credential');

    // Create an `OAuthCredential` from the credential returned by Apple.
    final oauthCredential = OAuthProvider("apple.com").credential(
      idToken: appleCredential.identityToken,
      rawNonce: rawNonce,
    );

    printLog(oauthCredential.toString(), name: 'OAUTH');

    final dynamic authResult =
    await firebaseAuth.signInWithCredential(oauthCredential).then((value) async {
      displayName =
      '${appleCredential.givenName} ${appleCredential.familyName}';
      userName =
      '${appleCredential.familyName}${appleCredential.familyName}';

      if (appleCredential.email != null){
        userEmail = '${appleCredential.email}';
        Session.data.setString('email_apple', userEmail!);
      } else {
        userEmail = Session.data.getString('email_apple');
      }

      await LoginAPI()
          .loginByApple(userEmail.toString(), displayName.toString(),
          userName.toString().toLowerCase())
          .then((data) {
        printLog(data.toString(), name: 'API Apple SignIn');
        if (data['wp_user_id'] != null) {
          Session.data.setBool('isLogin', true);
          Session.data.setString("cookie", data['cookie']);
          Session.data.setString("username", data['user_login']);
          Session.data.setString("login_type", 'apple');

          final home = Provider.of<HomeProvider>(context, listen: false);
          home.isReload = true;

          loading = false;
          inputDeviceToken();
          notifyListeners();
          return data;
        } else {
          loading = false;
          notifyListeners();
          return data;
        }
      });
    });
    return authResult;
  }
}
