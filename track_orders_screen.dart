import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import '../../models/order_model.dart';
import '../../services/order_service.dart';
import '../../services/auth_service.dart';
import '../../models/user_model.dart';

class TrackOrdersScreen extends StatefulWidget {
  const TrackOrdersScreen({super.key});

  @override
  State<TrackOrdersScreen> createState() => _TrackOrdersScreenState();
}

class _TrackOrdersScreenState extends State<TrackOrdersScreen> {
  static const Color primaryColor = Color(0xFF03A9F4);
  
  final OrderService _orderService = OrderService();
  final AuthService _authService = AuthService();
  final String _riderId = FirebaseAuth.instance.currentUser?.uid ?? "";
  
  StreamSubscription<Position>? _positionSubscription;
  String? _currentTrackingOrderId;
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  @override
  void dispose() {
    _stopTracking();
    super.dispose();
  }

  Future<void> _checkPermissions() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      return;
    }
  }

  void _startTracking(String orderId) {
    if (_currentTrackingOrderId == orderId) return;
    
    _stopTracking();
    _currentTrackingOrderId = orderId;
    
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
    );

    _positionSubscription = Geolocator.getPositionStream(locationSettings: locationSettings).listen(
      (Position position) {
        _orderService.updateRiderLocation(
          orderId, 
          "Updating...", // We could use geocoding here if needed
          lat: position.latitude, 
          lng: position.longitude
        );
      },
    );
  }

  void _stopTracking() {
    _positionSubscription?.cancel();
    _positionSubscription = null;
    _currentTrackingOrderId = null;
  }

  @override
  Widget build(BuildContext context) {
    if (_riderId.isEmpty) {
      return const Scaffold(body: Center(child: Text("Please login to view tasks.")));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Active Delivery Map"),
        backgroundColor: const Color(0xFF03A9F4),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<OrderModel>>(
        stream: _orderService.getRiderActiveOrders(_riderId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text("Error: ${snapshot.error}", style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
              ),
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final orders = snapshot.data ?? [];
          if (orders.isEmpty) {
            _stopTracking();
            return _buildNoActiveTaskUI();
          }

          final order = orders.first;
          
          // Start real-time tracking for this order
          if (order.id != null) {
            _startTracking(order.id!);
          }

          final LatLng currentPos = (order.riderLatitude != null && order.riderLongitude != null)
              ? LatLng(order.riderLatitude!, order.riderLongitude!)
              : const LatLng(8.0494, 126.0617); // Trento Center

          return Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: currentPos,
                  initialZoom: 15.0,
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.finalproject',
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: currentPos,
                        width: 60,
                        height: 60,
                        child: const Icon(Icons.delivery_dining, color: primaryColor, size: 40),
                      ),
                      // You might want to add customer location here if available
                    ],
                  ),
                ],
              ),
              Positioned(
                bottom: 20,
                left: 15,
                right: 15,
                child: Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.local_shipping, color: primaryColor),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                "Delivery to ${order.dropoffLocation}",
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 25),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text("CUSTOMER", style: TextStyle(fontSize: 10, color: Colors.grey)),
                                FutureBuilder<UserModel?>(
                                  future: _authService.getUserData(order.customerId),
                                  builder: (context, userSnap) {
                                    return Text(userSnap.data?.firstName ?? "Loading...", 
                                        style: const TextStyle(fontWeight: FontWeight.bold));
                                  },
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Text("CURRENT STATUS", style: TextStyle(fontSize: 10, color: Colors.grey)),
                                Text(order.status.toUpperCase(), 
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text("Dashboard"),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: primaryColor, foregroundColor: Colors.white),
                                onPressed: () {
                                  _mapController.move(currentPos, 15.0);
                                },
                                child: const Text("Recenter"),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildNoActiveTaskUI() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.map_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 15),
          const Text("No active delivery to track", style: TextStyle(color: Colors.grey, fontSize: 18)),
          const SizedBox(height: 10),
          const Text("Accept a request to see it here.", style: TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }
}
