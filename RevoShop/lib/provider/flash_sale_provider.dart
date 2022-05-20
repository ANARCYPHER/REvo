import 'package:flutter/foundation.dart';
import 'package:nyoba/models/product_model.dart';
import 'package:nyoba/models/variation_model.dart';
import 'dart:convert';
import 'package:nyoba/services/flash_sale_api.dart';
import 'package:nyoba/models/flash_sale_model.dart';

import 'package:nyoba/services/product_api.dart';

class FlashSaleProvider with ChangeNotifier {
  FlashSaleModel? flashSale;
  bool loading = true;
  List<FlashSaleModel> flashSales = [];
  List<ProductModel> flashSaleProducts = [];

  FlashSaleProvider() {
    fetchFlashSale();
  }

  Future<bool> fetchFlashSale() async {
    loading = true;
    await FlashSaleAPI().fetchHomeFlashSale().then((data) async {
      if (data.statusCode == 200) {
        final responseJson = json.decode(data.body);

        for (Map item in responseJson) {
          flashSales.add(FlashSaleModel.fromJson(item));
        }
        loading = false;
        notifyListeners();
      } else {
        loading = false;
        notifyListeners();
      }
    });
    return true;
  }

  Future<bool?> loadVariationData(
      {required List<ProductModel> listProduct, bool? load}) async {
    listProduct.forEach((element) async {
      if (element.type == 'variable') {
        List<VariationModel> variations = [];
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
