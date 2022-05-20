import 'package:flutter/foundation.dart';
import 'package:nyoba/models/categories_model.dart';
import 'package:nyoba/models/product_model.dart';
import 'package:nyoba/models/variation_model.dart';
import 'dart:convert';
import 'package:nyoba/services/categories_api.dart';
import 'package:nyoba/services/product_api.dart';
import 'package:nyoba/utils/utility.dart';

class CategoryProvider with ChangeNotifier {
  CategoriesModel? category;
  bool loading = true;
  bool loadingAll = true;

  bool loadingSub = false;

  List<CategoriesModel> categories = [];
  List<ProductCategoryModel> productCategories = [];

  List<AllCategoriesModel> allCategories = [];
  List<ProductCategoryModel> subCategories = [];
  List<PopularCategoriesModel> popularCategories = [];
  int? currentSelectedCategory;
  int? currentSelectedCountSub;
  int? currentPage;

  List<ProductModel> listProductCategory = [];
  List<ProductModel> listTempProduct = [];

  CategoryProvider() {
    // fetchCategories();
    // fetchProductCategories();
  }

  Future<bool> fetchCategories() async {
    await CategoriesAPI().fetchCategories().then((data) {
      if (data.statusCode == 200) {
        final responseJson = json.decode(data.body);

        for (Map item in responseJson) {
          categories.add(CategoriesModel.fromJson(item));
        }
        categories.add(new CategoriesModel(
            image: 'images/lobby/viewMore.png',
            categories: null,
            id: null,
            titleCategories: 'View More'));
        loading = false;
        notifyListeners();
      } else {
        loading = false;
        notifyListeners();
      }
    });
    return true;
  }

  Future<bool> fetchProductCategories() async {
    await CategoriesAPI().fetchProductCategories().then((data) {
      if (data.statusCode == 200) {
        final responseJson = json.decode(data.body);

        for (Map item in responseJson) {
          productCategories.add(ProductCategoryModel.fromJson(item));
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

  Future<bool> fetchAllCategories() async {
    var result;
    await CategoriesAPI().fetchAllCategories().then((data) {
      result = data;
      printLog(result.toString());
      for (Map item in result) {
        allCategories.add(AllCategoriesModel.fromJson(item));
      }
      loadingAll = false;
      notifyListeners();
    });
    return true;
  }

  Future<bool> fetchSubCategories(int? parent, page) async {
    loadingSub = true;
    await CategoriesAPI()
        .fetchProductCategories(parent: parent, page: page)
        .then((data) {
      if (data.statusCode == 200) {
        final responseJson = json.decode(data.body);

        if (page == 1) {
          subCategories.clear();
        }

        for (Map item in responseJson) {
          subCategories.add(ProductCategoryModel.fromJson(item));
        }
        loadingSub = false;
        notifyListeners();
      } else {
        loadingSub = false;
        notifyListeners();
      }
    });
    return true;
  }

  Future<bool> fetchPopularCategories() async {
    loadingSub = true;
    await CategoriesAPI().fetchPopularCategories().then((data) {
      if (data.statusCode == 200) {
        final responseJson = json.decode(data.body);

        popularCategories.clear();
        for (Map item in responseJson) {
          popularCategories.add(PopularCategoriesModel.fromJson(item));
        }
        loadingSub = false;
        notifyListeners();
      } else {
        loadingSub = false;
        notifyListeners();
      }
    });
    return true;
  }

  Future<bool> fetchProductsCategory(String category, {int page = 1}) async {
    loadingSub = true;
    await ProductAPI()
        .fetchProduct(category: category, page: page, perPage: 5)
        .then((data) {
      if (data.statusCode == 200) {
        final responseJson = json.decode(data.body);

        listTempProduct.clear();
        if (page == 1) {
          listProductCategory.clear();
        }

        int count = 0;

        for (Map item in responseJson) {
          listTempProduct.add(ProductModel.fromJson(item));
          count++;
        }

        if (count >= 5) {
          listTempProduct.add(ProductModel());
        }

        loadVariationData(load: loadingSub, listProduct: listTempProduct)
            .then((value) {
          listTempProduct.forEach((element) {
            listProductCategory.add(element);
          });
          loadingSub = false;
          notifyListeners();
        });
      } else {
        loadingSub = false;
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
