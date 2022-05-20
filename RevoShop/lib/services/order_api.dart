import 'package:nyoba/constant/constants.dart';
import 'package:nyoba/constant/global_url.dart';
import 'package:nyoba/services/session.dart';
import 'package:nyoba/utils/utility.dart';

class OrderAPI {
  checkoutOrder(order) async {
    var response = await baseAPI.getAsync(
        '$orderApi?order=$order', isOrder: true);
    return response;
  }

  listMyOrder(String? status, String? search, String? orderId, int? page) async {
    Map data = {
      "cookie": Session.data.getString('cookie'),
      "status" : status,
      "search" : search,
      "page": page,
      if (orderId != null)
        "order_id": orderId
    };
    printLog(data.toString());
    var response = await baseAPI.postAsync(
      '$listOrders',
      data,
      isCustom: true,
    );
    return response;
  }

  detailOrder(String? orderId) async {
    Map data = {
      "cookie": Session.data.getString('cookie'),
      "order_id": orderId
    };
    printLog(data.toString());
    var response = await baseAPI.postAsync(
      '$listOrders',
      data,
      isCustom: true,
    );
    return response;
  }
}
