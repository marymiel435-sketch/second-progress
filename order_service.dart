import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/order_model.dart';
import '../models/notification_model.dart';
import 'notification_service.dart';

class OrderService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService();

  // GET CUSTOMER ORDERS
  Stream<List<OrderModel>> getCustomerOrders(String customerId) {
    return _db
        .collection('orders')
        .where('customerId', isEqualTo: customerId)
        .snapshots()
        .map((snapshot) {
          final orders = snapshot.docs.map((doc) => OrderModel.fromMap(doc.data(), doc.id)).toList();
          orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return orders;
        });
  }

  // UPDATE ORDER STATUS (TRAPPABLE BY CUSTOMER)
  Future<void> updateOrderStatus(String orderId, String status, {String? riderId}) async {
    try {
      print("NOTIF_DEBUG: Rider is updating status to $status for order $orderId");
      
      final orderDoc = await _db.collection('orders').doc(orderId).get();
      if (!orderDoc.exists) {
        print("NOTIF_DEBUG: Order $orderId does not exist");
        return;
      }
      
      final Map<String, dynamic> orderData = orderDoc.data() as Map<String, dynamic>;
      final String customerId = orderData['customerId']?.toString() ?? "";
      
      if (customerId.isEmpty) {
        print("NOTIF_DEBUG: No customerId found for order $orderId");
        return;
      }

      // Update Order Status in Firestore
      Map<String, dynamic> updateData = {'status': status};
      if (riderId != null) updateData['riderId'] = riderId;
      await _db.collection('orders').doc(orderId).update(updateData);

      // Create Notification Content
      String title = "Order Update";
      String body = "Your order status is now: $status";
      
      if (status == 'accepted') {
        title = "Order Accepted ✅";
        body = "A rider has accepted your request and is starting the task.";
      } else if (status == 'on the way') {
        title = "Rider is On the Way 🛵";
        body = "Your rider is now heading to your location.";
      } else if (status == 'delivered') {
        title = "Order Delivered 🎉";
        body = "Your order has been successfully completed. Thank you!";
      }

      // Save to Notifications collection
      await _notificationService.createNotification(NotificationModel(
        userId: customerId,
        title: title,
        body: body,
        createdAt: DateTime.now(),
        type: status,
        orderId: orderId,
      ));
      
      print("NOTIF_DEBUG: Notification sent to customer: $customerId");
    } catch (e) {
      print("NOTIF_DEBUG: Error in updateOrderStatus: $e");
      rethrow;
    }
  }

  // UPDATE ITEM PRICES INDIVIDUALLY
  Future<void> updateItemPrices(String orderId, List<double> prices) async {
    try {
      final orderDoc = await _db.collection('orders').doc(orderId).get();
      if (!orderDoc.exists) return;
      
      final data = orderDoc.data() as Map<String, dynamic>;
      final String customerId = data['customerId']?.toString() ?? "";
      if (customerId.isEmpty) return;

      // Calculate total amount from items
      double totalItemsAmount = prices.fold(0, (sum, price) => sum + price);

      await _db.collection('orders').doc(orderId).update({
        'itemPrices': prices,
        'amount': totalItemsAmount, // We use 'amount' as the total items cost
      });

      await _notificationService.createNotification(NotificationModel(
        userId: customerId,
        title: "Order Prices Updated ₱",
        body: "The rider has updated the prices for your items. Total: ₱${totalItemsAmount.toStringAsFixed(2)}",
        createdAt: DateTime.now(),
        type: 'price_updated',
        orderId: orderId,
      ));
      
      print("NOTIF_DEBUG: Price notification sent to customer: $customerId");
    } catch (e) {
      print("NOTIF_DEBUG: Error in updateItemPrices: $e");
      rethrow;
    }
  }

  // UPDATE ITEM PRICE (Backward compatibility/Fallback)
  Future<void> updateItemPrice(String orderId, double price) async {
    try {
      final orderDoc = await _db.collection('orders').doc(orderId).get();
      if (!orderDoc.exists) return;
      
      final String customerId = (orderDoc.data() as Map<String, dynamic>)['customerId']?.toString() ?? "";
      if (customerId.isEmpty) return;

      await _db.collection('orders').doc(orderId).update({'amount': price});

      await _notificationService.createNotification(NotificationModel(
        userId: customerId,
        title: "Total Price Updated ₱",
        body: "The rider has updated the item price to ₱${price.toStringAsFixed(2)}",
        createdAt: DateTime.now(),
        type: 'price_updated',
        orderId: orderId,
      ));
    } catch (e) {
      rethrow;
    }
  }

  // UPDATE RIDER LOCATION INFO
  Future<void> updateRiderLocation(String orderId, String locationName, {double? lat, double? lng}) async {
    try {
      Map<String, dynamic> data = {'currentLocationName': locationName};
      if (lat != null) data['riderLatitude'] = lat;
      if (lng != null) data['riderLongitude'] = lng;
      
      await _db.collection('orders').doc(orderId).update(data);
    } catch (e) {
      rethrow;
    }
  }

  // Basic Order Methods
  Future<void> createOrder(OrderModel order) async {
    Map<String, dynamic> data = order.toMap();
    data['createdAt'] = FieldValue.serverTimestamp();
    await _db.collection('orders').add(data);
  }

  Stream<List<OrderModel>> getAvailableOrders() {
    return _db.collection('orders')
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((s) => s.docs.map((d) => OrderModel.fromMap(d.data(), d.id)).toList()..sort((a,b) => b.createdAt.compareTo(a.createdAt)));
  }

  Stream<List<OrderModel>> getRiderActiveOrders(String riderId) {
    return _db.collection('orders')
        .where('riderId', isEqualTo: riderId)
        .snapshots()
        .map((s) => s.docs.map((d) => OrderModel.fromMap(d.data(), d.id))
            .where((o) => ['accepted', 'on the way', 'arrived'].contains(o.status)).toList());
  }

  Stream<List<OrderModel>> getRiderCompletedOrders(String riderId) {
    return _db.collection('orders')
        .where('riderId', isEqualTo: riderId)
        .where('status', isEqualTo: 'delivered')
        .snapshots()
        .map((s) => s.docs.map((d) => OrderModel.fromMap(d.data(), d.id)).toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt)));
  }

  Stream<OrderModel?> getOrderStream(String orderId) {
    return _db.collection('orders').doc(orderId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return OrderModel.fromMap(doc.data()!, doc.id);
    });
  }
}
