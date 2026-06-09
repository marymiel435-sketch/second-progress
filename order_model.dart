import 'package:cloud_firestore/cloud_firestore.dart';

class OrderModel {
  final String? id;
  final String customerId;
  final String? riderId;
  final String type; // 'pickup', 'pabili', 'food', 'bills'
  final String? pickupLocation;
  final String dropoffLocation;
  final String? packageDescription;
  final List<String>? items;
  final List<double>? itemPrices; // Individual item pricing
  final String status; // 'pending', 'accepted', 'on the way', 'delivered', 'cancelled'
  final DateTime createdAt;
  final String? storeName;
  
  // Real-time tracking fields
  final String? currentLocationName; // e.g., "Purok 2"
  final double? riderLatitude;
  final double? riderLongitude;

  // New fields for Bills
  final String? billerName;
  final String? accountName;
  final String? accountNumber;
  final double? amount; // This is the total for Items/Bill amount

  // Added fields for Pricing
  final double? deliveryFee;
  final double? serviceFee;
  final double? distanceKm;

  // Proof of Delivery
  final String? proofOfDeliveryUrl;

  OrderModel({
    this.id,
    required this.customerId,
    this.riderId,
    required this.type,
    this.pickupLocation,
    required this.dropoffLocation,
    this.packageDescription,
    this.items,
    this.itemPrices,
    required this.status,
    required this.createdAt,
    this.storeName,
    this.currentLocationName,
    this.riderLatitude,
    this.riderLongitude,
    this.billerName,
    this.accountName,
    this.accountNumber,
    this.amount,
    this.deliveryFee,
    this.serviceFee,
    this.distanceKm,
    this.proofOfDeliveryUrl,
  });

  factory OrderModel.fromMap(Map<String, dynamic> data, String documentId) {
    return OrderModel(
      id: documentId,
      customerId: data['customerId'] ?? '',
      riderId: data['riderId'],
      type: data['type'] ?? '',
      pickupLocation: data['pickupLocation'],
      dropoffLocation: data['dropoffLocation'] ?? '',
      packageDescription: data['packageDescription'],
      items: data['items'] != null ? List<String>.from(data['items']) : null,
      itemPrices: data['itemPrices'] != null ? List<double>.from(data['itemPrices'].map((e) => e.toDouble())) : null,
      status: data['status'] ?? 'pending',
      createdAt: data['createdAt'] != null 
          ? (data['createdAt'] is Timestamp 
              ? (data['createdAt'] as Timestamp).toDate() 
              : DateTime.now()) 
          : DateTime.now(),
      storeName: data['storeName'],
      currentLocationName: data['currentLocationName'],
      riderLatitude: data['riderLatitude']?.toDouble(),
      riderLongitude: data['riderLongitude']?.toDouble(),
      billerName: data['billerName'],
      accountName: data['accountName'],
      accountNumber: data['accountNumber'],
      amount: data['amount']?.toDouble(),
      deliveryFee: data['deliveryFee']?.toDouble(),
      serviceFee: data['serviceFee']?.toDouble(),
      distanceKm: data['distanceKm']?.toDouble(),
      proofOfDeliveryUrl: data['proofOfDeliveryUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'customerId': customerId,
      'riderId': riderId,
      'type': type,
      'pickupLocation': pickupLocation,
      'dropoffLocation': dropoffLocation,
      'packageDescription': packageDescription,
      'items': items,
      'itemPrices': itemPrices,
      'status': status,
      'createdAt': createdAt,
      'storeName': storeName,
      'currentLocationName': currentLocationName,
      'riderLatitude': riderLatitude,
      'riderLongitude': riderLongitude,
      'billerName': billerName,
      'accountName': accountName,
      'accountNumber': accountNumber,
      'amount': amount,
      'deliveryFee': deliveryFee,
      'serviceFee': serviceFee,
      'distanceKm': distanceKm,
      'proofOfDeliveryUrl': proofOfDeliveryUrl,
    };
  }

  double get totalToPay {
    return (amount ?? 0) + (deliveryFee ?? 0) + (serviceFee ?? 0);
  }
}
