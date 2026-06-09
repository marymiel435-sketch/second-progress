import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../services/auth_service.dart';
import '../services/order_service.dart';
import '../models/user_model.dart';
import '../models/order_model.dart';
import 'login_screen.dart';
import 'rider/my_deliveries_screen.dart';
import 'rider/track_orders_screen.dart';
import 'rider/delivery_history_screen.dart';
import 'rider/profile_screen.dart';
import 'rider/settings_screen.dart';

class RiderDashboard extends StatefulWidget {
  const RiderDashboard({super.key});

  @override
  State<RiderDashboard> createState() => _RiderDashboardState();
}

class _RiderDashboardState extends State<RiderDashboard> {
  int _selectedIndex = 0;
  final AuthService _authService = AuthService();
  final OrderService _orderService = OrderService();
  
  bool _isOnline = true;
  bool _isFirstCheck = true;
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;

  static const Color primaryColor = Color(0xFF03A9F4);
  static const Color gradientStart = Color(0xFF81D4FA);
  static const Color gradientEnd = Color(0xFF0288D1);

  @override
  void initState() {
    super.initState();
    _checkInitialConnectivity();
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
      _updateConnectivityStatus(results);
    });
  }

  Future<void> _checkInitialConnectivity() async {
    final List<ConnectivityResult> results = await Connectivity().checkConnectivity();
    _updateConnectivityStatus(results);
  }

  void _updateConnectivityStatus(List<ConnectivityResult> results) {
    final bool isNowOnline = results.any((result) => result != ConnectivityResult.none);
    
    if (_isOnline != isNowOnline || _isFirstCheck) {
      if (mounted) {
        setState(() {
          _isOnline = isNowOnline;
          _isFirstCheck = false;
        });
      }

      final User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        _authService.updateOnlineStatus(user.uid, isNowOnline);
      }
    }
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;

    if (user == null) return const LoginScreen();

    return FutureBuilder<UserModel?>(
      future: _authService.getUserData(user.uid),
      builder: (context, userSnapshot) {
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final userData = userSnapshot.data;
        final String firstName = userData?.firstName ?? "Rider";
        final String lastName = userData?.lastName ?? "";
        final String fullName = "$firstName $lastName";
        
        final List<Widget> screens = [
          _HomeTab(
            user: user, 
            fullName: fullName, 
            orderService: _orderService,
            isOnline: _isOnline, 
            onTrackPressed: () => _onItemTapped(2),
            primaryColor: primaryColor,
            gradientStart: gradientStart,
            gradientEnd: gradientEnd,
          ),
          MyDeliveriesScreen(isOnline: _isOnline),
          const TrackOrdersScreen(),
          const RiderDeliveryHistoryScreen(),
          const RiderProfileScreen(),
        ];

        return Scaffold(
          backgroundColor: const Color(0xFFF5F7FA),
          body: Column(
            children: [
              if (!_isOnline)
                Container(
                  width: double.infinity,
                  color: Colors.redAccent,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: const SafeArea(
                    bottom: false,
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.wifi_off, color: Colors.white, size: 18),
                          SizedBox(width: 10),
                          Text(
                            "YOU ARE OFFLINE: Internet connection required",
                            style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              Expanded(
                child: IndexedStack(
                  index: _selectedIndex,
                  children: screens,
                ),
              ),
            ],
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            type: BottomNavigationBarType.fixed,
            selectedItemColor: primaryColor,
            unselectedItemColor: Colors.grey,
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: "Home"),
              BottomNavigationBarItem(icon: Icon(Icons.local_shipping_outlined), activeIcon: Icon(Icons.local_shipping), label: "Deliveries"),
              BottomNavigationBarItem(icon: Icon(Icons.location_on_outlined), activeIcon: Icon(Icons.location_on), label: "Track"),
              BottomNavigationBarItem(icon: Icon(Icons.history_outlined), activeIcon: Icon(Icons.history), label: "History"),
              BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: "Profile"),
            ],
          ),
        );
      },
    );
  }
}

class _HomeTab extends StatelessWidget {
  final User user;
  final String fullName;
  final OrderService orderService;
  final bool isOnline;
  final VoidCallback onTrackPressed;
  final Color primaryColor;
  final Color gradientStart;
  final Color gradientEnd;

