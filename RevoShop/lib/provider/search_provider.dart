import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:nyoba/models/product_model.dart';
import 'package:nyoba/models/variation_model.dart';
import 'package:nyoba/pages/product/product_detail_screen.dart';
import 'package:nyoba/services/product_api.dart';
import 'package:nyoba/utils/utility.dart';

class SearchProvider with ChangeNotifier {
  bool loadingSearch = false;
  bool loadingQr = false;

  String? message;

  List<ProductModel> listSearchProducts = [];
  List<ProductModel> listTempProducts = [];

  String? productWishlist;

  Future<bool> searchProducts(String search, int page) async {
    loadingSearch = true;
    await ProductAPI().searchProduct(search: search, page: page).then((data) {
      if (data.statusCode == 200) {
        final responseJson = json.decode(data.body);

        printLog(responseJson.toString(), name: 'Wishlist');
        listTempProducts.clear();
        if (page == 1) listSearchProducts.clear();
        if (search.isNotEmpty) {
          for (Map item in responseJson) {
            listTempProducts.add(ProductModel.fromJson(item));
          }
        }

        loadVariationData(load: loadingSearch, listProduct: listTempProducts)
            .then((value) {
          listTempProducts.forEach((element) {
            listSearchProducts.add(element);
          });
          loadingSearch = false;
          notifyListeners();
        });
      } else {
        print("Load Failed");
        loadingSearch = false;
        notifyListeners();
      }
    });
    return true;
  }

  Future<bool> scanProduct(String? code, context) async {
    loadingQr = true;
    await ProductAPI().scanProductAPI(code).then((data) {
      if (data['id'] != null) {
        loadingQr = false;
        Navigator.pop(context);
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => ProductDetail(
                      productId: data['id'].toString(),
                    )));
      } else if (data['status'] == 'error') {
        loadingQr = false;
        Navigator.pop(context);
        snackBar(context, message: "Product not found", color: Colors.red);
      }
      loadingQr = false;
      notifyListeners();
    });
    return true;
  }

  Future<bool?> loadVariationData(
      {required List<ProductModel> listProduct, bool? load}) async {
    listProduct.forEach((element) async {
      if (element.type == 'variable') {
        List<VariationModel> variations = [];
        notifyListeners();
        load = true;
        await ProductAPI()
            .productVariations(productId: element.id.toString())
            .then((value) {
          if (value.statusCode == 200) {
            final variation = json.decode(value.body);

            for (Map item in variation) {
              if (item['price'].isNotEmpty) {
                variations.add(VariationModel.fromJson(item));
              }
            }

            variations.forEach((v) {
              /*printLog('${element.productName} ${v.id} ${v.price}',
                  name: 'Price Variation 2');*/
              element.variationPrices!.add(double.parse(v.price!));
            });

            element.variationPrices!.sort((a, b) => a!.compareTo(b!));
          }
          load = false;
          notifyListeners();
        });
      } else {
        load = false;
        notifyListeners();
      }
    });
    return load;
  }
}
