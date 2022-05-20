import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:nyoba/models/product_model.dart';
import 'package:nyoba/pages/order/order_success_screen.dart';
import 'package:nyoba/provider/order_provider.dart';
import 'package:nyoba/provider/product_provider.dart';
import 'package:nyoba/services/session.dart';
import 'package:nyoba/utils/currency_format.dart';
import 'package:nyoba/utils/utility.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:slugify/slugify.dart';

import '../../../app_localizations.dart';

class ModalSheetCart extends StatefulWidget {
  final ProductModel? product;
  final String? type;
  final Future<dynamic> Function()? loadCount;
  ModalSheetCart({Key? key, this.product, this.type, this.loadCount})
      : super(key: key);

  @override
  _ModalSheetCartState createState() => _ModalSheetCartState();
}

class _ModalSheetCartState extends State<ModalSheetCart> {
  int index = 0;
  int indexColor = 0;
  int counter = 1;

  List<ProductAttributeModel> attributes = [];
  List<ProductVariation> variation = [];

  bool load = false;
  bool isAvailable = false;
  bool isOutStock = false;

  double variationPrice = 0;
  double variationSalePrice = 0;

  int? variationStock = 0;
  Map<String, dynamic>? variationResult;
  String? variationName;

  /*add to cart*/
  void addCart(ProductModel product) async {
    print('Add Cart');
    if (variationPrice != 0) {
      product.productPrice = variationPrice.toString();
    }
    if (product.variantId != null) {
      product.selectedVariation = variation;
      product.variationName = variationName;
    }
    print(product.productPrice);
    ProductModel productCart = product;

    /*check sharedprefs for cart*/
    if (!Session.data.containsKey('cart')) {
      List<ProductModel> listCart = [];
      productCart.priceTotal =
          (productCart.cartQuantity! * double.parse(productCart.productPrice));

      listCart.add(productCart);

      await Session.data.setString('cart', json.encode(listCart));
      List? products = await json.decode(Session.data.getString('cart')!);
      printLog(products.toString(), name: "Cart Product");
    } else {
      List products = await json.decode(Session.data.getString('cart')!);
      printLog(products.toString(), name: "Cart Product");

      List<ProductModel> listCart = products
          .map((product) => new ProductModel.fromJson(product))
          .toList();

      int index = products.indexWhere((prod) =>
          prod["id"] == productCart.id &&
          prod["variant_id"] == productCart.variantId &&
          prod["variation_name"] == productCart.variationName);

      if (index != -1) {
        productCart.cartQuantity =
            listCart[index].cartQuantity! + productCart.cartQuantity!;

        productCart.priceTotal =
            (productCart.cartQuantity! * double.parse(productCart.productPrice));

        listCart[index] = productCart;

        await Session.data.setString('cart', json.encode(listCart));
      } else {
        productCart.priceTotal =
            (productCart.cartQuantity! * double.parse(productCart.productPrice));
        listCart.add(productCart);
        await Session.data.setString('cart', json.encode(listCart));
        printLog(products.toString(), name: "Cart Product");
      }
    }
    widget.loadCount!();
    this.setState(() {});
    Navigator.pop(context);
    snackBar(context,
        message: AppLocalizations.of(context)!.translate('product_success_atc')!);
  }

