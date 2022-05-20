import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_countdown_timer/current_remaining_time.dart';
import 'package:flutter_countdown_timer/flutter_countdown_timer.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:nyoba/models/variation_model.dart';
import 'package:nyoba/pages/category/brand_product_screen.dart';
import 'package:nyoba/pages/order/cart_screen.dart';
import 'package:nyoba/pages/product/product_more_screen.dart';
import 'package:nyoba/pages/product/modal_sheet_cart/modal_sheet_cart.dart';
import 'package:nyoba/pages/wishlist/wishlist_screen.dart';
import 'package:nyoba/provider/flash_sale_provider.dart';
import 'package:nyoba/provider/order_provider.dart';
import 'package:nyoba/provider/product_provider.dart';
import 'package:nyoba/provider/review_provider.dart';
import 'package:nyoba/provider/wishlist_provider.dart';
import 'package:nyoba/services/product_api.dart';
import 'package:nyoba/services/session.dart';
import 'package:nyoba/utils/currency_format.dart';
import 'package:nyoba/utils/share_link.dart';
import 'package:nyoba/widgets/contact/contact_fab.dart';
import 'package:nyoba/widgets/home/card_item_shimmer.dart';
import 'package:nyoba/widgets/home/card_item_small.dart';
import 'package:nyoba/widgets/product/product_photoview.dart';
import 'package:nyoba/widgets/product/product_detail_shimmer.dart';
import 'package:nyoba/widgets/youtube/youtube_player.dart';
import 'package:provider/provider.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import '../../app_localizations.dart';
import '../../models/product_model.dart';
import '../../utils/utility.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:colorful_safe_area/colorful_safe_area.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'product_review_screen.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:like_button/like_button.dart';

import 'featured_products/all_featured_product_screen.dart';

class ProductDetail extends StatefulWidget {
  final String? productId;
  final String? slug;
  ProductDetail({Key? key, this.productId, this.slug}) : super(key: key);

  @override
  _ProductDetailState createState() => _ProductDetailState();
}

