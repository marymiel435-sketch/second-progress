import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/order_service.dart';
import '../services/notification_service.dart';
import '../models/order_model.dart';
import '../models/user_model.dart';
import '../models/notification_model.dart';
import 'login_screen.dart';
import 'customer/request_service_screen.dart';
import 'customer/track_rider_screen.dart';
import 'customer/delivery_history_screen.dart';
import 'customer/notifications_screen.dart';
import 'customer/profile_screen.dart';
import 'customer/settings_screen.dart';
import 'customer/support_screen.dart';

class CustomerDashboard extends StatefulWidget {
  const CustomerDashboard({super.key});

  @override
  State<CustomerDashboard> createState() => _CustomerDashboardState();
}

class _CustomerDashboardState extends State<CustomerDashboard> {
  int _selectedIndex = 0;
  final AuthService _authService = AuthService();
  final NotificationService _notificationService = NotificationService();
  String? _trackingOrderId;
  StreamSubscription? _notificationSubscription;

  static const Color primaryColor = Color(0xFF03A9F4);
  static const Color gradientStart = Color(0xFF81D4FA);
  static const Color gradientEnd = Color(0xFF0288D1);

  @override
  void initState() {
    super.initState();
    _startNotificationListener();
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    super.dispose();
  }

  void _startNotificationListener() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Listen for latest unread notifications to show SnackBars
      _notificationSubscription = _notificationService
          .getLatestUnreadNotification(user.uid)
          .listen((notification) {
        if (notification != null && mounted) {
          _showNotificationSnackBar(notification);
        }
      });
    }
  }

  void _showNotificationSnackBar(NotificationModel notification) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(notification.title, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(notification.body, style: const TextStyle(fontSize: 12)),
          ],
        ),
        action: SnackBarAction(
          label: "VIEW",
          onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen()));
          },
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 4),
        backgroundColor: const Color(0xFF003366),
      ),
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      if (index != 1) {
        _trackingOrderId = null;
      }
    });
  }

  void _navigateToTrack(String? orderId) {
    setState(() {
      _trackingOrderId = orderId;
      _selectedIndex = 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final OrderService orderService = OrderService();
    final User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const LoginScreen();
    }

    return FutureBuilder<UserModel?>(
      future: _authService.getUserData(user.uid),
      builder: (context, userSnapshot) {
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final userData = userSnapshot.data;
        final String firstName = userData?.firstName ?? "Customer";
        final String lastName = userData?.lastName ?? "";

        final List<Widget> screens = [
          _HomeTab(
            user: user,
            firstName: firstName,
            lastName: lastName,
            orderService: orderService,
            authService: _authService,
            notificationService: _notificationService,
            primaryColor: primaryColor,
            gradientStart: gradientStart,
            gradientEnd: gradientEnd,
            onTrackRequested: _navigateToTrack,
          ),
          TrackRiderScreen(key: ValueKey(_trackingOrderId), orderId: _trackingOrderId),
          const DeliveryHistoryScreen(),
          const SettingsScreen(),
          const ProfileScreen(),
        ];

        return Scaffold(
          backgroundColor: const Color(0xFFF5F7FA),
          body: IndexedStack(
            index: _selectedIndex,
            children: screens,
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            type: BottomNavigationBarType.fixed,
            selectedItemColor: primaryColor,
            unselectedItemColor: Colors.grey,
            showUnselectedLabels: true,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home),
                label: "Home",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.location_on_outlined),
                activeIcon: Icon(Icons.location_on),
                label: "Track",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.history_outlined),
                activeIcon: Icon(Icons.history),
                label: "History",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.settings_outlined),
                activeIcon: Icon(Icons.settings),
                label: "Settings",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                activeIcon: Icon(Icons.person),
                label: "Profile",
              ),
            ],
          ),
        );
      },
    );
  }
}

class _HomeTab extends StatelessWidget {
  final User user;
  final String firstName;
  final String lastName;
  final OrderService orderService;
  final AuthService authService;
  final NotificationService notificationService;
  final Color primaryColor;
  final Color gradientStart;
  final Color gradientEnd;
  final Function(String?) onTrackRequested;

