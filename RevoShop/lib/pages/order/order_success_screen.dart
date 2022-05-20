import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:nyoba/pages/home/home_screen.dart';
import 'package:nyoba/provider/home_provider.dart';
import 'package:nyoba/services/session.dart';
import 'package:provider/provider.dart';
import '../../app_localizations.dart';
import '../../utils/utility.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'order_detail_screen.dart';

class OrderSuccess extends StatefulWidget {
  OrderSuccess({Key? key}) : super(key: key);

  @override
  _OrderSuccessState createState() => _OrderSuccessState();
}

class _OrderSuccessState extends State<OrderSuccess> {
  @override
  Widget build(BuildContext context) {
    final orderSuccess =
        Provider.of<HomeProvider>(context, listen: false).imageThanksOrder;
    return WillPopScope(
        child: Scaffold(
          backgroundColor: Colors.white,
          body: Container(
            alignment: Alignment.center,
            margin: EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                orderSuccess.image == null
                    ? Icon(
                        Icons.check_circle_outline,
                        color: primaryColor,
                        size: 75,
                      )
                    : CachedNetworkImage(
                        imageUrl: orderSuccess.image!,
                        height: MediaQuery.of(context).size.height * 0.4,
                        placeholder: (context, url) => Container(),
                        errorWidget: (context, url, error) => Icon(
                              Icons.check_circle_outline,
                              color: primaryColor,
                              size: 75,
                            )),
                Container(
                  width: MediaQuery.of(context).size.width * 0.7,
                  margin: EdgeInsets.only(top: 15),
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(5),
                      gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [primaryColor, secondaryColor])),
                  height: 30.h,
                  child: TextButton(
                    onPressed: () {
                      Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                              builder: (BuildContext context) => HomeScreen()),
                          (Route<dynamic> route) => false);
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => OrderDetail(
                                    orderId:
                                        Session.data.getString('order_number'),
                                  )));
                    },
                    child: Text(
                      'Check Order',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: responsiveFont(10),
                          fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
                Container(
                  margin: EdgeInsets.symmetric(vertical: 10),
                  width: MediaQuery.of(context).size.width * 0.7,
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(color: primaryColor)),
                  height: 30.h,
                  child: TextButton(
                    onPressed: () {
                      Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                              builder: (BuildContext context) => HomeScreen()),
                          (Route<dynamic> route) => false);
                    },
                    child: Text(
                      AppLocalizations.of(context)!.translate('back_to_home')!,
                      style: TextStyle(
                          color: primaryColor,
                          fontSize: responsiveFont(10),
                          fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        onWillPop: () async => false);
  }
}