  const _HomeTab({
    required this.user,
    required this.fullName,
    required this.orderService,
    required this.isOnline,
    required this.onTrackPressed,
    required this.primaryColor,
    required this.gradientStart,
    required this.gradientEnd,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {},
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            // ================= TOP HEADER =================
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(25, 60, 15, 45),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: isOnline 
                      ? [gradientStart, gradientEnd] 
                      : [Colors.grey.shade900, Colors.grey.shade700],
                ),
                borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(40), bottomRight: Radius.circular(40)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(isOnline ? "Welcome Rider 👋" : "System Status: ", 
                                  style: const TextStyle(color: Colors.white70, fontSize: 16)),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isOnline ? Colors.green.withValues(alpha: 0.2) : Colors.red.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: isOnline ? Colors.green : Colors.red, width: 1.5),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 8, height: 8, 
                                        decoration: BoxDecoration(color: isOnline ? Colors.green : Colors.red, shape: BoxShape.circle)
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        isOnline ? "ONLINE" : "OFFLINE", 
                                        style: TextStyle(color: isOnline ? Colors.green : Colors.red, fontSize: 11, fontWeight: FontWeight.bold)
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(fullName, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.settings_outlined, color: Colors.white), 
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RiderSettingsScreen()))
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Text(isOnline ? "Ready to earn today?" : "Reconnect internet to receive jobs", 
                    style: const TextStyle(color: Colors.white60, fontSize: 16)),
                ],
              ),
            ),

            // ================= STATUS CARD =================
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Transform.translate(
                offset: const Offset(0, -35),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 25, horizontal: 10),
                  decoration: BoxDecoration(
                    color: Colors.white, 
                    borderRadius: BorderRadius.circular(25), 
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 15, offset: const Offset(0, 8))]
                  ),
                  child: StreamBuilder<List<OrderModel>>(
                    stream: orderService.getRiderActiveOrders(user.uid),
                    builder: (context, activeSnapshot) {
                      return StreamBuilder<List<OrderModel>>(
                        stream: orderService.getRiderCompletedOrders(user.uid),
                        builder: (context, completedSnapshot) {
                          final activeCount = activeSnapshot.data?.length ?? 0;
                          final completedCount = completedSnapshot.data?.length ?? 0;
                          final earnings = completedSnapshot.data?.fold<double>(0, (sum, order) => sum + (order.deliveryFee ?? 0)) ?? 0;

                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _StatusItem(icon: Icons.local_shipping, label: "Active", value: "$activeCount", color: Colors.orange),
                              _divider(),
                              _StatusItem(icon: Icons.check_circle, label: "Done", value: "$completedCount", color: Colors.green),
                              _divider(),
                              _StatusItem(icon: Icons.payments, label: "Earned", value: "₱${earnings.toStringAsFixed(0)}", color: primaryColor),
                            ],
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
            ),

            // ================= NEW DELIVERY REQUESTS & CURRENT DELIVERIES =================
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("New Delivery Request", 
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: gradientEnd)),
                  const SizedBox(height: 15),
                  
                  if (!isOnline) 
                    _emptyState("Please connect to the internet to receive requests"),
                  
                  if (isOnline)
                    StreamBuilder<List<OrderModel>>(
                      stream: orderService.getAvailableOrders(),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) return _errorState("Error loading requests");
                        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                        final available = snapshot.data ?? [];
                        if (available.isEmpty) return _emptyState("No new requests available");
                        return Column(children: available.map((order) => _NewJobCard(order: order, riderId: user.uid, orderService: orderService, primaryColor: primaryColor)).toList());
                      },
                    ),
                  
                  const SizedBox(height: 30),
                  Text("Current Delivery", 
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: gradientEnd)),
                  const SizedBox(height: 15),
                  StreamBuilder<List<OrderModel>>(
                    stream: orderService.getRiderActiveOrders(user.uid),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) return _errorState("Error loading active deliveries");
                      if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                      final active = snapshot.data ?? [];
                      if (active.isEmpty) return _emptyState("No active deliveries");
                      return Column(children: active.map((order) => _CurrentDeliveryCard(order: order, onTrackPressed: onTrackPressed, primaryColor: primaryColor, orderService: orderService)).toList());
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState(String message) => Container(padding: const EdgeInsets.all(20), width: double.infinity, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)), child: Center(child: Text(message, style: const TextStyle(color: Colors.grey))));
  Widget _errorState(String message) => Container(padding: const EdgeInsets.all(20), width: double.infinity, decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)), child: Center(child: Text(message, style: const TextStyle(color: Colors.red, fontSize: 12))));
  Widget _divider() => Container(height: 40, width: 1, color: Colors.grey.withValues(alpha: 0.2));
}