  /*get variant id, if product have variant*/
  checkProductVariant(ProductModel productModel) async {
    setState(() {
      load = true;
    });
    var tempVar = [];
    variation.forEach((element) {
      setState(() {
        tempVar.add(element.value);
      });
    });
    variationName = tempVar.join();
    print(variationName);
    final product = Provider.of<ProductProvider>(context, listen: false);
    final Future<Map<String, dynamic>?> productResponse =
        product.checkVariation(productId: productModel.id, list: variation);

    productResponse.then((value) {
      printLog(value.toString(), name: "Response Variation");
      if (value!['variation_id'] != 0) {
        setState(() {
          productModel.variantId = value['variation_id'];
          load = false;
          variationResult = value;
          variationPrice = double.parse(value['data']['price'].toString());

          if (value['data']['wholesales'] != null &&
              value['data']['wholesales'].isNotEmpty) {
            if (value['data']['wholesales'][0]['price'].isNotEmpty &&
                Session.data.getString('role') == 'wholesale_customer') {
              variationPrice =
                  double.parse(value['data']['wholesales'][0]['price']);
            }
          }
          if (value['data']['stock_status'] == 'instock' &&
                  value['data']['stock_quantity'] == null ||
              value['data']['stock_quantity'] == 0) {
            variationStock = 999;
            isAvailable = true;
            isOutStock = false;
          } else if (value['data']['stock_status'] == 'outofstock') {
            print('outofstock');
            isAvailable = true;
            isOutStock = true;
            variationStock = 0;
          } else if (value['data']['price'] == 0) {
            print('price not set');
            isAvailable = false;
            isOutStock = false;
            variationStock = 0;
          } else {
            print('else');
            variationStock = value['data']['stock_quantity'];
            isAvailable = true;
            isOutStock = false;
          }
        });
      } else {
        if (mounted)
          setState(() {
            variationPrice = 0;
            isAvailable = false;
            load = false;
          });
      }
    });
  }

  @override
  void initState() {
    super.initState();
    widget.product!.cartQuantity = 1;
    initVariation();
  }

  /*init variation & check if variation true*/
  initVariation() {
    if (widget.product!.attributes!.isNotEmpty &&
        widget.product!.type == 'variable') {
      widget.product!.attributes!.forEach((element) {
        if (element.variation == true) {
          print("Variation True");
          setState(() {
            attributes.add(element);
            element.selectedVariant = element.options!.first;
            if (element.id != 0 && element.id != null) {
              var _value =
                  element.options!.first.toString().replaceAll('.', '-');
              variation.add(new ProductVariation(
                  id: element.id,
                  value: slugify(_value).replaceAll('--', '-'),
                  columnName: 'pa_${slugify(element.name!)}'));
            } else {
              variation.add(new ProductVariation(
                  id: element.id,
                  value: element.options!.first,
                  columnName: element.name));
            }
          });
        }
      });
      checkProductVariant(widget.product!);
    }
    if (widget.product!.type == 'simple' && widget.product!.productStock != 0) {
      setState(() {
        isAvailable = true;
      });
    }
  }

