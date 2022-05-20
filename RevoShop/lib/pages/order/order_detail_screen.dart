import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:nyoba/models/order_model.dart';
import 'package:nyoba/provider/home_provider.dart';
import 'package:nyoba/provider/order_provider.dart';
import 'package:nyoba/services/session.dart';
import 'package:nyoba/utils/currency_format.dart';
import 'package:nyoba/utils/utility.dart';
import 'package:nyoba/widgets/order/order_detail_shimmer.dart';
import 'package:nyoba/widgets/webview/checkout_webview.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../../app_localizations.dart';

class OrderDetail extends StatefulWidget {
  final String? orderId;
  OrderDetail({Key? key, this.orderId}) : super(key: key);

  @override
  _OrderDetailState createState() => _OrderDetailState();
}

class _OrderDetailState extends State<OrderDetail> {
  _launchWAURL(String? phoneNumber) async {
    String url = 'https://api.whatsapp.com/send?phone=$phoneNumber&text=Hi';
    if (await canLaunchUrlString(url)) {
      await launchUrlString(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  @override
  void initState() {
    super.initState();
    loadOrder();
  }

  loadOrder() async {
    await Provider.of<OrderProvider>(context, listen: false)
        .fetchDetailOrder(widget.orderId)
        .then((value) => loadOrderedItems());
  }

  loadOrderedItems() async {
    await Provider.of<OrderProvider>(context, listen: false)
        .loadItemOrder(context);
    Session.data.remove('order_number');
    this.setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final contact = Provider.of<HomeProvider>(context, listen: false);
    final order = Provider.of<OrderProvider>(context, listen: false);

    Widget buildOrder = ListenableProvider.value(
      value: order,
      child: Consumer<OrderProvider>(builder: (context, value, child) {
        if (value.isLoading) {
          return OrderDetailShimmer();
        }
        return Column(
          children: [
            Expanded(
              child: ListView(
                children: [
                  Container(
                    margin: EdgeInsets.only(top: 15, left: 15, right: 15),
                    child: Row(
                      children: [
                        Container(
                            width: 30.w,
                            height: 30.h,
                            child: Icon(Icons.shopping_bag_outlined)),
                        Container(
                          width: 10,
                        ),
                        Row(
                          children: [
                            Text(
                              'Order ID : ',
                              style: TextStyle(
                                  fontSize: responsiveFont(12),
                                  fontWeight: FontWeight.w500),
                            ),
                            Text(
                              "${order.detailOrder!.id}",
                              style: TextStyle(
                                  fontSize: responsiveFont(12),
                                  fontWeight: FontWeight.w500,
                                  color: secondaryColor),
                            )
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    color: HexColor("EEEEEE"),
                    margin: EdgeInsets.all(15),
                    height: 2,
                    width: double.infinity,
                  ),
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: 15),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                            width: 30.w,
                            height: 30.h,
                            child: Icon(Icons.local_shipping_outlined)),
                        Container(
                          width: 10,
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppLocalizations.of(context)!
                                    .translate('shipping_information')!,
                                style: TextStyle(
                                    fontSize: responsiveFont(12),
                                    fontWeight: FontWeight.w500),
                              ),
                              order.detailOrder!.shippingServices!.isEmpty
                                  ? Text(
                                      "-",
                                      style: TextStyle(
                                          fontSize: responsiveFont(10)),
                                    )
                                  : Text(
                                      "${order.detailOrder!.shippingServices![0].serviceName} - ",
                                      style: TextStyle(
                                          fontSize: responsiveFont(10)),
                                    )
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                  Container(
                    color: HexColor("EEEEEE"),
                    margin: EdgeInsets.all(15),
                    height: 2,
                    width: double.infinity,
                  ),
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: 15),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                            width: 30.w,
                            height: 30.h,
                            child: Icon(Icons.location_on_outlined)),
                        Container(
                          width: 10,
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppLocalizations.of(context)!
                                    .translate('shipping_address')!,
                                style: TextStyle(
                                    fontSize: responsiveFont(12),
                                    fontWeight: FontWeight.w500),
                              ),
                              Text(
                                "${order.detailOrder!.billingInfo!.firstName} ${order.detailOrder!.billingInfo!.lastName}",
                                style: TextStyle(fontSize: responsiveFont(11)),
                              ),
                              Text(
                                order.detailOrder!.billingInfo!.phone!,
                                style: TextStyle(fontSize: responsiveFont(11)),
                              ),
                              Text(
                                order.detailOrder!.billingInfo!.firstAddress!,
                                style: TextStyle(fontSize: responsiveFont(11)),
                              )
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                  Container(
                    color: HexColor("EEEEEE"),
                    margin: EdgeInsets.all(15),
                    height: 2,
                    width: double.infinity,
                  ),
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: 15),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                            width: 30.w,
                            height: 30.h,
                            child: Icon(Icons.credit_card_outlined)),
                        Container(
                          width: 10,
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    AppLocalizations.of(context)!
                                        .translate('payment_info')!,
                                    style: TextStyle(
                                        fontSize: responsiveFont(12),
                                        fontWeight: FontWeight.w500),
                                  ),
                                  buildBtnPay()
                                ],
                              ),
                              SizedBox(
                                height: 10,
                              ),
                              Text(
                                AppLocalizations.of(context)!
                                    .translate('payment_method')!,
                                style: TextStyle(
                                    fontSize: responsiveFont(10),
                                    fontWeight: FontWeight.w600),
                              ),
                              Text(
                                "${order.detailOrder!.paymentMethodTitle}",
                                style: TextStyle(
                                    fontSize: responsiveFont(12),
                                    fontWeight: FontWeight.w400),
                              ),
                              SizedBox(
                                height: 10,
                              ),
                              Text(
                                AppLocalizations.of(context)!
                                    .translate('payment_description')!,
                                style: TextStyle(
                                    fontSize: responsiveFont(10),
                                    fontWeight: FontWeight.w600),
                              ),
                              Text(
                                "${order.detailOrder!.paymentDescription}",
                                style: TextStyle(
                                    fontSize: responsiveFont(12),
                                    fontWeight: FontWeight.w400),
                              ),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                  Visibility(
                    visible: order.detailOrder!.customerNote!.isNotEmpty,
                    child: Column(
                      children: [
                        Container(
                          margin: EdgeInsets.symmetric(vertical: 10),
                          color: HexColor("EEEEEE"),
                          height: 2,
                          width: double.infinity,
                        ),
                        Container(
                          margin: EdgeInsets.symmetric(horizontal: 15),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                  width: 30.w,
                                  height: 30.h,
                                  child: Icon(Icons.assignment_outlined)),
                              Container(
                                width: 10,
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      AppLocalizations.of(context)!
                                          .translate('order_notes')!,
                                      style: TextStyle(
                                          fontSize: responsiveFont(12),
                                          fontWeight: FontWeight.w500),
                                    ),
                                    SizedBox(
                                      height: 10,
                                    ),
                                    Text(
                                      "${order.detailOrder!.customerNote}",
                                      style: TextStyle(
                                          fontSize: responsiveFont(12),
                                          fontWeight: FontWeight.w400),
                                    ),
                                  ],
                                ),
                              )
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    color: HexColor("EEEEEE"),
                    margin: EdgeInsets.only(top: 15, bottom: 15),
                    height: 5,
                    width: double.infinity,
                  ),
                  ListView.builder(
                      shrinkWrap: true,
                      physics: ScrollPhysics(),
                      itemCount: order.detailOrder!.productItems!.length,
                      itemBuilder: (context, i) {
                        return item(order.detailOrder!.productItems![i]);
                      }),
                  Container(
                    height: 5,
                  ),
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              AppLocalizations.of(context)!
                                  .translate('subtotal')!,
                              style: TextStyle(
                                  fontSize: responsiveFont(11),
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500),
                            ),
                            Text(
                              stringToCurrency(
                                  order.detailOrder!.subTotal!, context),
                              style: TextStyle(fontSize: responsiveFont(11)),
                            )
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                                AppLocalizations.of(context)!
                                    .translate('shipping_cost')!,
                                style: TextStyle(
                                    fontSize: responsiveFont(11),
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500)),
                            Text(
                                stringToCurrency(
                                    double.parse(
                                        order.detailOrder!.shippingTotal!),
                                    context),
                                style: TextStyle(fontSize: responsiveFont(11))),
                          ],
                        ),
                        Visibility(
                          visible: order.detailOrder!.discountTotal != "0.0",
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                  AppLocalizations.of(context)!
                                      .translate('discount')!,
                                  style: TextStyle(
                                      fontSize: responsiveFont(11),
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w500)),
                              Text(
                                  "-${stringToCurrency(double.parse(order.detailOrder!.discountTotal!), context)}",
                                  style: TextStyle(
                                      fontSize: responsiveFont(11),
                                      color: primaryColor)),
                            ],
                          ),
                        ),
                        Container(
                          color: HexColor("EEEEEE"),
                          margin: EdgeInsets.only(top: 5, bottom: 5),
                          height: 1,
                          width: double.infinity,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                                AppLocalizations.of(context)!
                                    .translate('total_order')!,
                                style: TextStyle(
                                    fontSize: responsiveFont(12),
                                    fontWeight: FontWeight.w600)),
                            order.detailOrder!.discountTotal != "0"
                                ? Text(
                                    stringToCurrency(
                                        double.parse(order.detailOrder!.total!),
                                        context),
                                    style: TextStyle(
                                      fontSize: responsiveFont(12),
                                      fontWeight: FontWeight.w600,
                                    ))
                                : Text(
                                    stringToCurrency(
                                        double.parse(order.detailOrder!.total!),
                                        context),
                                    style: TextStyle(
                                      fontSize: responsiveFont(12),
                                      fontWeight: FontWeight.w600,
                                    )),
                          ],
                        )
                      ],
                    ),
                  )
                ],
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: Colors.black54,
                        blurRadius: 15.0,
                      )
                    ],
                  ),
                  height: 45.h,
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      //buy again
                      buildBtnBuyAgain(),
                      Container(
                        width: 10,
                      ),
                      Expanded(
                        child: Container(
                          height: 30.h,
                          margin: EdgeInsets.only(right: 15),
                          child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                  side: BorderSide(
                                    color: secondaryColor, //Color of the border
                                    //Style of the border
                                  ),
                                  alignment: Alignment.center,
                                  shape: new RoundedRectangleBorder(
                                      borderRadius:
                                          new BorderRadius.circular(5))),
                              onPressed: () {
                                _launchWAURL(contact.wa.description);
                              },
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Image.asset(
                                    "images/order/wa.png",
                                    width: 20.w,
                                    height: 20.h,
                                  ),
                                  Text(
                                    AppLocalizations.of(context)!
                                        .translate('contact_seller')!,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        fontSize: responsiveFont(9),
                                        color: secondaryColor),
                                  )
                                ],
                              )),
                        ),
                      )
                    ],
                  )),
            ),
          ],
        );
      }),
    );

    return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          leading: IconButton(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: Icon(
              Icons.arrow_back,
              color: Colors.black,
            ),
          ),
          title: Text(
            "Order Detail",
            style: TextStyle(
                color: Colors.black,
                fontSize: responsiveFont(16),
                fontWeight: FontWeight.w500),
          ),
        ),
        body: buildOrder);
  }

  Widget item(ProductItems productItems) {
    return Container(
      height: 80.h,
      margin: EdgeInsets.only(left: 15),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 55.h,
                height: 55.h,
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(5),
                    color: HexColor("c4c4c4")),
                child: productItems.image == null && productItems.image == ''
                    ? Icon(
                        Icons.image_not_supported_outlined,
                      )
                    : CachedNetworkImage(
                        imageUrl: productItems.image!,
                        placeholder: (context, url) => Container(),
                        errorWidget: (context, url, error) =>
                            Icon(Icons.image_not_supported_outlined)),
              ),
              SizedBox(
                width: 15,
              ),
              Flexible(
                child: Container(
                  height: 55.h,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        convertHtmlUnescape(productItems.productName!),
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: responsiveFont(12),
                            fontWeight: FontWeight.w600),
                      ),
                      Text(
                        "${productItems.quantity} x ${stringToCurrency((double.parse(productItems.subTotal!)), context)}",
                        style: TextStyle(fontSize: responsiveFont(10)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Container(
            margin: EdgeInsets.only(top: 10, bottom: 10),
            width: double.infinity,
            height: 2,
            color: HexColor("EEEEEE"),
          )
        ],
      ),
    );
  }

  buildBtnBuyAgain() {
    final order = Provider.of<OrderProvider>(context, listen: false);

    return ListenableProvider.value(
      value: order,
      child: Consumer<OrderProvider>(builder: (context, value, child) {
        if (value.loadDataOrder) {
          return Expanded(
            child: Container(
              margin: EdgeInsets.only(left: 15),
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(5), color: Colors.grey),
              height: 30.h,
              child: TextButton(
                onPressed: null,
                child: Text(
                  AppLocalizations.of(context)!.translate('buy_again')!,
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: responsiveFont(12),
                      fontWeight: FontWeight.w600),
                ),
              ),
            ),
          );
        }
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(left: 15),
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5),
                gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [primaryColor, secondaryColor])),
            height: 30.h,
            child: TextButton(
              onPressed: () {
                order.actionBuyAgain(context);
              },
              child: Text(
                AppLocalizations.of(context)!.translate('buy_again')!,
                style: TextStyle(
                    color: Colors.white,
                    fontSize: responsiveFont(10),
                    fontWeight: FontWeight.w600),
              ),
            ),
          ),
        );
      }),
    );
  }

  buildBtnPay() {
    final order = Provider.of<OrderProvider>(context, listen: false);

    if (order.isLoading) {
      return Container();
    }
    return Visibility(
      visible: order.detailOrder!.paymentMethodTitle == 'OVO' ||
          order.detailOrder!.paymentMethodTitle == 'GOPAY' &&
              order.detailOrder!.datePaid == null,
      child: order.detailOrder!.status == 'pending' ||
              order.detailOrder!.status == 'on-hold'
          ? Container(
              margin: EdgeInsets.only(right: 15),
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(5),
                  gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [primaryColor, secondaryColor])),
              height: 30.h,
              width: 50.w,
              child: TextButton(
                onPressed: () async {
                  print(order.detailOrder!.paymentUrl);
                  await Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => CheckoutWebView(
                                url: order.detailOrder!.paymentUrl,
                                fromOrder: true,
                              ))).then((value) {
                    this.setState(() {});
                    this.loadOrder();
                  });
                },
                child: Text(
                  AppLocalizations.of(context)!.translate('pay')!,
                  style: TextStyle(
                      color: Colors.white, fontSize: responsiveFont(10)),
                ),
              ),
            )
          : Container(),
    );
  }
}
