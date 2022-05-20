import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:nyoba/models/cart_model.dart';
import 'package:nyoba/models/order_model.dart';
import 'package:nyoba/models/product_model.dart';
import 'package:nyoba/pages/auth/login_screen.dart';
import 'package:nyoba/provider/product_provider.dart';
import 'package:nyoba/services/order_api.dart';
import 'package:nyoba/services/session.dart';
import 'package:nyoba/utils/utility.dart';
import 'package:nyoba/widgets/webview/checkout_webview.dart';
import 'package:provider/provider.dart';

import '../app_localizations.dart';
import 'coupon_provider.dart';

class OrderProvider with ChangeNotifier {
  ProductModel? productDetail;
  String? status;
  String? search;

  bool isLoading = false;
  bool loadDataOrder = false;

  List<OrderModel> listOrder = [];
  List<OrderModel> tempOrder = [];
  int orderPage = 1;

  List<ProductModel?> listProductOrder = [];

  OrderModel? detailOrder;
  int cartCount = 0;

  Future checkout(order) async {
    var result;
    await OrderAPI().checkoutOrder(order).then((data) {
      printLog(data, name: 'Link Order From API');
      result = data;
    });
    return result;
  }

  Future<List?> fetchOrders({status, search, orderId}) async {
    isLoading = true;
    var result;
    await OrderAPI()
        .listMyOrder(status, search, orderId, orderPage)
        .then((data) {
      result = data;
      List _order = result;
      tempOrder = [];
      tempOrder
          .addAll(_order.map((order) => OrderModel.fromJson(order)).toList());
      List<OrderModel> list = List.from(listOrder);
      list.addAll(tempOrder);
      listOrder = list;
      if (tempOrder.length % 10 == 0) {
        orderPage++;
      }

      listOrder.forEach((element) {
        element.productItems!.sort((a, b) => b.image!.compareTo(a.image!));
      });

      isLoading = false;
      notifyListeners();
      printLog(result.toString());
    });
    return result;
  }

  Future<List?> fetchDetailOrder(orderId) async {
    isLoading = true;
    var result;
    await OrderAPI().detailOrder(orderId).then((data) {
      result = data;
      printLog(result.toString());

      for (Map item in result) {
        detailOrder = OrderModel.fromJson(item);
      }

      isLoading = false;
      notifyListeners();
      printLog(result.toString());
    });
    return result;
  }

  Future<dynamic> loadCartCount() async {
    print('Load Count');
    List<ProductModel> productCart = [];
    int _count = 0;

    if (Session.data.containsKey('cart')) {
      List listCart = await json.decode(Session.data.getString('cart')!);

      productCart = listCart
          .map((product) => new ProductModel.fromJson(product))
          .toList();

      productCart.forEach((element) {
        _count += element.cartQuantity!;
      });
      cartCount = _count;
      notifyListeners();
    }
    return _count;
  }