  Future onFinishBuyNow() async {
    await Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (context) => OrderSuccess()));
  }

  buyNow() async {
    print("Buy Now");
    await Provider.of<OrderProvider>(context, listen: false)
        .buyNow(context, widget.product, onFinishBuyNow);
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Visibility(
                visible: attributes.isNotEmpty,
                child: ListView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    physics: ScrollPhysics(),
                    itemCount: attributes.length,
                    itemBuilder: (context, i) {
                      return buildVariations(i);
                    })),
            Container(
              height: 1,
              width: double.infinity,
              color: HexColor("c4c4c4"),
              margin: EdgeInsets.only(bottom: 15),
            ),
            Container(
                margin: EdgeInsets.only(left: 15, right: 15, bottom: 15),
                child: load
                    ? Shimmer.fromColors(
                        child: Container(
                          height: 25.h,
                          color: Colors.white,
                        ),
                        baseColor: Colors.grey[300]!,
                        highlightColor: Colors.grey[100]!)
                    : !isAvailable
                        ? Container(
                            alignment: Alignment.center,
                            child: Text(
                              AppLocalizations.of(context)!
                                  .translate('select_var_not_avail')!,
                              textAlign: TextAlign.center,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    alignment: Alignment.center,
                                    child: Text(
                                      AppLocalizations.of(context)!
                                          .translate('qty')!,
                                      style: TextStyle(
                                          fontSize: responsiveFont(12)),
                                    ),
                                  ),
                                  SizedBox(
                                    width: 25,
                                  ),
                                  Row(
                                    children: [
                                      Container(
                                        width: 16.w,
                                        height: 16.h,
                                        child: InkWell(
                                          onTap: () {
                                            setState(() {
                                              if (widget.product!.cartQuantity! >
                                                  1) {
                                                widget.product!.cartQuantity =
                                                    widget.product!
                                                            .cartQuantity! -
                                                        1;
                                              }
                                            });
                                          },
                                          child: widget.product!.cartQuantity! > 1
                                              ? Image.asset(
                                                  "images/cart/minusDark.png")
                                              : Image.asset(
                                                  "images/cart/minus.png"),
                                        ),
                                      ),
                                      SizedBox(
                                        width: 10,
                                      ),
                                      Text((widget.product!.cartQuantity)
                                          .toString()),
                                      SizedBox(
                                        width: 10,
                                      ),
                                      Container(
                                        width: 16.w,
                                        height: 16.h,
                                        child: InkWell(
                                            onTap:
                                                widget.product!.productStock! <=
                                                            widget.product!
                                                                .cartQuantity! ||
                                                        isOutStock
                                                    ? null
                                                    : () {
                                                        setState(() {
                                                          widget.product!
                                                              .cartQuantity = widget
                                                                  .product!
                                                                  .cartQuantity! +
                                                              1;
                                                        });
                                                      },
                                            child: widget.product!.productStock! >
                                                        widget.product!
                                                            .cartQuantity! &&
                                                    !isOutStock
                                                ? Image.asset(
                                                    "images/cart/plus.png")
                                                : Image.asset(
                                                    "images/cart/plusDark.png")),
                                      )
                                    ],
                                  ),
                                ],
                              ),
                              widget.product!.type == 'simple'
                                  ? Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          stringToCurrency(
                                              double.parse(widget
                                                      .product!.productPrice)
                                                  .toDouble(),
                                              context),
                                          style: TextStyle(
                                              color: secondaryColor,
                                              fontWeight: FontWeight.w500),
                                        ),
                                        Text(
                                          widget.product!.productStock == 999
                                              ? '${AppLocalizations.of(context)!.translate('stock')} : ${AppLocalizations.of(context)!.translate('available')}'
                                              : '${AppLocalizations.of(context)!.translate('stock')} : ${widget.product!.productStock}',
                                        )
                                      ],
                                    )
                                  : Visibility(
                                      visible:
                                          widget.product!.type == 'variable',
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            stringToCurrency(
                                                variationPrice, context),
                                            style: TextStyle(
                                                color: secondaryColor,
                                                fontWeight: FontWeight.w500),
                                          ),
                                          Text(
                                            variationStock == 999
                                                ? '${AppLocalizations.of(context)!.translate('stock')} : ${AppLocalizations.of(context)!.translate('in_stock')}'
                                                : '${AppLocalizations.of(context)!.translate('stock')} : $variationStock',
                                          )
                                        ],
                                      ))
                            ],
                          )),
            Visibility(
              visible: widget.product!.productStock == null ||
                  widget.product!.productStock == 0,
              child: Container(
                alignment: Alignment.center,
                margin: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                child: Text(
                  "Current product stock is not available",
                  style: TextStyle(color: Colors.red),
                ),
              ),
            )
          ],
        ),
        Visibility(
          visible: widget.type == 'add',
          child: Align(
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
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: 15),
                width: 132.w,
                height: 30.h,
                child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: !isAvailable || load || isOutStock
                              ? Colors.grey
                              : secondaryColor, //Color of the border
                          //Style of the border
                        ),
                        alignment: Alignment.center,
                        shape: new RoundedRectangleBorder(
                            borderRadius: new BorderRadius.circular(5))),
                    onPressed: !isAvailable || load || isOutStock
                        ? null
                        : () {
                            if (widget.product!.productStock != null &&
                                widget.product!.productStock != 0) {
                              addCart(widget.product!);
                            } else {
                              Navigator.pop(context);
                              snackBar(context,
                                  message: 'Product out ouf stock.');
                            }
                          },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add,
                          size: responsiveFont(9),
                          color: !isAvailable || load || isOutStock
                              ? Colors.grey
                              : secondaryColor,
                        ),
                        Text(
                          AppLocalizations.of(context)!.translate('add_to_cart')!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: responsiveFont(9),
                              color: !isAvailable || load || isOutStock
                                  ? Colors.grey
                                  : secondaryColor),
                        )
                      ],
                    )),
              ),
            ),
          ),
        ),
        Visibility(
          visible: widget.type == 'buy',
          child: Align(
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
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: 15),
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(5),
                    gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: !isAvailable || load
                            ? [Colors.black12, Colors.grey]
                            : [primaryColor, secondaryColor])),
                width: double.infinity,
                height: 30.h,
                child: TextButton(
                  onPressed: !isAvailable || load
                      ? null
                      : () {
                          buyNow();
                        },
                  child: Text(
                    AppLocalizations.of(context)!.translate('buy_now')!,
                    style: TextStyle(
                        color: Colors.white, fontSize: responsiveFont(10)),
                  ),
                ),
              ),
            ),
          ),
        )
      ],
    );
  }

  Widget buildVariations(index) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: EdgeInsets.fromLTRB(15, 5, 15, 0),
          child: Text(
            attributes[index].name!,
            style: TextStyle(fontSize: responsiveFont(12)),
          ),
        ),
        Container(
          height: 50,
          margin: EdgeInsets.only(left: 15, right: 15),
          child: ListView.builder(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              scrollDirection: Axis.horizontal,
              itemCount: attributes[index].options!.length,
              itemBuilder: (context, i) {
                return Row(
                  children: [
                    GestureDetector(
                        onTap: () {
                          setState(() {
                            if (attributes[index].id != 0) {
                              attributes[index].selectedVariant =
                                  attributes[index]
                                      .options![i]
                                      .toString()
                                      .toLowerCase();
                            } else {
                              attributes[index].selectedVariant =
                                  attributes[index].options![i];
                            }
                          });
                          variation.forEach((element) {
                            if (element.id != 0) {
                              if (element.columnName ==
                                  'pa_${slugify(attributes[index].name!)}') {
                                print(attributes[index].options![i]);
                                setState(() {
                                  var _value = attributes[index]
                                      .options![i]
                                      .replaceAll('.', '-');
                                  element.value =
                                      slugify(_value).replaceAll('--', '-');
                                });
                              }
                            } else {
                              if (element.columnName ==
                                  attributes[index].name) {
                                setState(() {
                                  element.value = attributes[index].options![i];
                                });
                              }
                            }
                          });
                          checkProductVariant(widget.product!);
                        },
                        child: attributes[index].id == 0
                            ? sizeButton(attributes[index].options![i], index, i)
                            : sizeButtonPA(
                                attributes[index].options![i], index, i)),
                    Container(
                      width: 10,
                    ),
                  ],
                );
              }),
        )
      ],
    );
  }

  Widget colorButton(String color, int indexes) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
            color: indexColor == indexes ? Colors.transparent : secondaryColor),
        borderRadius: BorderRadius.circular(5),
        color: indexColor == indexes ? primaryColor : Colors.white,
      ),
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 3),
      child: Text(
        color,
        style: TextStyle(
            color: indexColor == indexes ? Colors.white : primaryColor),
      ),
    );
  }

  Widget sizeButton(String variant, int groupVariant, int subVariant) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
            color: attributes[groupVariant].selectedVariant ==
                    attributes[groupVariant].options![subVariant]
                ? Colors.transparent
                : secondaryColor),
        borderRadius: BorderRadius.circular(5),
        color: attributes[groupVariant].selectedVariant ==
                attributes[groupVariant].options![subVariant]
            ? primaryColor
            : Colors.white,
      ),
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 3),
      child: Text(
        variant,
        style: TextStyle(
            color: attributes[groupVariant].selectedVariant ==
                    attributes[groupVariant].options![subVariant]
                ? Colors.white
                : primaryColor),
      ),
    );
  }

  Widget sizeButtonPA(String variant, int groupVariant, int subVariant) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
            color: attributes[groupVariant].selectedVariant!.toLowerCase() ==
                    attributes[groupVariant]
                        .options![subVariant]
                        .toString()
                        .toLowerCase()
                ? Colors.transparent
                : secondaryColor),
        borderRadius: BorderRadius.circular(5),
        color: attributes[groupVariant].selectedVariant!.toLowerCase() ==
                attributes[groupVariant]
                    .options![subVariant]
                    .toString()
                    .toLowerCase()
            ? primaryColor
            : Colors.white,
      ),
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 3),
      child: Text(
        variant,
        style: TextStyle(
            color: attributes[groupVariant].selectedVariant!.toLowerCase() ==
                    attributes[groupVariant]
                        .options![subVariant]
                        .toString()
                        .toLowerCase()
                ? Colors.white
                : primaryColor),
      ),
    );
  }
}
