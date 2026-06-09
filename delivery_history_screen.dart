import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/order_model.dart';
import '../../services/order_service.dart';

class DeliveryHistoryScreen extends StatefulWidget {
  const DeliveryHistoryScreen({super.key});

  @override
  State<DeliveryHistoryScreen> createState() => _DeliveryHistoryScreenState();
}

class _DeliveryHistoryScreenState extends State<DeliveryHistoryScreen> {
  final OrderService _orderService = OrderService();
  
  // Key used to force a rebuild of the StreamBuilder if needed
  Key _refreshKey = UniqueKey();

  Future<void> _handleRefresh() async {
    setState(() {
      _refreshKey = UniqueKey();
    });
    // Small delay to show the animation
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text("My Orders"),
        backgroundColor: const Color(0xFF03A9F4),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: user == null
          ? const Center(child: Text("Please login to view history"))
          : RefreshIndicator(
              onRefresh: _handleRefresh,
              child: StreamBuilder<List<OrderModel>>(
                key: _refreshKey,
                stream: _orderService.getCustomerOrders(user.uid),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return ListView( // Needs to be a scrollable view for RefreshIndicator to work
                      children: [
                        SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Text(
                              "Error: ${snapshot.error}\n\nTip: If you see an index error, click the link in your console.",
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                        ),
                      ],
                    );
                  }

                  final orders = snapshot.data ?? [];

                  if (orders.isEmpty) {
                    return ListView(
                      children: [
                        SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.history, size: 80, color: Colors.grey[400]),
                              const SizedBox(height: 10),
                              const Text("No orders found", style: TextStyle(color: Colors.grey, fontSize: 18)),
                            ],
                          ),
                        ),
                      ],
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: orders.length,
                    itemBuilder: (context, index) {
                      final order = orders[index];
                      return _orderCard(context, order);
                    },
                  );
                },
              ),
            ),
    );
  }

  Widget _orderCard(BuildContext context, OrderModel order) {
    IconData icon;
    Color color;
    String title;
    String subtitle;

    switch (order.type) {
      case 'pabili':
        icon = Icons.shopping_bag;
        color = Colors.orange;
        title = "Pabili: ${order.storeName ?? 'Store'}";
        subtitle = order.items?.join(', ') ?? 'No items';
        break;
      case 'food':
        icon = Icons.fastfood;
        color = Colors.green;
        title = "Food: ${order.storeName ?? 'Restaurant'}";
        subtitle = order.items?.join(', ') ?? 'No items';
        break;
      case 'bills':
        icon = Icons.receipt_long;
        color = Colors.blue;
        title = "Bill: ${order.billerName ?? 'Biller'}";
        subtitle = "Amount: ₱${order.amount?.toStringAsFixed(2) ?? '0.00'}";
        break;
      default:
        icon = Icons.local_shipping;
        color = const Color(0xFF003366);
        title = "Pick Up Delivery";
        subtitle = order.packageDescription ?? 'Package';
    }

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(15),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 5),
            Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 5),
            Row(
              children: [
                _statusChip(order.status),
                const Spacer(),
                Text(
                  "${order.createdAt.month}/${order.createdAt.day}/${order.createdAt.year}",
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
        onTap: () => _showOrderDetails(context, order),
      ),
    );
  }

  Widget _statusChip(String status) {
    Color color;
    switch (status) {
      case 'pending': color = Colors.amber; break;
      case 'accepted':
      case 'on the way': color = Colors.orange; break;
      case 'delivered': color = Colors.green; break;
      case 'cancelled': color = Colors.red; break;
      default: color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 10),
      ),
    );
  }

  void _showOrderDetails(BuildContext context, OrderModel order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          padding: const EdgeInsets.all(25),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 50,
                    height: 5,
                    decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 25),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(order.type.toUpperCase(), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF03A9F4))),
                    _statusChip(order.status),
                  ],
                ),
                const Divider(height: 30),
                
                if (order.type == 'bills') ...[
                  _detailRow("Biller", order.billerName),
                  _detailRow("Account Name", order.accountName),
                  _detailRow("Account Number", order.accountNumber),
                ] else if (order.type == 'pabili' || order.type == 'food') ...[
                  _detailRow(order.type == 'pabili' ? "Store" : "Restaurant", order.storeName),
                  _detailRow("Drop-off", order.dropoffLocation),
                ] else ...[
                  _detailRow("Pickup", order.pickupLocation),
                  _detailRow("Drop-off", order.dropoffLocation),
                  _detailRow("Package", order.packageDescription),
                ],

                const SizedBox(height: 10),
                const Text("Payment Summary", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 10),
                
                if (order.type == 'pabili' || order.type == 'food') ...[
                  if (order.items != null) ...[
                    ...List.generate(order.items!.length, (index) {
                      final item = order.items![index];
                      final price = (order.itemPrices != null && order.itemPrices!.length > index)
                          ? order.itemPrices![index]
                          : 0.0;
                      return _priceRow(item, price);
                    }),
                    const Divider(),
                    _priceRow("Items Subtotal", order.amount ?? 0.0, isBold: true),
                  ],
                ] else if (order.type == 'bills') ...[
                  _priceRow("Bill Amount", order.amount ?? 0.0, isBold: true),
                ],

                _priceRow("Delivery Fee", order.deliveryFee ?? 0.0),
                _priceRow("Service Fee", order.serviceFee ?? 0.0),
                const Divider(),
                _priceRow("TOTAL PAID", order.totalToPay, isBold: true, isPrimary: true),
                
                const SizedBox(height: 20),
                Text("Order Date: ${order.createdAt.toString().split('.')[0]}", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF03A9F4),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                    child: const Text("Close", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _detailRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 120, child: Text(label, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w500))),
          Expanded(child: Text(value ?? 'N/A', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
        ],
      ),
    );
  }

  Widget _priceRow(String label, double amount, {bool isBold = false, bool isPrimary = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(
            color: isBold ? Colors.black87 : Colors.grey[700],
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            fontSize: isBold ? 14 : 13,
          )),
          Text("₱${amount.toStringAsFixed(2)}", style: TextStyle(
            color: isPrimary ? const Color(0xFF03A9F4) : Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: isBold ? 16 : 14,
          )),
        ],
      ),
    );
  }
}