class _StatusItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _StatusItem({required this.icon, required this.label, required this.value, required this.color});
  @override
  Widget build(BuildContext context) => Column(children: [Icon(icon, color: color, size: 28), const SizedBox(height: 8), Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87)), Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12))]);
}

class _NewJobCard extends StatelessWidget {
  final OrderModel order;
  final String riderId;
  final OrderService orderService;
  final Color primaryColor;
  const _NewJobCard({required this.order, required this.riderId, required this.orderService, required this.primaryColor});
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(25), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)]),
      child: Column(
        children: [
          Row(
            children: [
              Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: primaryColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(15)), child: Icon(Icons.add_shopping_cart, color: primaryColor, size: 30)),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("New ${order.type.toUpperCase()} Request", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text("Pickup: ${order.pickupLocation ?? order.storeName ?? 'Not specified'}", style: const TextStyle(color: Colors.grey, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text("₱${((order.deliveryFee ?? 0) + (order.serviceFee ?? 0)).toStringAsFixed(0)}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.green)),
                  Text("${order.distanceKm?.toStringAsFixed(1)} km", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => orderService.updateOrderStatus(order.id!, 'declined', riderId: riderId), 
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.redAccent), 
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), 
                    padding: const EdgeInsets.symmetric(vertical: 12)
                  ), 
                  child: const Text("Decline", style: TextStyle(color: Colors.redAccent))
                )
              ),
              const SizedBox(width: 10),
              Expanded(child: ElevatedButton(onPressed: () => orderService.updateOrderStatus(order.id!, 'accepted', riderId: riderId), style: ElevatedButton.styleFrom(backgroundColor: primaryColor, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 12)), child: const Text("Accept"))),
            ],
          ),
        ],
      ),
    );
  }
}

class _CurrentDeliveryCard extends StatelessWidget {
  final OrderModel order;
  final VoidCallback onTrackPressed;
  final Color primaryColor;
  final OrderService orderService;

  const _CurrentDeliveryCard({required this.order, required this.onTrackPressed, required this.primaryColor, required this.orderService});

  @override
  Widget build(BuildContext context) {
    final bool isPabili = order.type == 'pabili';
    final bool isFood = order.type == 'food';

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(25), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)]),
      child: Column(
        children: [
          Row(
            children: [
              Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(15)), child: const Icon(Icons.moped, color: Colors.orange, size: 30)),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Order is ${order.status}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text("Store: ${order.storeName ?? 'Generic Store'}", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text("₱${order.totalToPay.toStringAsFixed(0)}", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: primaryColor)),
                  const Text("TOTAL", style: TextStyle(fontSize: 10, color: Colors.grey)),
                ],
              ),
            ],
          ),
          if (isPabili || isFood) ...[
             const SizedBox(height: 15),
             Row(
               mainAxisAlignment: MainAxisAlignment.spaceBetween,
               children: [
                 Text("Items: ${order.items?.length ?? 0}", style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                 TextButton(
                   onPressed: () => _showUpdateItemsPriceDialog(context, order), 
                   child: const Text("Update Prices", style: TextStyle(fontSize: 12))
                 ),
               ],
             ),
          ],
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _infoColumn("#${order.id?.substring(0, 5) ?? 'N/A'}", "Order ID"),
              _infoColumn(order.type.toUpperCase(), "Type"),
              _infoColumn(order.status.toUpperCase(), "Status"),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(width: double.infinity, child: ElevatedButton.icon(onPressed: onTrackPressed, icon: const Icon(Icons.location_on, size: 18), label: const Text("Track Order"), style: ElevatedButton.styleFrom(backgroundColor: primaryColor, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 15)))),
        ],
      ),
    );
  }

  void _showUpdateItemsPriceDialog(BuildContext context, OrderModel order) {
    final items = order.items ?? [];
    if (items.isEmpty) return;

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
          double calculateSubtotal() {
            double total = 0;
            for (var controller in controllers) {
              total += double.tryParse(controller.text) ?? 0;
            }
            return total;
          }

          return AlertDialog(
            title: const Text("Update Item Prices"),
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
                    Text("₱${calculateSubtotal().toStringAsFixed(2)}", style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor)),
                  ],
                ),
              ),
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
              ElevatedButton(
                onPressed: () async {
                  final List<double> prices = controllers.map((c) => double.tryParse(c.text) ?? 0.0).toList();
                  await orderService.updateItemPrices(order.id!, prices);
                  if (context.mounted) Navigator.pop(context);
                },
                child: const Text("Save Prices"),
              ),
            ],
          );
        }
      ),
    );
  }

  Widget _infoColumn(String value, String label) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)), Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10))]);
}
