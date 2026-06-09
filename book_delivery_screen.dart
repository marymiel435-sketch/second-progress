import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';
import '../../models/order_model.dart';
import '../../services/order_service.dart';

enum ServiceType { pickup, pabili, food, bills }

class BookDeliveryScreen extends StatefulWidget {
  final ServiceType initialType;
  const BookDeliveryScreen({super.key, this.initialType = ServiceType.pickup});

  @override
  State<BookDeliveryScreen> createState() => _BookDeliveryScreenState();
}

class _BookDeliveryScreenState extends State<BookDeliveryScreen> {
  final OrderService _orderService = OrderService();
  late ServiceType _selectedType;
  bool _isLoading = false;

  final TextEditingController _itemController = TextEditingController();
  final List<String> _itemList = [];

  final TextEditingController _pickupController = TextEditingController();
  final TextEditingController _dropoffController = TextEditingController();
  final TextEditingController _storeController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  // Bills fields
  final TextEditingController _billerController = TextEditingController();
  final TextEditingController _accountNameController = TextEditingController();
  final TextEditingController _accountNumberController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();

  static const Color primaryColor = Color(0xFF03A9F4);
  static const Color gradientStart = Color(0xFF81D4FA);
  static const Color gradientEnd = Color(0xFF0288D1);

  // Estimation variables
  double _distanceKm = 0.0;
  double _deliveryFee = 0.0;
  double _serviceFee = 0.0;
  bool _isEstimating = false;
  bool _showEstimation = false;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialType;
    
    // Add listeners to detect when locations are filled
    _pickupController.addListener(_onLocationChanged);
    _dropoffController.addListener(_onLocationChanged);
    _storeController.addListener(_onLocationChanged);
    