class _ProductDetailState extends State<ProductDetail>
    with TickerProviderStateMixin {
  late AnimationController _colorAnimationController;
  late AnimationController _textAnimationController;

  int itemCount = 10;

  bool? isWishlist = false;

  int cartCount = 0;
  TextEditingController reviewController = new TextEditingController();

  double rating = 0;

  int endTime = DateTime.now().millisecondsSinceEpoch + 1000 * 30;
  bool isFlashSale = false;

  ProductModel? productModel;
  final CarouselController _controller = CarouselController();
  int _current = 0;

  RefreshController _refreshController =
      RefreshController(initialRefresh: false);

  List<double> variantPrices = [];

  @override
  void initState() {
    super.initState();

    _colorAnimationController =
        AnimationController(vsync: this, duration: Duration(seconds: 0));
    _textAnimationController =
        AnimationController(vsync: this, duration: Duration(seconds: 0));
    loadDetail();
  }

  @override
  void setState(fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  bool scrollListener(ScrollNotification scrollInfo) {
    if (scrollInfo.metrics.axis == Axis.vertical) {
      _colorAnimationController.animateTo(scrollInfo.metrics.pixels / 350);
      _textAnimationController
          .animateTo((scrollInfo.metrics.pixels - 350) / 50);
      return true;
    } else {
      return false;
    }
  }

  Future loadDetail() async {
    final productProvider =
        Provider.of<ProductProvider>(context, listen: false);

    loadCartCount();
    if (widget.slug == null) {
      await Provider.of<ProductProvider>(context, listen: false)
          .fetchProductDetail(widget.productId)
          .then((value) async {
        setState(() {
          productModel = value;
          printLog(productModel.toString(), name: 'Product Model');
          productModel!.isSelected = false;
        });
        loadVariationData().then((value) {
          printLog('Load Stop', name: 'Load Stop');
          productProvider.loadingDetail = false;
        });
        if (Session.data.getBool('isLogin')!)
          await productProvider.hitViewProducts(widget.productId).then(
              (value) async => await productProvider.fetchRecentProducts());
      });
    } else {
      await Provider.of<ProductProvider>(context, listen: false)
          .fetchProductDetailSlug(widget.slug)
          .then((value) {
        setState(() {
          productModel = value;
          productModel!.isSelected = false;
          productProvider.loadingDetail = false;
          printLog(productModel.toString(), name: 'Product Model');
        });
        loadVariationData().then((value) {
          printLog('Load Stop', name: 'Load Stop');
          productProvider.loadingDetail = false;
        });
      });
    }
    if (mounted) secondLoad();
  }

  secondLoad() {
    final wishlist = Provider.of<WishlistProvider>(context, listen: false);

    checkFlashSale();

    if (Session.data.getBool('isLogin')!) {
      final Future<Map<String, dynamic>?> checkWishlist =
          wishlist.checkWishlistProduct(productId: productModel!.id.toString());

      checkWishlist.then((value) {
        printLog('Cek Wishlist Success');
        setState(() {
          isWishlist = value!['message'];
        });
      });
    }
    loadReviewProduct();
  }

  Future<bool?> setWishlist(bool? isLiked) async {
    if (Session.data.getBool('isLogin')!) {
      setState(() {
        isWishlist = !isWishlist!;
        isLiked = isWishlist;
      });
      final wishlist = Provider.of<WishlistProvider>(context, listen: false);

      final Future<Map<String, dynamic>?> setWishlist = wishlist
          .setWishlistProduct(context, productId: productModel!.id.toString());

      setWishlist.then((value) {
        print("200");
      });
    } else {
      Navigator.push(
          context, MaterialPageRoute(builder: (context) => WishList()));
    }
    return isLiked;
  }

  Future<dynamic> loadCartCount() async {
    await Provider.of<OrderProvider>(context, listen: false)
        .loadCartCount()
        .then((value) {
      setState(() {
        cartCount = value;
      });
    });
  }

  Future<bool> loadVariationData() async {
    await ProductAPI()
        .productVariations(
            productId: widget.slug == null
                ? widget.productId
                : productModel!.id.toString())
        .then((value) {
      if (value.statusCode == 200) {
        final variation = json.decode(value.body);
        List<VariationModel> variations = [];

        for (Map item in variation) {
          if (item['price'].isNotEmpty) {
            variations.add(VariationModel.fromJson(item));
          }
        }

        variations.forEach((v) {
          variantPrices.add(double.parse(v.price!));
          if (widget.slug != null) {
            productModel!.variationPrices!.add(double.parse(v.price!));
          }
        });

        variantPrices.sort((a, b) => a.compareTo(b));
        if (widget.slug != null) {
          productModel!.variationPrices!.sort((a, b) => a!.compareTo(b!));
        }
      }
    });
    return true;
  }

  loadReviewProduct() async {
    await Provider.of<ReviewProvider>(context, listen: false)
        .fetchReviewProductLimit(productModel!.id.toString())
        .then((value) => loadLikeProduct());
  }

  loadLikeProduct() async {
    if (mounted) {
      await Provider.of<ProductProvider>(context, listen: false)
          .fetchCategoryProduct(productModel!.categories![0].id.toString());
    }
  }

  checkFlashSale() {
    final flashsale = Provider.of<FlashSaleProvider>(context, listen: false);
    if (flashsale.flashSales.isNotEmpty) {
      setState(() {
        endTime = DateTime.parse(flashsale.flashSales[0].endDate!)
            .millisecondsSinceEpoch;
      });
    }

    if (flashsale.flashSaleProducts.isNotEmpty) {
      flashsale.flashSaleProducts.forEach((element) {
        if (productModel!.id.toString() == element.id.toString()) {
          setState(() {
            isFlashSale = true;
          });
        }
      });
    }
  }

  refresh() async {
    this.setState(() {});
    await loadDetail().then((value) {
      this.setState(() {});
      _refreshController.refreshCompleted();
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final product = Provider.of<ProductProvider>(context, listen: false);

    Widget buildWishlistBtn = LikeButton(
      size: 25,
      onTap: setWishlist,
      circleColor: CircleColor(start: primaryColor, end: secondaryColor),
      bubblesColor: BubblesColor(
        dotPrimaryColor: primaryColor,
        dotSecondaryColor: secondaryColor,
      ),
      isLiked: isWishlist,
      likeBuilder: (bool isLiked) {
        if (!isLiked) {
          return Icon(
            Icons.favorite_border,
            color: Colors.grey,
            size: 25,
          );
        }
        return Icon(
          Icons.favorite,
          color: Colors.red,
          size: 25,
        );
      },
    );

    return ListenableProvider.value(
      value: product,
      child: Consumer<ProductProvider>(builder: (context, value, child) {
        if (value.loadingDetail) {
          return ProductDetailShimmer();
        }
        List<Widget> itemSlider = [
          Icon(
            Icons.broken_image_outlined,
            size: 80,
          )
        ];
        if (productModel!.images!.isNotEmpty ||
            productModel!.videos!.isNotEmpty) {
          itemSlider = [
            InkWell(
              onTap: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => ProductPhotoView(
                              image: productModel!.images![0].src,
                            )));
              },
              child: AspectRatio(
                aspectRatio: 1 / 1,
                child: CachedNetworkImage(
                  imageUrl: productModel!.images![0].src!,
                  placeholder: (context, url) => customLoading(),
                  errorWidget: (context, url, error) => Icon(
                    Icons.image_not_supported_rounded,
                    size: 25,
                  ),
                ),
              ),
            ),
            for (var i = 0; i < productModel!.videos!.length; i++)
              Container(
                child: YoutubePlayerWidget(
                  url: productModel!.videos![i].content,
                ),
              ),
            for (var i = 1; i < productModel!.images!.length; i++)
              InkWell(
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => ProductPhotoView(
                                  image: productModel!.images![i].src,
                                )));
                  },
                  child: AspectRatio(
                    aspectRatio: 1 / 1,
                    child: CachedNetworkImage(
                      imageUrl: productModel!.images![i].src!,
                      placeholder: (context, url) => customLoading(),
                      errorWidget: (context, url, error) => Icon(
                        Icons.image_not_supported_rounded,
                        size: 25,
                      ),
                    ),
                  ))
          ];
        }
        return ColorfulSafeArea(
          color: Colors.white,
          child: Scaffold(
            floatingActionButton: ContactFAB(),
            appBar: appBar(productModel!) as PreferredSizeWidget?,
            body: Stack(
              children: [
                SmartRefresher(
                  controller: _refreshController,
                  onRefresh: refresh,
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        Stack(
                          children: [
                            CarouselSlider(
                              options: CarouselOptions(
                                  enableInfiniteScroll: false,
                                  viewportFraction: 1,
                                  aspectRatio: 1 / 1,
                                  onPageChanged: (index, reason) {
                                    setState(() {
                                      _current = index;
                                    });
                                  }),
                              carouselController: _controller,
                              items: itemSlider,
                            ),
                            Positioned(
                              bottom: 10,
                              left: 0,
                              right: 0,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children:
                                    itemSlider.asMap().entries.map((entry) {
                                  return GestureDetector(
                                    onTap: () =>
                                        _controller.animateToPage(entry.key),
                                    child: Container(
                                        width: 10.0,
                                        height: 10.0,
                                        margin: EdgeInsets.symmetric(
                                            vertical: 5.0, horizontal: 2.0),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: _current == entry.key
                                              ? primaryColor
                                              : primaryColor.withOpacity(0.5),
                                        )),
                                  );
                                }).toList(),
                              ),
                            )
                          ],
                        ),
                        Visibility(
                          visible: isFlashSale,
                          child: Container(
                            width: double.infinity,
                            height: 50,
                            decoration: BoxDecoration(
                                image: DecorationImage(
                                    fit: BoxFit.cover,
                                    image: AssetImage(
                                        "images/product_detail/bg_flashsale.png"))),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 10),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        "FLASH SALE ENDS IN :",
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 14),
                                      ),
                                      Text(
                                          "${productModel!.totalSales} Item Sold",
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 10)),
                                    ],
                                  ),
                                ),
                                Container(
                                    padding:
                                        EdgeInsets.symmetric(horizontal: 10),
                                    alignment: Alignment.center,
                                    child: CountdownTimer(
                                      endTime: endTime,
                                      widgetBuilder:
                                          (_, CurrentRemainingTime? time) {
                                        int? hours = time!.hours;
                                        if (time.days != null &&
                                            time.days != 0) {
                                          hours =
                                              (time.days! * 24) + time.hours!;
                                        } else {
                                          return Text('Flash Sale END');
                                        }
                                        return Container(
                                          height: 30.h,
                                          child: Row(
                                            children: [
                                              Container(
                                                alignment: Alignment.center,
                                                padding: EdgeInsets.symmetric(
                                                    horizontal: 4, vertical: 3),
                                                decoration: BoxDecoration(
                                                    color: Colors.white,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            5)),
                                                width: 35.w,
                                                height: 30.h,
                                                child: Text(
                                                  hours < 10
                                                      ? "0$hours"
                                                      : "$hours",
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(
                                                      color: primaryColor,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize:
                                                          responsiveFont(12)),
                                                ),
                                              ),
                                              Container(
                                                margin: EdgeInsets.symmetric(
                                                    horizontal: 5),
                                                child: Text(
                                                  ":",
                                                  style: TextStyle(
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      fontSize:
                                                          responsiveFont(12)),
                                                ),
                                              ),
                                              Container(
                                                alignment: Alignment.center,
                                                padding: EdgeInsets.all(3),
                                                decoration: BoxDecoration(
                                                    color: Colors.white,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            5)),
                                                width: 30.w,
                                                height: 30.h,
                                                child: Text(
                                                  time.min! < 10
                                                      ? "0${time.min}"
                                                      : "${time.min}",
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(
                                                      color: primaryColor,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize:
                                                          responsiveFont(12)),
                                                ),
                                              ),
                                              Container(
                                                margin: EdgeInsets.symmetric(
                                                    horizontal: 5),
                                                child: Text(
                                                  ":",
                                                  style: TextStyle(
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      fontSize:
                                                          responsiveFont(12)),
                                                ),
                                              ),
                                              Container(
                                                alignment: Alignment.center,
                                                padding: EdgeInsets.all(3),
                                                decoration: BoxDecoration(
                                                    color: Colors.white,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            5)),
                                                width: 30.w,
                                                height: 30.h,
                                                child: Text(
                                                  time.sec! < 10
                                                      ? "0${time.sec}"
                                                      : "${time.sec}",
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(
                                                      color: primaryColor,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize:
                                                          responsiveFont(12)),
                                                ),
                                              )
                                            ],
                                          ),
                                        );
                                      },
                                    ))
                              ],
                            ),
                          ),
                        ),
                        firstPart(productModel!, buildWishlistBtn),
                        Container(
                          margin: EdgeInsets.symmetric(vertical: 15),
                          width: double.infinity,
                          height: 5,
                          color: HexColor("EEEEEE"),
                        ),
                        secondPart(productModel!),
                        Container(
                          margin: EdgeInsets.symmetric(vertical: 15),
                          width: double.infinity,
                          height: 5,
                          color: HexColor("EEEEEE"),
                        ),
                        thirdPart(),
                        Container(
                          margin: EdgeInsets.symmetric(vertical: 15),
                          width: double.infinity,
                          height: 5,
                          color: HexColor("EEEEEE"),
                        ),
                        commentPart(),
                        Container(
                          margin: EdgeInsets.symmetric(vertical: 15),
                          width: double.infinity,
                          height: 5,
                          color: HexColor("EEEEEE"),
                        ),
                        sameCategoryProduct(),
                        SizedBox(
                          height: 15,
                        ),
                        featuredProduct(),
                        SizedBox(
                          height: 15,
                        ),
                        onSaleProduct(),
                        SizedBox(
                          height: 70.h,
                        ),
                      ],
                    ),
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
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Container(
                          width: 150.w,
                          height: 30.h,
                          child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                  side: BorderSide(
                                    color: productModel!.stockStatus !=
                                                'outofstock' &&
                                            productModel!.productStock! >= 1
                                        ? secondaryColor
                                        : Colors.grey, //Color of the border
                                    //Style of the border
                                  ),
                                  alignment: Alignment.center,
                                  shape: new RoundedRectangleBorder(
                                      borderRadius:
                                          new BorderRadius.circular(5))),
                              onPressed: () {
                                if (productModel!.stockStatus != 'outofstock' &&
                                    productModel!.productStock! >= 1) {
                                  showMaterialModalBottomSheet(
                                    context: context,
                                    builder: (context) => ModalSheetCart(
                                      product: productModel,
                                      type: 'add',
                                      loadCount: loadCartCount,
                                    ),
                                  );
                                } else {
                                  snackBar(context,
                                      message: AppLocalizations.of(context)!
                                          .translate('product_out_stock')!);
                                }
                              },
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.add,
                                    size: responsiveFont(9),
                                    color: productModel!.stockStatus !=
                                                'outofstock' &&
                                            productModel!.productStock! >= 1
                                        ? secondaryColor
                                        : Colors.grey,
                                  ),
                                  Text(
                                    AppLocalizations.of(context)!
                                        .translate('add_to_cart')!,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: responsiveFont(9),
                                      color: productModel!.stockStatus !=
                                                  'outofstock' &&
                                              productModel!.productStock! >= 1
                                          ? secondaryColor
                                          : Colors.grey,
                                    ),
                                  )
                                ],
                              )),
                        ),
                        Container(
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(5),
                              gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: productModel!.stockStatus !=
                                              'outofstock' &&
                                          productModel!.productStock! >= 1
                                      ? [primaryColor, secondaryColor]
                                      : [Colors.grey, Colors.grey])),
                          width: 132.w,
                          height: 30.h,
                          child: TextButton(
                            onPressed: () {
                              if (productModel!.stockStatus != 'outofstock' &&
                                  productModel!.productStock! >= 1) {
                                showMaterialModalBottomSheet(
                                  context: context,
                                  builder: (context) => ModalSheetCart(
                                    product: productModel,
                                    type: 'buy',
                                  ),
                                );
                              } else {
                                snackBar(context,
                                    message: AppLocalizations.of(context)!
                                        .translate('product_out_stock')!);
                              }
                            },
                            child: Text(
                              AppLocalizations.of(context)!
                                  .translate('buy_now')!,
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: responsiveFont(9)),
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget sameCategoryProduct() {
    final product = Provider.of<ProductProvider>(context, listen: false);

    return ListenableProvider.value(
        value: product,
        child: Consumer<ProductProvider>(builder: (context, value, child) {
          if (value.loadingCategory) {
            return AspectRatio(
              aspectRatio: 3 / 1.9,
              child: ListView.separated(
                itemCount: 4,
                scrollDirection: Axis.horizontal,
                itemBuilder: (context, i) {
                  return CardItemShimmer(
                    i: i,
                    itemCount: 4,
                  );
                },
                separatorBuilder: (BuildContext context, int index) {
                  return SizedBox(
                    width: 5,
                  );
                },
              ),
            );
          }
          return Visibility(
              visible: value.listCategoryProduct.isNotEmpty,
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    margin: EdgeInsets.only(left: 15, bottom: 10, right: 15),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          AppLocalizations.of(context)!
                              .translate('you_might_also')!,
                          style: TextStyle(
                              fontSize: responsiveFont(14),
                              fontWeight: FontWeight.w600),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => BrandProducts(
                                          categoryId: product
                                              .productDetail!.categories![0].id
                                              .toString(),
                                          brandName:
                                              AppLocalizations.of(context)!
                                                  .translate('you_might_also'),
                                        )));
                          },
                          child: Text(
                            AppLocalizations.of(context)!.translate('more')!,
                            style: TextStyle(
                                fontSize: responsiveFont(12),
                                fontWeight: FontWeight.w600,
                                color: secondaryColor),
                          ),
                        )
                      ],
                    ),
                  ),
                  AspectRatio(
                    aspectRatio: 3 / 2,
                    child: ListView.separated(
                      itemCount: value.listCategoryProduct.length,
                      scrollDirection: Axis.horizontal,
                      itemBuilder: (context, i) {
                        return CardItem(
                          product: value.listCategoryProduct[i],
                          i: i,
                          itemCount: value.listCategoryProduct.length,
                        );
                      },
                      separatorBuilder: (BuildContext context, int index) {
                        return SizedBox(
                          width: 5,
                        );
                      },
                    ),
                  )
                ],
              ));
        }));
  }

  Widget featuredProduct() {
    return Consumer<ProductProvider>(builder: (context, value, child) {
      if (value.loadingFeatured) {
        return customLoading();
      }
      return Visibility(
          visible: value.listFeaturedProduct.isNotEmpty,
          child: Column(
            children: [
              Container(
                width: double.infinity,
                margin: EdgeInsets.only(left: 15, bottom: 10, right: 15),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      AppLocalizations.of(context)!
                          .translate('featured_products')!,
                      style: TextStyle(
                          fontSize: responsiveFont(14),
                          fontWeight: FontWeight.w600),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => AllFeaturedProducts()));
                      },
                      child: Text(
                        AppLocalizations.of(context)!.translate('more')!,
                        style: TextStyle(
                            fontSize: responsiveFont(12),
                            fontWeight: FontWeight.w600,
                            color: secondaryColor),
                      ),
                    )
                  ],
                ),
              ),
              AspectRatio(
                aspectRatio: 3 / 2,
                child: ListView.separated(
                  itemCount: value.listFeaturedProduct.length,
                  scrollDirection: Axis.horizontal,
                  itemBuilder: (context, i) {
                    return CardItem(
                      product: value.listFeaturedProduct[i],
                      i: i,
                      itemCount: value.listFeaturedProduct.length,
                    );
                  },
                  separatorBuilder: (BuildContext context, int index) {
                    return SizedBox(
                      width: 5,
                    );
                  },
                ),
              )
            ],
          ));
    });
  }

  Widget onSaleProduct() {
    return Consumer<FlashSaleProvider>(builder: (context, value, child) {
      return Visibility(
          visible: value.flashSaleProducts.isNotEmpty,
          child: Column(
            children: [
              Container(
                width: double.infinity,
                margin: EdgeInsets.only(left: 15, bottom: 10, right: 15),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.translate('flashsale')!,
                      style: TextStyle(
                          fontSize: responsiveFont(14),
                          fontWeight: FontWeight.w600),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => ProductMoreScreen(
                                      include: value.flashSales[0].products,
                                      name: AppLocalizations.of(context)!
                                          .translate('flashsale')!,
                                    )));
                      },
                      child: Text(
                        AppLocalizations.of(context)!.translate('more')!,
                        style: TextStyle(
                            fontSize: responsiveFont(12),
                            fontWeight: FontWeight.w600,
                            color: secondaryColor),
                      ),
                    )
                  ],
                ),
              ),
              AspectRatio(
                aspectRatio: 3 / 1.9,
                child: ListView.separated(
                  itemCount: value.flashSaleProducts.length,
                  scrollDirection: Axis.horizontal,
                  itemBuilder: (context, i) {
                    return CardItem(
                      product: value.flashSaleProducts[i],
                      i: i,
                      itemCount: value.flashSaleProducts.length,
                    );
                  },
                  separatorBuilder: (BuildContext context, int index) {
                    return SizedBox(
                      width: 5,
                    );
                  },
                ),
              )
            ],
          ));
    });
  }

  Widget thirdPart() {
    final review = Provider.of<ReviewProvider>(context, listen: false);
    final product = Provider.of<ProductProvider>(context, listen: false);

    Widget buildReview = Container(
      child: ListenableProvider.value(
        value: review,
        child: Consumer<ReviewProvider>(builder: (context, value, child) {
          if (value.isLoadingReview) {
            return Container();
          }
          if (value.listReviewLimit.isEmpty) {
            return Text(
              AppLocalizations.of(context)!.translate('empty_review_product')!,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12),
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  RatingBarIndicator(
                    rating: double.parse(value.listReviewLimit[0].star!),
                    itemBuilder: (context, index) => Icon(
                      Icons.star,
                      color: Colors.amber,
                    ),
                    itemCount: 5,
                    itemSize: 15,
                    direction: Axis.horizontal,
                  ),
                  SizedBox(
                    width: 10,
                  ),
                  Text(
                    "by ",
                    style: TextStyle(
                        color: HexColor("929292"), fontSize: responsiveFont(9)),
                  ),
                  Text(
                    value.listReviewLimit[0].author!,
                    style: TextStyle(fontSize: responsiveFont(9)),
                  )
                ],
              ),
              SizedBox(
                height: 5,
              ),
              Text(
                value.listReviewLimit[0].content!,
                style: TextStyle(
                    color: HexColor("464646"),
                    fontWeight: FontWeight.w400,
                    fontSize: 10),
              ),
            ],
          );
        }),
      ),
    );

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)!.translate('review')!,
                    style: TextStyle(
                        fontSize: responsiveFont(10),
                        fontWeight: FontWeight.w500),
                  ),
                  Row(
                    children: [
                      Container(
                          width: 15.w,
                          height: 15.h,
                          child: Image.asset(
                              "images/product_detail/starGold.png")),
                      Text(
                        " ${product.productDetail!.avgRating} (${product.productDetail!.ratingCount} ${AppLocalizations.of(context)!.translate('review')})",
                        style: TextStyle(fontSize: responsiveFont(10)),
                      ),
                    ],
                  )
                ],
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => ProductReview(
                                productId: productModel!.id.toString(),
                              )));
                },
                child: Row(
                  children: [
                    Text(
                      AppLocalizations.of(context)!.translate('see_all')!,
                      style: TextStyle(fontSize: responsiveFont(11)),
                    ),
                    SizedBox(
                      width: 5,
                    ),
                    Icon(
                      Icons.keyboard_arrow_right,
                      size: responsiveFont(20),
                    )
                  ],
                ),
              )
            ],
          ),
          SizedBox(
            height: 10,
          ),
          SizedBox(
            height: 10,
          ),
          buildReview
        ],
      ),
    );
  }

  Widget commentPart() {
    final product = Provider.of<ProductProvider>(context, listen: false);

    Widget buildBtnReview = Container(
      child: ListenableProvider.value(
        value: product,
        child: Consumer<ProductProvider>(builder: (context, value, child) {
          if (value.loadAddReview) {
            return InkWell(
              onTap: null,
              child: Container(
                width: 80,
                height: 30,
                padding: EdgeInsets.symmetric(horizontal: 5, vertical: 3),
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(3), color: Colors.grey),
                alignment: Alignment.center,
                child: customLoading(),
              ),
            );
          }
          return InkWell(
            onTap: () async {
              if (rating != 0 && reviewController.text.isNotEmpty) {
                FocusScopeNode currentFocus = FocusScope.of(context);

                if (!currentFocus.hasPrimaryFocus) {
                  currentFocus.unfocus();
                }
                await Provider.of<ProductProvider>(context, listen: false)
                    .addReview(context,
                        productId: productModel!.id,
                        rating: rating,
                        review: reviewController.text)
                    .then((value) {
                  setState(() {
                    reviewController.clear();
                    rating = 0;
                  });
                  loadReviewProduct();
                });
              } else {
                snackBar(context,
                    message: 'You must set the rating and review first');
              }
            },
            child: Container(
              width: 80,
              height: 30,
              padding: EdgeInsets.symmetric(horizontal: 5, vertical: 3),
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(3),
                  color: rating != 0 && reviewController.text.isNotEmpty
                      ? secondaryColor
                      : Colors.grey),
              alignment: Alignment.center,
              child: Text(
                "Submit",
                style: TextStyle(
                    fontSize: responsiveFont(10),
                    fontWeight: FontWeight.w700,
                    color: Colors.white),
              ),
            ),
          );
        }),
      ),
    );

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.translate('add_review')!,
            style: TextStyle(
                fontSize: responsiveFont(12), fontWeight: FontWeight.w500),
          ),
          SizedBox(
            height: 10,
          ),
          Text(
            AppLocalizations.of(context)!.translate('comment')!,
            style: TextStyle(
                fontSize: responsiveFont(10), fontWeight: FontWeight.w400),
          ),
          SizedBox(
            height: 5,
          ),
          TextField(
            controller: reviewController,
            maxLines: 2,
            style: TextStyle(
              fontSize: 10,
            ),
            onChanged: (value) {
              setState(() {});
            },
            decoration: InputDecoration(
              border: OutlineInputBorder(
                  borderSide: new BorderSide(color: Colors.teal)),
              hintText: AppLocalizations.of(context)!.translate('hint_review'),
              hintStyle: TextStyle(fontSize: 10, color: HexColor('9e9e9e')),
            ),
            textInputAction: TextInputAction.done,
          ),
          SizedBox(
            height: 10,
          ),
          RatingBar.builder(
            initialRating: rating,
            minRating: 1,
            direction: Axis.horizontal,
            allowHalfRating: false,
            itemCount: 5,
            itemSize: 25,
            itemBuilder: (context, _) => Icon(
              Icons.star,
              color: Colors.amber,
            ),
            onRatingUpdate: (value) {
              print(value);
              setState(() {
                rating = value;
              });
            },
          ),
          SizedBox(
            height: 10,
          ),
          buildBtnReview
        ],
      ),
    );
  }

  Widget secondPart(ProductModel model) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.translate('description')!,
            style: TextStyle(
                fontSize: responsiveFont(12), fontWeight: FontWeight.w500),
          ),
          SizedBox(
            height: 5,
          ),
          HtmlWidget(
            model.productDescription!,
            textStyle: TextStyle(color: HexColor("929292")),
          ),
        ],
      ),
    );
  }

  Widget firstPart(ProductModel model, Widget btnFav) {
    return Container(
      margin: EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              productModel!.type == 'simple'
                  ? RichText(
                      text: TextSpan(
                        style: TextStyle(color: Colors.black),
                        children: <TextSpan>[
                          TextSpan(
                              text: stringToCurrency(
                                  double.parse(productModel!.productPrice),
                                  context),
                              style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: responsiveFont(15),
                                  color: Colors.black)),
                        ],
                      ),
                    )
                  : RichText(
                      text: TextSpan(
                        style: TextStyle(color: Colors.black),
                        children: <TextSpan>[
                          variantPrices.isEmpty
                              ? TextSpan(
                                  text: '',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: responsiveFont(11),
                                      color: secondaryColor))
                              : TextSpan(
                                  text: variantPrices.first ==
                                          variantPrices.last
                                      ? '${stringToCurrency(variantPrices.first, context)}'
                                      : '${stringToCurrency(variantPrices.first, context)} - ${stringToCurrency(variantPrices.last, context)}',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: responsiveFont(15),
                                      color: Colors.black)),
                        ],
                      ),
                    ),
              btnFav
            ],
          ),
          SizedBox(
            height: 5,
          ),
          Visibility(
            visible: model.discProduct != 0,
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 5, vertical: 3),
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(3),
                      color: secondaryColor),
                  child: Row(
                    children: [
                      Text(
                        AppLocalizations.of(context)!
                            .translate('save_product')!,
                        style: TextStyle(
                            fontSize: responsiveFont(8),
                            fontWeight: FontWeight.w600,
                            color: Colors.white),
                      ),
                      SizedBox(
                        width: 3,
                      ),
                      Text(
                        "${model.discProduct!.round()}%",
                        style: TextStyle(
                            fontSize: responsiveFont(8), color: Colors.white),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 5,
                ),
                RichText(
                  text: TextSpan(
                    style: TextStyle(color: Colors.black),
                    children: <TextSpan>[
                      TextSpan(
                          text: stringToCurrency(
                              double.parse(productModel!.productRegPrice),
                              context),
                          style: TextStyle(
                              decoration: TextDecoration.lineThrough,
                              fontSize: responsiveFont(12),
                              color: HexColor("C4C4C4"))),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 5,
          ),
          Text(
            model.productName!,
            style: TextStyle(fontSize: responsiveFont(11)),
          ),
          SizedBox(
            height: 10,
          ),
          Row(
            children: [
              Row(
                children: [
                  Text(
                    "${AppLocalizations.of(context)!.translate('sold')} ",
                    style: TextStyle(
                        fontSize: responsiveFont(10),
                        fontWeight: FontWeight.w500),
                  ),
                  Text(
                    "${model.totalSales}",
                    style: TextStyle(fontSize: responsiveFont(10)),
                  )
                ],
              ),
              Container(
                margin: EdgeInsets.symmetric(horizontal: 10),
                height: 11,
                width: 1,
                color: Colors.black,
              ),
              Container(
                  width: 15.w,
                  height: 15.h,
                  child: Image.asset("images/product_detail/starGold.png")),
              Text(
                " ${model.avgRating} (${model.ratingCount})",
                style: TextStyle(fontSize: responsiveFont(10)),
              ),
            ],
          ),
          SizedBox(
            height: 10,
          ),
          Text(
            model.stockStatus == 'instock'
                ? '${AppLocalizations.of(context)!.translate('available')}'
                : '${AppLocalizations.of(context)!.translate('out_stock')}',
            style: TextStyle(
                fontSize: responsiveFont(11),
                fontWeight: FontWeight.bold,
                color:
                    model.stockStatus == 'instock' ? Colors.green : Colors.red),
          ),
          SizedBox(
            height: 10,
          ),
          HtmlWidget(
            model.productShortDesc!,
            textStyle: TextStyle(
                color: HexColor("929292"), fontSize: responsiveFont(10)),
          ),
        ],
      ),
    );
  }

  Widget appBar(ProductModel model) {
    return AppBar(
      backgroundColor: Colors.white,
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: Icon(
          Icons.arrow_back,
          color: Colors.black,
        ),
      ),
      title: Text(
        model.productName ?? "",
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: responsiveFont(14)),
      ),
      actions: [
        InkWell(
          onTap: () {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => CartScreen(
                          isFromHome: false,
                        )));
          },
          child: Container(
            width: 65,
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  Icons.shopping_cart,
                  color: Colors.black,
                ),
                Positioned(
                  right: 0,
                  top: 7,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                        shape: BoxShape.circle, color: primaryColor),
                    alignment: Alignment.center,
                    child: Text(
                      cartCount.toString(),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: responsiveFont(9),
                      ),
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
        InkWell(
          onTap: () {
            shareLinks('product', model.link);
          },
          child: Container(
            margin: EdgeInsets.only(right: 15),
            child: Icon(
              Icons.share,
              color: Colors.black,
            ),
          ),
        )
      ],
    );
  }

  Widget itemList(
      String title, String discount, String price, String crossedPrice, int i) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
            context, MaterialPageRoute(builder: (context) => ProductDetail()));
      },
      child: Container(
        margin: EdgeInsets.only(
            left: i == 0 ? 15 : 0, right: i == itemCount - 1 ? 15 : 0),
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(5)),
        width: MediaQuery.of(context).size.width / 3,
        height: double.infinity,
        child: Card(
          elevation: 5,
          margin: EdgeInsets.only(bottom: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 4,
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.only(
                        topRight: Radius.circular(5),
                        topLeft: Radius.circular(5)),
                    color: primaryColor,
                  ),
                  child: Image.asset("images/lobby/laptop.png"),
                ),
              ),
              Expanded(
                  flex: 3,
                  child: Container(
                    margin: EdgeInsets.symmetric(vertical: 3, horizontal: 5),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Flexible(
                          flex: 3,
                          child: Text(
                            title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: responsiveFont(10)),
                          ),
                        ),
                        Container(
                          height: 5,
                        ),
                        Flexible(
                          flex: 1,
                          child: Container(
                            child: Text(
                              price,
                              style: TextStyle(
                                  fontSize: responsiveFont(10),
                                  color: secondaryColor,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                        Container(
                          height: 5,
                        ),
                      ],
                    ),
                  )),
            ],
          ),
        ),
      ),
    );
  }
}