  const _HomeTab({
    required this.user,
    required this.firstName,
    required this.lastName,
    required this.orderService,
    required this.authService,
    required this.notificationService,
    required this.primaryColor,
    required this.gradientStart,
    required this.gradientEnd,
    required this.onTrackRequested,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<OrderModel>>(
      stream: orderService.getCustomerOrders(user.uid),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Text("Error loading orders: ${snapshot.error}", 
            textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
          ));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final orders = snapshot.data ?? [];
        final activeOrders = orders
            .where((o) => o.status == 'accepted' || o.status == 'on the way')
            .toList();
        final completedOrders =
            orders.where((o) => o.status == 'delivered').toList();
        final pendingOrders =
            orders.where((o) => o.status == 'pending').toList();

        return SingleChildScrollView(
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 50, 20, 30),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [gradientStart, gradientEnd],
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(35),
                    bottomRight: Radius.circular(35),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.support_agent, color: Colors.white),
                          onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const SupportScreen())),
                        ),
                        StreamBuilder<List<NotificationModel>>(
                          stream: notificationService.getUserNotifications(user.uid),
                          builder: (context, notifSnapshot) {
                            final unreadCount = notifSnapshot.data?.where((n) => !n.isRead).length ?? 0;
                            return Stack(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.notifications_active_outlined, color: Colors.white),
                                  onPressed: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) => const NotificationsScreen())),
                                ),
                                if (unreadCount > 0)
                                  Positioned(
                                    right: 8,
                                    top: 8,
                                    child: Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(10)),
                                      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                                      child: Text(
                                        unreadCount > 9 ? "9+" : "$unreadCount",
                                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.logout, color: Colors.white),
                          onPressed: () async {
                            final navigator = Navigator.of(context);
                            await authService.logout();
                            if (context.mounted) {
                              navigator.pushReplacement(MaterialPageRoute(
                                  builder: (_) => const LoginScreen()));
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Text("Welcome back,",
                        style: TextStyle(color: Colors.white, fontSize: 16)),
                    const SizedBox(height: 5),
                    Text("$firstName $lastName",
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),
                    GestureDetector(
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const RequestServiceScreen())),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 15),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 4))
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                  color: primaryColor.withValues(alpha: 0.1),
                                  shape: BoxShape.circle),
                              child: Icon(Icons.add_location_alt_outlined,
                                  color: primaryColor, size: 26),
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("Request Service",
                                      style: TextStyle(
                                          color: primaryColor,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18)),
                                  const Text("Need a hand? Choose a service here.",
                                      style: TextStyle(
                                          color: Colors.grey, fontSize: 12)),
                                ],
                              ),
                            ),
                            Icon(Icons.arrow_forward_ios,
                                color: primaryColor, size: 16),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4))
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _statusItem(Icons.local_shipping, "Active",
                              activeOrders.length.toString(), Colors.orange),
                          _statusDivider(),
                          _statusItem(Icons.check_circle, "Completed",
                              completedOrders.length.toString(), Colors.green),
                          _statusDivider(),
                          _statusItem(Icons.pending_actions, "Pending",
                              pendingOrders.length.toString(), Colors.amber),
                        ],
                      ),
                    ),
                    const SizedBox(height: 25),
                    Text("Current Delivery",
                        style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: primaryColor)),
                    const SizedBox(height: 15),
                    if (activeOrders.isNotEmpty || pendingOrders.isNotEmpty)
                      _activeDeliveryCard(
                          context,
                          activeOrders.isNotEmpty
                              ? activeOrders.first
                              : pendingOrders.first,
                          primaryColor)
                    else
                      _noActiveDeliveryCard(),
                    const SizedBox(height: 25),
                    Text("Recent Activity",
                        style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: primaryColor)),
                    const SizedBox(height: 15),
                    _recentActivityList(context, orders),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _statusItem(IconData icon, String title, String value, Color color) {
    return Column(
      children: [
        CircleAvatar(
            radius: 22,
            backgroundColor: color.withValues(alpha: 0.2),
            child: Icon(icon, color: color)),
        const SizedBox(height: 8),
        Text(value,
            style: TextStyle(
                color: color, fontWeight: FontWeight.bold, fontSize: 20)),
        Text(title, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }

  Widget _statusDivider() => Container(
      height: 60, width: 1, color: Colors.grey.withValues(alpha: 0.2));

  Widget _activeDeliveryCard(
      BuildContext context, OrderModel order, Color primaryColor) {
    bool isPending = order.status == 'pending';
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
                color: Colors.grey.withValues(alpha: 0.08), blurRadius: 10)
          ]),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: (isPending ? Colors.amber : Colors.orange)
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(15)),
                child: Icon(
                    isPending ? Icons.timer_outlined : Icons.delivery_dining,
                    color: isPending ? Colors.amber : Colors.orange,
                    size: 30),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isPending)
                      const Text("Finding a Rider...",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Colors.black87))
                    else
                      FutureBuilder<UserModel?>(
                        future: order.riderId != null ? authService.getUserData(order.riderId!) : Future.value(null),
                        builder: (context, snapshot) {
                          final rider = snapshot.data;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                order.status == 'accepted' ? "Request Accepted!" : "Rider is ${order.status}",
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Colors.black87),
                              ),
                              if (rider != null) ...[
                                Text(
                                  "Rider: ${rider.firstName} ${rider.lastName}",
                                  style: TextStyle(color: primaryColor, fontWeight: FontWeight.w600, fontSize: 14),
                                ),
                                if (order.currentLocationName != null)
                                  Text(
                                    "Near ${order.currentLocationName}",
                                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                                  ),
                              ],
                            ],
                          );
                        },
                      ),
                    const SizedBox(height: 5),
                    Text(
                      order.type == 'pabili'
                          ? "Buying at ${order.storeName}"
                          : (order.type == 'bills'
                              ? "Paying ${order.billerName}"
                              : "Delivering: ${order.packageDescription ?? 'Package'}"),
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _DeliveryInfo(
                  title: "Order ID",
                  value: "#${order.id?.substring(0, 5) ?? 'N/A'}"),
              _DeliveryInfo(title: "Status", value: order.status.toUpperCase()),
              _DeliveryInfo(title: "Type", value: order.type.toUpperCase()),
            ],
          ),
          if (!isPending) ...[
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16))),
                onPressed: () => onTrackRequested(order.id),
                icon: const Icon(Icons.location_on),
                label: const Text("Track on Map"),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _noActiveDeliveryCard() => Container(
        padding: const EdgeInsets.all(30),
        width: double.infinity,
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(25)),
        child: const Column(
          children: [
            Icon(Icons.shopping_bag_outlined, size: 50, color: Colors.grey),
            SizedBox(height: 10),
            Text("No active deliveries",
                style: TextStyle(color: Colors.grey, fontSize: 16)),
          ],
        ),
      );

  Widget _recentActivityList(BuildContext context, List<OrderModel> orders) {
    if (orders.isEmpty) {
      return Container(
          padding: const EdgeInsets.all(20),
          width: double.infinity,
          decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(25)),
          child: const Center(child: Text("No activity yet")));
    }
    final recentOrders = orders.take(3).toList();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
                color: Colors.grey.withValues(alpha: 0.08), blurRadius: 10)
          ]),
      child: Column(
        children: recentOrders.map((order) {
          IconData icon;
          Color color;
          if (order.status == 'delivered') {
            icon = Icons.check;
            color = Colors.green;
          } else if (order.status == 'declined') {
            icon = Icons.close;
            color = Colors.red;
          } else if (order.status == 'pending') {
            icon = Icons.timer_outlined;
            color = Colors.amber;
          } else {
            icon = Icons.local_shipping;
            color = Colors.orange;
          }
          return Column(
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                    backgroundColor: color.withValues(alpha: 0.1),
                    child: Icon(icon, color: color)),
                title: Text(order.type == 'pabili'
                    ? "Pabili: ${order.storeName}"
                    : (order.type == 'bills'
                        ? "Bills: ${order.billerName}"
                        : "Delivery to ${order.dropoffLocation}")),
                subtitle: Text("Status: ${order.status}"),
                trailing: Text(
                    "${order.createdAt.hour}:${order.createdAt.minute.toString().padLeft(2, '0')}"),
                onTap: () {
                  if (order.status == 'accepted' || order.status == 'on the way') {
                    onTrackRequested(order.id);
                  }
                },
              ),
              if (order != recentOrders.last) const Divider(),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _DeliveryInfo extends StatelessWidget {
  final String title;
  final String value;
  const _DeliveryInfo({required this.title, required this.value});
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text(value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      const SizedBox(height: 5),
      Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12))
    ]);
  }
}