    // For bills, estimation is fixed or based on amount, so we can show it immediately if relevant
    if (_selectedType == ServiceType.bills) {
      _calculateFee();
      _showEstimation = true;
    }
  }

  @override
  void dispose() {
    _pickupController.dispose();
    _dropoffController.dispose();
    _storeController.dispose();
    _itemController.dispose();
    _descriptionController.dispose();
    _billerController.dispose();
    _accountNameController.dispose();
    _accountNumberController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _onLocationChanged() {
    bool hasBothLocations = false;

    if (_selectedType == ServiceType.pickup) {
      hasBothLocations = _pickupController.text.trim().length > 3 && 
                         _dropoffController.text.trim().length > 3;
    } else if (_selectedType == ServiceType.pabili || _selectedType == ServiceType.food) {
      hasBothLocations = _storeController.text.trim().length > 3 && 
                         _dropoffController.text.trim().length > 3;
    }

    if (hasBothLocations) {
      if (!_showEstimation && !_isEstimating) {
        _triggerEstimation();
      }
    } else {
      if (_showEstimation) {
        setState(() {
          _showEstimation = false;
        });
      }
    }
  }

  Future<void> _triggerEstimation() async {
    setState(() {
      _isEstimating = true;
    });

    // Simulate network delay for distance calculation (workable estimation)
    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;

    // Generate a distance based on the length of text to make it feel "workable"
    // In a real app, use Google Maps API or similar here.
    int lengthSum = 0;
    if (_selectedType == ServiceType.pickup) {
      lengthSum = _pickupController.text.length + _dropoffController.text.length;
    } else {
      lengthSum = _storeController.text.length + _dropoffController.text.length;
    }
    
    _distanceKm = (lengthSum % 10) + 1.5 + (Random().nextDouble() * 2);
    _calculateFee();

    setState(() {
      _isEstimating = false;
      _showEstimation = true;
    });
  }

  void _calculateFee() {
    double baseFee = 45.0;
    double perKm = 12.0;
    double perItem = 5.0;

    double deliveryFee = baseFee + (_distanceKm * perKm);
    double serviceFee = 15.0; // Fixed base service fee
    
    if (_selectedType == ServiceType.pabili || _selectedType == ServiceType.food) {
      deliveryFee += (_itemList.length * perItem);
      serviceFee = 25.0; // Higher service fee for shopping/food tasks
    } else if (_selectedType == ServiceType.bills) {
      deliveryFee = 35.0; // Flat fee for bills
      serviceFee = 10.0;
    }

    _deliveryFee = deliveryFee;
    _serviceFee = serviceFee;
  }

  void _addItem() {
    if (_itemController.text.isNotEmpty) {
      setState(() {
        _itemList.add(_itemController.text);
        _itemController.clear();
        _calculateFee();
      });
    }
  }

  void _removeItem(int index) {
    setState(() {
      _itemList.removeAt(index);
      _calculateFee();
    });
  }

  Future<void> _submitOrder() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Validation
    if (_selectedType == ServiceType.pickup) {
      if (_pickupController.text.isEmpty || _dropoffController.text.isEmpty) {
        _showError("Please provide both pickup and drop-off locations.");
        return;
      }
    } else if (_selectedType == ServiceType.pabili || _selectedType == ServiceType.food) {
      if (_storeController.text.isEmpty || _dropoffController.text.isEmpty) {
        _showError("Please provide both store and delivery locations.");
        return;
      }
      if (_itemList.isEmpty) {
        _showError("Please add at least one item.");
        return;
      }
    } else if (_selectedType == ServiceType.bills) {
      if (_billerController.text.isEmpty || _amountController.text.isEmpty) {
        _showError("Please fill in bill details.");
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      final order = OrderModel(
        customerId: user.uid,
        type: _selectedType.name,
        pickupLocation: _selectedType == ServiceType.pickup ? _pickupController.text : null,
        dropoffLocation: _selectedType == ServiceType.bills ? "N/A" : _dropoffController.text,
        packageDescription: _selectedType == ServiceType.pickup ? _descriptionController.text : null,
        items: (_selectedType == ServiceType.pabili || _selectedType == ServiceType.food) ? _itemList : null,
        status: 'pending',
        createdAt: DateTime.now(),
        storeName: (_selectedType == ServiceType.pabili || _selectedType == ServiceType.food) ? _storeController.text : null,
        billerName: _selectedType == ServiceType.bills ? _billerController.text : null,
        accountName: _selectedType == ServiceType.bills ? _accountNameController.text : null,
        accountNumber: _selectedType == ServiceType.bills ? _accountNumberController.text : null,
        amount: _selectedType == ServiceType.bills ? double.tryParse(_amountController.text) : 0.0,
        deliveryFee: _deliveryFee,
        serviceFee: _serviceFee,
        distanceKm: _distanceKm,
      );

      await _orderService.createOrder(order);

      if (!mounted) return;
      _showOrderConfirmationDialog(order);
      
    } catch (e) {
      if (mounted) _showError("Error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _showOrderConfirmationDialog(OrderModel order) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        title: const Column(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 60),
            SizedBox(height: 10),
            Text("Order Booked!", style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: Text(
                "Your request has been sent to nearby riders. Please wait while we find a rider for you.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ),
            const Divider(height: 30),
            _dialogRow("Service", _getServiceTitle()),
            if (order.storeName != null) _dialogRow("Store", order.storeName!),
            if (_selectedType != ServiceType.bills) _dialogRow("Est. Distance", "${order.distanceKm?.toStringAsFixed(1)} km"),
            _dialogRow("Delivery Fee", "₱${order.deliveryFee?.toStringAsFixed(2)}"),
            _dialogRow("Service Fee", "₱${order.serviceFee?.toStringAsFixed(2)}"),
            const Divider(),
            _dialogRow("Total Fees", "₱${((order.deliveryFee ?? 0) + (order.serviceFee ?? 0)).toStringAsFixed(2)}"),
            const SizedBox(height: 10),
            const Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              ),
              child: const Text("Go to Dashboard", style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dialogRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value, style: const TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 55, 20, 25),
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [gradientStart, gradientEnd]),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(40),
                bottomRight: Radius.circular(40),
              ),
            ),
            child: Row(
              children: [
                Container(
                  height: 42,
                  width: 42,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getServiceTitle(),
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const Text(
                        "Fill in the details below",
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading 
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
              padding: const EdgeInsets.all(22),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Order Information",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryColor.withOpacity(0.8)),
                        ),
                        const SizedBox(height: 20),
                        ..._getFormContent(),
                        
                        if (_isEstimating)
                          const Padding(
                            padding: EdgeInsets.only(top: 20),
                            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                          ),

                        if (_showEstimation)
                          Column(
                            children: [
                              const Divider(height: 40),
                              _buildEstimationSummary(),
                            ],
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _submitOrder,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      ),
                      child: const Text(
                        "Confirm & Book Now",
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEstimationSummary() {
    return Column(
      children: [
        if (_selectedType != ServiceType.bills)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Est. Distance", style: TextStyle(color: Colors.grey)),
              Text("${_distanceKm.toStringAsFixed(1)} km", style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Delivery Fee", style: TextStyle(color: Colors.grey)),
            Text("₱${_deliveryFee.toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Service Fee", style: TextStyle(color: Colors.grey)),
            Text("₱${_serviceFee.toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        const Divider(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Estimated Total Fees", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text("₱${(_deliveryFee + _serviceFee).toStringAsFixed(2)}", 
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryColor)),
          ],
        ),
        const SizedBox(height: 5),
        const Text("*Item prices are not yet included and will be updated by rider.", 
          style: TextStyle(fontSize: 10, color: Colors.grey, fontStyle: FontStyle.italic)),
      ],
    );
  }

  String _getServiceTitle() {
    switch (_selectedType) {
      case ServiceType.pickup: return "Delivery Request";
      case ServiceType.pabili: return "Pabili Service";
      case ServiceType.food: return "Food Delivery";
      case ServiceType.bills: return "Bills Payment";
    }
  }

  List<Widget> _getFormContent() {
    switch (_selectedType) {
      case ServiceType.pickup:
        return [
          _buildTextField(_pickupController, "Pickup Location", Icons.location_on),
          const SizedBox(height: 15),
          _buildTextField(_dropoffController, "Drop-off Location", Icons.location_searching),
          const SizedBox(height: 15),
          _buildTextField(_descriptionController, "Package Description", Icons.inventory_2),
        ];
      case ServiceType.pabili:
      case ServiceType.food:
        String storeLabel = _selectedType == ServiceType.pabili ? "Store / Market Name" : "Restaurant Name";
        return [
          _buildTextField(_storeController, storeLabel, Icons.storefront),
          const SizedBox(height: 15),
          _buildTextField(_dropoffController, "Your Delivery Address", Icons.home),
          const SizedBox(height: 25),
          const Text("Items List", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primaryColor)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _itemController,
                  decoration: InputDecoration(
                    hintText: "Enter item",
                    filled: true,
                    fillColor: const Color(0xFFF3F4F6),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: _addItem,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green, 
                  foregroundColor: Colors.white, 
                  padding: const EdgeInsets.all(15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                child: const Icon(Icons.add),
              ),
            ],
          ),
          const SizedBox(height: 15),
          _buildItemsList(),
        ];
      case ServiceType.bills:
        return [
          _buildTextField(_billerController, "Biller Name (e.g. Meralco)", Icons.receipt_long),
          const SizedBox(height: 15),
          _buildTextField(_accountNameController, "Account Name", Icons.person),
          const SizedBox(height: 15),
          _buildTextField(_accountNumberController, "Account Number", Icons.numbers),
          const SizedBox(height: 15),
          _buildTextField(_amountController, "Amount to Pay", Icons.attach_money, keyboardType: TextInputType.number),
        ];
    }
  }

  Widget _buildItemsList() {
    if (_itemList.isEmpty) {
      return const Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Center(child: Text("No items added yet.", style: TextStyle(color: Colors.grey))));
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _itemList.length,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            title: Text(_itemList[index], style: const TextStyle(fontWeight: FontWeight.w500)),
            trailing: IconButton(icon: const Icon(Icons.remove_circle_outline, color: Colors.red), onPressed: () => _removeItem(index)),
          ),
        );
      },
    );
  }

  Widget _buildTextField(TextEditingController? controller, String label, IconData icon, {TextInputType? keyboardType}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      onChanged: (val) {
        // This can also trigger distance estimation if needed, 
        // but listeners in initState are more robust for this setup.
      },
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: primaryColor),
        filled: true,
        fillColor: const Color(0xFFF3F4F6),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: const BorderSide(color: primaryColor, width: 1)),
      ),
    );
  }
}
