import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/order_model.dart';
import '../../services/order_service.dart';

class MyDeliveriesScreen extends StatefulWidget {
  final bool isOnline; 
  const MyDeliveriesScreen({super.key, this.isOnline = true});

  @override
  State<MyDeliveriesScreen> createState() => _MyDeliveriesScreenState();
}

class _MyDeliveriesScreenState extends State<MyDeliveriesScreen> {
  final OrderService _orderService = OrderService();
  final String? _riderId = FirebaseAuth.instance.currentUser?.uid;

  static const Color primaryColor = Color(0xFF03A9F4);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Deliveries"),
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          bottom: const TabBar(
            tabs: [
              Tab(text: "Available"),
              Tab(text: "My Tasks"),
            ],
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
          ),
        ),
        body: TabBarView(
          children: [
            _buildAvailableOrders(),
            _buildMyTasks(),
          ],
        ),
      ),
    );
  }

  Widget _buildAvailableOrders() {
    if (!widget.isOnline) {
      return _buildOfflinePlaceholder("You are currently OFFLINE.\nConnect to internet to see available orders.");
    }

    return StreamBuilder<List<OrderModel>>(
      stream: _orderService.getAvailableOrders(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return _buildErrorState(snapshot.error.toString());
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final orders = snapshot.data ?? [];
        if (orders.isEmpty) {
          return const Center(child: Text("No available orders nearby."));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(15),
          itemCount: orders.length,
          itemBuilder: (context, index) {
            final order = orders[index];
            return _buildOrderCard(order, isAvailable: true);
          },
        );
      },
    );
  }

  Widget _buildMyTasks() {
    if (_riderId == null) return const Center(child: Text("Please login."));

    return StreamBuilder<List<OrderModel>>(
      stream: _orderService.getRiderActiveOrders(_riderId!),
      builder: (context, snapshot) {
        if (snapshot.hasError) return _buildErrorState(snapshot.error.toString());
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final orders = snapshot.data ?? [];
        if (orders.isEmpty) {
          return const Center(child: Text("You have no active tasks."));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(15),
          itemCount: orders.length,
          itemBuilder: (context, index) {
            final order = orders[index];
            return _buildOrderCard(order, isAvailable: false);
          },
        );
      },
    );
  }

  Widget _buildOfflinePlaceholder(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.wifi_off_rounded, size: 80, color: Colors.red.withValues(alpha: 0.3)),
          const SizedBox(height: 20),
          Text(
            message, 
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey, fontSize: 16, fontWeight: FontWeight.w500)
          ),
          const SizedBox(height: 10),
          const Text("Turn on Wi-Fi or Mobile Data", style: TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 40),
            const SizedBox(height: 10),
            Text("Something went wrong:\n$error", textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderCard(OrderModel order, {required bool isAvailable}) {
    final bool isPabili = order.type == 'pabili';
    final bool isFood = order.type == 'food';

    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: (isPabili || isFood) 
                        ? Colors.green.withValues(alpha: 0.1) 
                        : primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(order.type.toUpperCase(), style: TextStyle(color: (isPabili || isFood) ? Colors.green : primaryColor, fontWeight: FontWeight.bold, fontSize: 12)),
                ),
                Text(order.status.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 10),
            if (isPabili || isFood) ...[
              Text("Store: ${order.storeName ?? 'N/A'}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 5),
              Text("Items: ${order.items?.join(', ') ?? 'No items listed'}", style: const TextStyle(color: Colors.grey, fontSize: 13)),
            ] else ...[
              Text("Pickup: ${order.pickupLocation ?? 'N/A'}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 5),
              Text("Package: ${order.packageDescription ?? 'N/A'}", style: const TextStyle(color: Colors.grey)),
            ],
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 16, color: Colors.red),
                const SizedBox(width: 5),
                Expanded(child: Text("Drop-off: ${order.dropoffLocation}", style: const TextStyle(fontSize: 14))),
              ],
            ),
            if (!isAvailable && (isPabili || isFood)) ...[
              const SizedBox(height: 10),
              const Divider(),
              const Text("Price Breakdown:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              const SizedBox(height: 5),
              _priceRow("Items Subtotal", order.amount ?? 0),
              _priceRow("Delivery Fee", order.deliveryFee ?? 0),
              _priceRow("Service Fee", order.serviceFee ?? 0),
              const Divider(),
              _priceRow("TOTAL TO COLLECT", order.totalToPay, isTotal: true),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: () => _showUpdateItemsPriceDialog(order), 
                  icon: const Icon(Icons.edit, size: 16), 
                  label: const Text("Edit Item Prices"),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.green,
                    backgroundColor: Colors.green.withValues(alpha: 0.05),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 15),
            if (isAvailable)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: widget.isOnline ? () => _handleOrderUpdate(order, true) : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    disabledBackgroundColor: Colors.grey.shade300,
                  ),
                  child: Text(widget.isOnline ? "Accept Order" : "Rider is Offline"),
                ),
              )
            else
              Column(
                children: [
                  if (isPabili || isFood)
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _showUpdateLocationDialog(order),
                        icon: const Icon(Icons.edit_location_alt, size: 16),
                        label: const Text("Update Current Location"),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: primaryColor,
                          side: const BorderSide(color: primaryColor),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _handleOrderUpdate(order, false),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(_getNextStatusLabel(order.status)),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _priceRow(String label, double amount, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(
            fontSize: isTotal ? 14 : 12, 
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            color: isTotal ? Colors.black : Colors.grey[700]
          )),
          Text("₱${amount.toStringAsFixed(2)}", style: TextStyle(
            fontSize: isTotal ? 16 : 13, 
            fontWeight: FontWeight.bold,
            color: isTotal ? primaryColor : Colors.black87
          )),
        ],
      ),
    );
  }

  void _showUpdateItemsPriceDialog(OrderModel order) {
    final items = order.items ?? [];
    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("No items to price.")));
      return;
    }

    final List<TextEditingController> controllers = List.generate(
      items.length, 
      (index) => TextEditingController(
        text: (order.itemPrices != null && order.itemPrices!.length > index) 
            ? order.itemPrices![index].toStringAsFixed(2) 
            : ""
      )
    );

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          double calculateTotal() {
            double total = 0;
            for (var controller in controllers) {
              total += double.tryParse(controller.text) ?? 0;
            }
            return total;
          }

          return AlertDialog(
            title: const Text("Enter Item Prices"),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: items.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: TextField(
                      controller: controllers[index],
                      keyboardType: TextInputType.number,
                      onChanged: (_) => setDialogState(() {}),
                      decoration: InputDecoration(
                        labelText: items[index],
                        prefixText: "₱ ",
                        border: const OutlineInputBorder(),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                  );
                },
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Subtotal:", style: TextStyle(fontWeight: FontWeight.bold)),
                    Text("₱${calculateTotal().toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.bold, color: primaryColor)),
                  ],
                ),
              ),
              const Divider(),
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
              ElevatedButton(
                onPressed: () async {
                  final List<double> prices = controllers.map((c) => double.tryParse(c.text) ?? 0.0).toList();
                  await _orderService.updateItemPrices(order.id!, prices);
                  if (mounted) Navigator.pop(context);
                },
                child: const Text("Save Prices"),
              ),
            ],
          );
        }
      ),
    );
  }

  void _showUpdateLocationDialog(OrderModel order) {
    final TextEditingController locationController = TextEditingController(text: order.currentLocationName);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Where are you now?"),
        content: TextField(
          controller: locationController,
          decoration: const InputDecoration(
            hintText: "Enter location (e.g., Purok 2)",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              if (locationController.text.isNotEmpty) {
                await _orderService.updateRiderLocation(order.id!, locationController.text);
                if (mounted) Navigator.pop(context);
              }
            },
            child: const Text("Update"),
          ),
        ],
      ),
    );
  }

  String _getNextStatusLabel(String currentStatus) {
    switch (currentStatus) {
      case 'accepted': return "Mark as On The Way";
      case 'on the way': return "Mark as Delivered";
      default: return "Update Status";
    }
  }

  Future<void> _handleOrderUpdate(OrderModel order, bool isAvailable) async {
    if (order.id == null) return;
    
    if (isAvailable && !widget.isOnline) {
       ScaffoldMessenger.of(context).showSnackBar(
         const SnackBar(content: Text("Action failed: Your phone is currently Offline."), backgroundColor: Colors.redAccent)
       );
       return;
    }

    String nextStatus = isAvailable ? 'accepted' : (order.status == 'accepted' ? 'on the way' : 'delivered');

    try {
      await _orderService.updateOrderStatus(order.id!, nextStatus, riderId: _riderId);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Status updated to $nextStatus")));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }
}