  Future checkOutOrder(context,
      {int? totalSelected,
      List<ProductModel>? productCart,
      Future<dynamic> Function()? removeOrderedItems}) async {
    final coupons = Provider.of<CouponProvider>(context, listen: false);
    if (totalSelected == 0) {
      snackBar(context, message: "Please select the product first.");
    } else {
      if (Session.data.getBool('isLogin')!) {
        CartModel cart = new CartModel();
        cart.listItem = [];
        productCart!.forEach((element) {
          if (element.isSelected!) {
            var variation = {};
            if (element.selectedVariation!.isNotEmpty) {
              element.selectedVariation!.forEach((elementVar) {
                String columnName = elementVar.columnName!.toLowerCase();
                String? value = elementVar.value;

                variation['attribute_$columnName'] = "$value";
              });
            }
            cart.listItem!.add(new CartProductItem(
                productId: element.id,
                quantity: element.cartQuantity,
                variationId: element.variantId,
                variation: [variation]));
          }
        });

        //init list coupon
        cart.listCoupon = [];
        //check coupon
        if (coupons.couponUsed != null) {
          cart.listCoupon!.add(new CartCoupon(code: coupons.couponUsed!.code));
        }

        //add to cart model
        cart.paymentMethod = "xendit_bniva";
        cart.paymentMethodTitle = "Bank Transfer - BNI";
        cart.setPaid = true;
        cart.customerId = Session.data.getInt('id');
        cart.status = 'completed';
        cart.token = Session.data.getString('cookie');

        //Encode Json
        final jsonOrder = json.encode(cart);
        printLog(jsonOrder, name: 'Json Order');

        //Convert Json to bytes
        var bytes = utf8.encode(jsonOrder);

        //Convert bytes to base64
        var order = base64.encode(bytes);

        //Generate link WebView checkout
        await Provider.of<OrderProvider>(context, listen: false)
            .checkout(order)
            .then((value) async {
          printLog(value, name: 'Link Order');
          await Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => CheckoutWebView(
                        url: value,
                        onFinish: removeOrderedItems,
                      )));
        });
      } else {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => Login(
                      isFromNavBar: false,
                    )));
      }
    }
  }

  Future buyNow(context, ProductModel? product,
      Future<dynamic> Function() onFinishBuyNow) async {
    if (Session.data.getBool('isLogin')!) {
      CartModel cart = new CartModel();
      cart.listItem = [];
      cart.listItem!.add(new CartProductItem(
          productId: product!.id,
          quantity: product.cartQuantity,
          variationId: product.variantId));

      //init list coupon
      cart.listCoupon = [];

      //add to cart model
      cart.paymentMethod = "xendit_bniva";
      cart.paymentMethodTitle = "Bank Transfer - BNI";
      cart.setPaid = true;
      cart.customerId = Session.data.getInt('id');
      cart.status = 'completed';
      cart.token = Session.data.getString('cookie');

      //Encode Json
      final jsonOrder = json.encode(cart);
      printLog(jsonOrder, name: 'Json Order');

      //Convert Json to bytes
      var bytes = utf8.encode(jsonOrder);

      //Convert bytes to base64
      var order = base64.encode(bytes);

      //Generate link WebView checkout
      await Provider.of<OrderProvider>(context, listen: false)
          .checkout(order)
          .then((value) async {
        printLog(value, name: 'Link Order');
        await Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => CheckoutWebView(
                      url: value,
                      onFinish: onFinishBuyNow,
                    )));
      });
    } else {
      Navigator.pop(context);
      snackBar(context,
          message: AppLocalizations.of(context)!.translate('you_login_first')!);
    }
  }

  Future loadItemOrder(context) async {
    loadDataOrder = true;
    if (detailOrder != null) {
      listProductOrder.clear();
      detailOrder!.productItems!.forEach((element) async {
        await Provider.of<ProductProvider>(context, listen: false)
            .fetchProductDetail(element.productId.toString())
            .then((value) {
          listProductOrder.add(value);
        });
      });
      loadDataOrder = false;
    }
  }

  Future<void> actionBuyAgain(context) async {
    detailOrder!.productItems!.forEach((elementOrder) {
      listProductOrder.forEach((element) {
        if (element!.id == elementOrder.productId) {
          print('${element.id} == ${elementOrder.productId}');
          element.cartQuantity = elementOrder.quantity;
          element.variantId = elementOrder.variationId;
          element.priceTotal =
              double.parse(element.productPrice) * element.cartQuantity!;
          element.attributes!.forEach((elementAttr) {
            elementOrder.metaData!.forEach((elementMeta) {
              if (elementAttr.name!.toLowerCase().replaceAll(" ", "-") ==
                  elementMeta.key) {
                elementAttr.selectedVariant = elementMeta.value;
              }
            });
          });
        }
      });
    });
    for (int i = 0; i < listProductOrder.length; i++) {
      await addCart(listProductOrder[i], context);
    }
    snackBar(context,
        message: AppLocalizations.of(context)!.translate('add_cart_message')!);
  }

  /*add to cart*/
  Future addCart(ProductModel? product, context) async {
    /*check sharedprefs for cart*/
    if (!Session.data.containsKey('cart')) {
      List<ProductModel?> listCart = [];

      listCart.add(product);

      await Session.data.setString('cart', json.encode(listCart));
    } else {
      List products = await json.decode(Session.data.getString('cart')!);

      printLog(products.length.toString());
      printLog(products.toString(), name: 'Cart Product');

      List<ProductModel?> listCart =
          products.map((product) => ProductModel.fromJson(product)).toList();

      printLog(listCart.toString(), name: 'List Cart');

      int index = products.indexWhere((prod) =>
          prod["id"] == product!.id && prod["variant_id"] == product.variantId);

      if (index != -1) {
        product!.cartQuantity =
            listCart[index]!.cartQuantity! + product.cartQuantity!;

        listCart[index] = product;

        await Session.data.setString('cart', json.encode(listCart));
      } else {
        listCart.add(product);
        await Session.data.setString('cart', json.encode(listCart));
      }
    }
  }

  resetPage() {
    orderPage = 1;
    listOrder = [];
    tempOrder = [];
    isLoading = true;
    notifyListeners();
  }
}
