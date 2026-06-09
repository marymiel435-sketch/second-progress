import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/order_model.dart';
import '../../services/order_service.dart';
import '../../services/auth_service.dart';
import '../../models/user_model.dart';

class TrackRiderScreen extends StatefulWidget {
  final String? orderId;
  final VoidCallback? onBack;
  const TrackRiderScreen({super.key, this.orderId, this.onBack});

  @override
  State<TrackRiderScreen> createState() => _TrackRiderScreenState();
}

class _TrackRiderScreenState extends State<TrackRiderScreen> {
  // Light Blue Theme Colors
  static const Color primaryColor = Color(0xFF03A9F4);
  static const Color gradientStart = Color(0xFF81D4FA);
  static const Color gradientEnd = Color(0xFF0288D1);

  final OrderService _orderService = OrderService();
  final AuthService _authService = AuthService();
  final String _userId = FirebaseAuth.instance.currentUser?.uid ?? "";
  final MapController _mapController = MapController();

  @override
  Widget build(BuildContext context) {
    if (_userId.isEmpty) {
      return const Scaffold(body: Center(child: Text("Please login to track orders.")));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: StreamBuilder<List<OrderModel>>(
        stream: _orderService.getCustomerOrders(_userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          final orders = snapshot.data ?? [];
          
          OrderModel? order;
          if (widget.orderId != null) {
            try {
              order = orders.firstWhere((o) => o.id == widget.orderId);
            } catch (e) {
              // Fallback if specific order not found
            }
          }
          
          if (order == null) {
            final activeOrders = orders
                .where((o) => o.status != 'cancelled' && o.status != 'delivered')
                .toList();
            if (activeOrders.isNotEmpty) {
              order = activeOrders.first;
            } else if (orders.isNotEmpty) {
              order = orders.first;
            }
          }

          if (order == null) {
            return _buildNoActiveOrderUI();
          }
          
          // Type promotion for null safety
          final currentOrder = order;
          final bool isDelivered = currentOrder.status == 'delivered';

          // Use rider's live coordinates or default to Trento center
          final LatLng riderPos = (currentOrder.riderLatitude != null && currentOrder.riderLongitude != null)
              ? LatLng(currentOrder.riderLatitude!, currentOrder.riderLongitude!)
              : const LatLng(8.0494, 126.0617); 

          return Stack(
            children: [
              // ===== LIVE MAP =====
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: riderPos,
                  initialZoom: 16.0,
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.finalproject',
                  ),
                  MarkerLayer(
                    markers: [
                      // Destination Marker (Customer/Drop-off)
                      const Marker(
                        point: LatLng(8.0494, 126.0617), 
                        width: 40,
                        height: 40,
                        child: Icon(Icons.location_on, color: Colors.red, size: 35),
                      ),
                      // Rider Live Marker
                      Marker(
                        point: riderPos,
                        width: 80,
                        height: 80,
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                              ),
                              child: const Text(
                                "Rider",
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: primaryColor),
                              ),
                            ),
                            const Icon(Icons.delivery_dining, color: primaryColor, size: 45),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // ===== HEADER =====
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(10, 50, 20, 20),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [gradientStart, gradientEnd],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(30),
                      bottomRight: Radius.circular(30),
                    ),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () {
                          if (widget.onBack != null) {
                            widget.onBack!();
                          } else {
                            Navigator.pop(context);
                          }
                        },
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 22),
                      ),
                      const Text(
                        "Tracking Order",
                        style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () {
                          _mapController.move(riderPos, 16.0);
                        },
                        icon: const Icon(Icons.my_location, color: Colors.white),
                        style: IconButton.styleFrom(backgroundColor: Colors.white.withAlpha(51)),
                      ),
                    ],
                  ),
                ),
              ),

              // ===== DETAILS PANEL =====
              DraggableScrollableSheet(
                initialChildSize: 0.35,
                minChildSize: 0.15,
                maxChildSize: 0.85,
                builder: (context, scrollController) {
                  return Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(topLeft: Radius.circular(35), topRight: Radius.circular(35)),
                      boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, spreadRadius: 5)],
                    ),
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.all(25),
                      children: [
                        Center(
                          child: Container(
                            width: 50,
                            height: 5,
                            decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                        const SizedBox(height: 25),
                        
                        if (isDelivered)
                          Container(
                            margin: const EdgeInsets.only(bottom: 20),
                            padding: const EdgeInsets.all(15),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.check_circle, color: Colors.green, size: 30),
                                SizedBox(width: 15),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text("DELIVERY COMPLETED", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 16)),
                                      Text("Your order has been delivered successfully. It is now saved in your history.", style: TextStyle(fontSize: 12, color: Colors.black54)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // Rider Info & Location Section
                        Row(
                          children: [
                            const CircleAvatar(
                              radius: 30,
                              backgroundColor: primaryColor,
                              child: Icon(Icons.person, color: Colors.white, size: 35),
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  FutureBuilder<UserModel?>(
                                    future: currentOrder.riderId != null 
                                        ? _authService.getUserData(currentOrder.riderId!) 
                                        : Future.value(null),
                                    builder: (context, riderSnapshot) {
                                      final rider = riderSnapshot.data;
                                      return Text(
                                        rider != null ? "${rider.firstName} ${rider.lastName}" : "Assigning Rider...",
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                                      );
                                    },
                                  ),
                                  // Specific Location Badge
                                  Container(
                                    margin: const EdgeInsets.only(top: 4),
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: primaryColor.withAlpha(25),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.location_on, size: 14, color: primaryColor),
                                        const SizedBox(width: 4),
                                        Text(
                                          isDelivered 
                                              ? "At Destination"
                                              : (currentOrder.currentLocationName != null 
                                                  ? "At ${currentOrder.currentLocationName}"
                                                  : "Updating location..."),
                                          style: const TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (!isDelivered)
                              IconButton.filled(
                                onPressed: () {}, 
                                icon: const Icon(Icons.phone),
                                style: IconButton.styleFrom(backgroundColor: Colors.green),
                              ),
                          ],
                        ),
                        
                        const Divider(height: 40),
                        
                        // Order Status Progress Bar
                        _buildStatusProgress(currentOrder.status),
                        
                        const SizedBox(height: 30),
                        
                        // Order Details
                        const Text("Order Summary", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        const SizedBox(height: 15),
                        _buildDetailRow(Icons.inventory_2_outlined, "Service", currentOrder.type.toUpperCase()),
                        
                        if (currentOrder.type == 'pabili' || currentOrder.type == 'food') ...[
                          _buildDetailRow(Icons.store_outlined, "Store", currentOrder.storeName ?? "N/A"),
                          if (currentOrder.items != null) ...[
                            const Padding(
                              padding: EdgeInsets.only(left: 35, top: 10, bottom: 5),
                              child: Text("Items & Prices", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                            ),
                            ...List.generate(currentOrder.items!.length, (index) {
                              final itemName = currentOrder.items![index];
                              final itemPrice = (currentOrder.itemPrices != null && currentOrder.itemPrices!.length > index)
                                  ? currentOrder.itemPrices![index]
                                  : null;
                              return Padding(
                                padding: const EdgeInsets.only(left: 35, bottom: 5, right: 0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(child: Text(itemName, style: const TextStyle(fontSize: 14))),
                                    Text(itemPrice != null ? "₱${itemPrice.toStringAsFixed(2)}" : "₱0.00", 
                                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                                  ],
                                ),
                              );
                            }),
                            const Divider(indent: 35),
                            _buildDetailRow(Icons.shopping_bag_outlined, "Items Subtotal", "₱${(currentOrder.amount ?? 0).toStringAsFixed(2)}", isBold: true),
                          ],
                        ] else if (currentOrder.type == 'bills') ...[
                          _buildDetailRow(Icons.receipt_long_outlined, "Biller", currentOrder.billerName ?? "N/A"),
                          _buildDetailRow(Icons.payments_outlined, "Amount", "₱${currentOrder.amount?.toStringAsFixed(2)}"),
                        ] else ...[
                          _buildDetailRow(Icons.description_outlined, "Package", currentOrder.packageDescription ?? "N/A"),
                        ],
                        
                        _buildDetailRow(Icons.flag_outlined, "Drop-off", currentOrder.dropoffLocation),
                        
                        const Divider(height: 20),
                        // Pricing Details
                        _buildDetailRow(Icons.straighten, "Distance", "${currentOrder.distanceKm?.toStringAsFixed(2) ?? '0.00'} km"),
                        _buildDetailRow(Icons.payments_outlined, "Delivery Fee", "₱${currentOrder.deliveryFee?.toStringAsFixed(2) ?? '0.00'}"),
                        _buildDetailRow(Icons.room_service_outlined, "Service Fee", "₱${currentOrder.serviceFee?.toStringAsFixed(2) ?? '0.00'}"),
                        
                        const Divider(height: 10),
                        _buildDetailRow(Icons.account_balance_wallet, "TOTAL TO PAY", "₱${currentOrder.totalToPay.toStringAsFixed(2)}", isBold: true),

                        const SizedBox(height: 25),
                        if (isDelivered)
                          ElevatedButton.icon(
                            onPressed: () {
                              if (widget.onBack != null) {
                                widget.onBack!();
                              } else {
                                Navigator.pop(context);
                              }
                            },
                            icon: const Icon(Icons.home),
                            label: const Text("Back to Dashboard", style: TextStyle(fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(double.infinity, 55),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                            ),
                          )
                        else
                          ElevatedButton.icon(
                            onPressed: () {},
                            icon: const Icon(Icons.chat_bubble_outline),
                            label: const Text("Message Rider", style: TextStyle(fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(double.infinity, 55),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                            ),
                          ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildNoActiveOrderUI() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(10, 50, 20, 20),
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [gradientStart, gradientEnd]),
            borderRadius: BorderRadius.only(bottomLeft: Radius.circular(35), bottomRight: Radius.circular(35)),
          ),
          child: Row(
            children: [
              IconButton(
                onPressed: () {
                  if (widget.onBack != null) {
                    widget.onBack!();
                  } else {
                    Navigator.pop(context);
                  }
                },
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 22),
              ),
              const Text("Track Rider", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.map_outlined, size: 100, color: Colors.grey[300]),
                const SizedBox(height: 20),
                const Text("No active deliveries to track", style: TextStyle(fontSize: 18, color: Colors.grey, fontWeight: FontWeight.w500)),
                const Padding(
                  padding: EdgeInsets.all(20),
                  child: Text("Once a rider accepts your order, you'll be able to see their location here.", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                Text(value, style: TextStyle(color: isBold ? primaryColor : Colors.black87, fontSize: 15, fontWeight: isBold ? FontWeight.bold : FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusProgress(String status) {
    int step = 1;
    if (status == 'accepted') step = 2;
    if (status == 'on the way') step = 3;
    if (status == 'delivered') step = 4;

    return Row(
      children: [
        _statusStep("Request", step >= 1),
        _statusLine(step >= 2),
        _statusStep("Accepted", step >= 2),
        _statusLine(step >= 3),
        _statusStep("On Way", step >= 3),
        _statusLine(step >= 4),
        _statusStep("Arrived", step >= 4),
      ],
    );
  }

  Widget _statusStep(String label, bool active) {
    return Expanded(
      child: Column(
        children: [
          Icon(active ? Icons.check_circle : Icons.radio_button_unchecked, color: active ? primaryColor : Colors.grey[300], size: 22),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 10, color: active ? Colors.black87 : Colors.grey, fontWeight: active ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }

  Widget _statusLine(bool active) {
    return Container(width: 30, height: 2, color: active ? primaryColor : Colors.grey[200], margin: const EdgeInsets.only(bottom: 18));
  }
}
