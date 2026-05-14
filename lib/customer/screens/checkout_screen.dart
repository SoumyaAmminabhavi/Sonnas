import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/cart_provider.dart';
import 'payment_screen.dart';

import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class CustomerCheckoutScreen extends StatefulWidget {
  final bool isSelfCheckout;
  const CustomerCheckoutScreen({super.key, this.isSelfCheckout = false});

  @override
  State<CustomerCheckoutScreen> createState() => _CustomerCheckoutScreenState();
}

class _CustomerCheckoutScreenState extends State<CustomerCheckoutScreen> {
  String selectedPayment = "UPI";
  DateTime? selectedDate;
  String? selectedTimeSlot;
  bool _isGettingLocation = false;
  LatLng _currentLatLng = const LatLng(12.9716, 77.5946); // Default to Bangalore
  final MapController _mapController = MapController();

  static const primary = Color(0xFFC2185B);
  static const background = Color(0xFFFFF0F5);
  static const berryText = Color(0xFF4A152C);

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();

  Future<void> _getCurrentLocation() async {
    setState(() => _isGettingLocation = true);
    try {
      bool serviceEnabled;
      LocationPermission permission;

      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw 'Location services are disabled.';
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw 'Location permissions are denied';
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        throw 'Location permissions are permanently denied';
      }

      final Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );

      String? finalAddress;

      // Geocoding package doesn't always work well on Web
      if (kIsWeb) {
        // Use Nominatim (OpenStreetMap) for Web reverse geocoding
        final url = Uri.parse('https://nominatim.openstreetmap.org/reverse?format=json&lat=${position.latitude}&lon=${position.longitude}');
        final response = await http.get(url, headers: {'User-Agent': 'SonnaPatisserieApp'});
        
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          finalAddress = data['display_name'];
        }
      } else {
        // Native platforms can use the geocoding package
        try {
          final List<Placemark> placemarks = await placemarkFromCoordinates(
            position.latitude,
            position.longitude,
          );

          if (placemarks.isNotEmpty) {
            final Placemark place = placemarks[0];
            finalAddress = "${place.street}, ${place.subLocality}, ${place.locality}, ${place.postalCode}";
          }
        } catch (e) {
          // Fallback to coordinates if geocoding fails
          finalAddress = "Lat: ${position.latitude}, Lon: ${position.longitude}";
        }
      }

      if (finalAddress != null) {
        setState(() {
          _addressController.text = finalAddress!;
          _currentLatLng = LatLng(position.latitude, position.longitude);
        });
        _mapController.move(_currentLatLng, 15);
      } else {
        setState(() {
          _addressController.text = "Lat: ${position.latitude}, Lon: ${position.longitude}";
          _currentLatLng = LatLng(position.latitude, position.longitude);
        });
        _mapController.move(_currentLatLng, 15);
      }
    } catch (e) {
      debugPrint("Location Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error getting location: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _isGettingLocation = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: berryText), onPressed: () => Navigator.pop(context)),
        title: Text("Checkout", style: GoogleFonts.dmSerifDisplay(color: berryText)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle("DELIVERY DETAILS"),
            const SizedBox(height: 16),
            _buildTextField("Recipient Name", Icons.person_outline, controller: _nameController),
            const SizedBox(height: 12),
            _buildTextField("Contact Number", Icons.phone_outlined, controller: _phoneController, keyboardType: TextInputType.phone, inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)]),
            const SizedBox(height: 12),
            _buildMapView(),
            const SizedBox(height: 12),
            _buildAddressField(),
            const SizedBox(height: 12),
            _buildTextField("Special Instructions (Notes)", Icons.note_add_outlined, controller: _notesController, maxLines: 2),
            
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(child: _buildDatePicker(context)),
                const SizedBox(width: 12),
                Expanded(child: _buildTimePicker()),
              ],
            ),

            const SizedBox(height: 40),
            _sectionTitle("PAYMENT METHOD"),
            const SizedBox(height: 16),
            _buildPaymentOption("UPI", "Instant, secure transfer", Icons.vibration),
            _buildPaymentOption("Credit/Debit Card", "Mastercard, Visa, RuPay", Icons.credit_card),
            _buildPaymentOption("Cash on Delivery", "Pay when you receive", Icons.payments_outlined),

            const SizedBox(height: 40),
            _sectionTitle("ORDER SUMMARY"),
            const SizedBox(height: 16),
            Builder(builder: (context) {
              final int subtotalCents = cart.total.round();
              final int packagingCents = widget.isSelfCheckout ? 0 : 15000;
              final int taxCents = ((subtotalCents * 5) + 50) ~/ 100;
              final int grandTotalCents = subtotalCents + packagingCents + taxCents;

              return Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [BoxShadow(color: primary.withOpacity(0.08), blurRadius: 40, offset: const Offset(0, 20))],
                ),
                child: Column(
                  children: [
                    _summaryRow("Bag Total", "₹${(subtotalCents / 100).toStringAsFixed(2)}"),
                    _summaryRow("Delivery", "₹${(packagingCents / 100).toStringAsFixed(2)}"),
                    _summaryRow("Taxes (5%)", "₹${(taxCents / 100).toStringAsFixed(2)}"),
                    const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider(height: 1, thickness: 0.5)),
                    _summaryRow("Grand Total", "₹${(grandTotalCents / 100).toStringAsFixed(2)}", isTotal: true),
                  ],
                ),
              );
            }),

            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  final trimmedName = _nameController.text.trim();
                  final trimmedPhone = _phoneController.text.replaceAll(RegExp(r'\D'), '');
                  final trimmedAddress = _addressController.text.trim();
                  
                  if (trimmedName.isEmpty || trimmedPhone.length < 10 || trimmedAddress.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Please provide valid name, phone, and address")),
                    );
                    return;
                  }
                  
                  final addressLower = trimmedAddress.toLowerCase();
                  const allowedCities = ['hubli', 'hubballi', 'dharwad'];
                  final isServiceable = allowedCities.any((city) => addressLower.contains(city));

                  if (!isServiceable) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("In your city it is not available. We currently serve Hubli-Dharwad only."),
                        backgroundColor: Colors.red,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                    return;
                  }
                  
                  final supabase = Supabase.instance.client;
                  final user = supabase.auth.currentUser;

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PaymentScreen(
                        customerName: trimmedName,
                        phone: trimmedPhone,
                        address: trimmedAddress,
                        deliveryDate: selectedDate?.toIso8601String(),
                        deliveryTime: selectedTimeSlot,
                        notes: _notesController.text,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                ),
                child: const Text("PLACE ORDER", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5)),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(title, style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5, color: const Color(0xFF4A152C).withOpacity(0.5)));
  }

  Widget _buildTextField(String hint, IconData icon, {int maxLines = 1, TextEditingController? controller, TextInputType? keyboardType, List<TextInputFormatter>? inputFormatters}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 14, color: Colors.grey),
        prefixIcon: Icon(icon, size: 20, color: const Color(0xFFC2185B)),
        filled: true,
        fillColor: Colors.white,
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: const Color(0xFFC2185B).withOpacity(0.05))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFC2185B))),
      ),
    );
  }

  Widget _buildMapView() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFC2185B).withOpacity(0.1)),
      ),
      clipBehavior: Clip.antiAlias,
      child: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: _currentLatLng,
          initialZoom: 13,
          onTap: (tapPosition, latLng) {
            setState(() {
              _currentLatLng = latLng;
            });
            _reverseGeocode(latLng);
          },
        ),
        children: [
          TileLayer(
            urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
            userAgentPackageName: 'com.sonnas.patisserie',
          ),
          MarkerLayer(
            markers: [
              Marker(
                point: _currentLatLng,
                width: 40,
                height: 40,
                child: const Icon(Icons.location_on, color: Color(0xFFC2185B), size: 40),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _reverseGeocode(LatLng latLng) async {
    setState(() => _isGettingLocation = true);
    try {
      String? finalAddress;
      if (kIsWeb) {
        final url = Uri.parse('https://nominatim.openstreetmap.org/reverse?format=json&lat=${latLng.latitude}&lon=${latLng.longitude}');
        final response = await http.get(url, headers: {'User-Agent': 'SonnaPatisserieApp'});
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          finalAddress = data['display_name'];
        }
      } else {
        try {
          final List<Placemark> placemarks = await placemarkFromCoordinates(latLng.latitude, latLng.longitude);
          if (placemarks.isNotEmpty) {
            final Placemark place = placemarks[0];
            finalAddress = "${place.street}, ${place.subLocality}, ${place.locality}, ${place.postalCode}";
          }
        } catch (e) {
          finalAddress = "Lat: ${latLng.latitude.toStringAsFixed(4)}, Lon: ${latLng.longitude.toStringAsFixed(4)}";
        }
      }

      if (finalAddress != null) {
        setState(() {
          _addressController.text = finalAddress!;
        });
      }
    } catch (e) {
      debugPrint("Reverse Geocoding Error: $e");
    } finally {
      if (mounted) setState(() => _isGettingLocation = false);
    }
  }

  Widget _buildAddressField() {
    return TextField(
      controller: _addressController,
      maxLines: null, // Allow expanding for long addresses
      minLines: 2,
      style: const TextStyle(fontSize: 13, height: 1.4),
      decoration: InputDecoration(
        hintText: "Full Delivery Address",
        hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
        prefixIcon: const Icon(Icons.location_on_outlined, size: 20, color: Color(0xFFC2185B)),
        suffixIcon: Padding(
          padding: const EdgeInsets.only(right: 8),
          child: _isGettingLocation 
            ? const UnconstrainedBox(child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFC2185B))))
            : IconButton(
                icon: const Icon(Icons.my_location, size: 20, color: Color(0xFFC2185B)),
                onPressed: _getCurrentLocation,
                tooltip: "Get Current Location",
              ),
        ),
        filled: true,
        fillColor: Colors.white,
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: const Color(0xFFC2185B).withOpacity(0.05))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFC2185B))),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  Widget _buildDatePicker(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final DateTime? picked = await showDatePicker(context: context, initialDate: DateTime.now().add(const Duration(days: 1)), firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 30)));
        if (picked != null) setState(() => selectedDate = picked);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFC2185B).withOpacity(0.05))),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_outlined, size: 18, color: Color(0xFFC2185B)),
            const SizedBox(width: 12),
            Text(selectedDate == null ? "Date" : "${selectedDate!.day}/${selectedDate!.month}", style: const TextStyle(fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _buildTimePicker() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFC2185B).withOpacity(0.05))),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          hint: const Text("Time", style: TextStyle(fontSize: 14)),
          isExpanded: true,
          value: selectedTimeSlot,
          items: ["12 PM - 03 PM", "03 PM - 06 PM", "06 PM - 09 PM"].map((String value) {
            return DropdownMenuItem<String>(value: value, child: Text(value, style: const TextStyle(fontSize: 12)));
          }).toList(),
          onChanged: (val) => setState(() => selectedTimeSlot = val),
        ),
      ),
    );
  }

  Widget _buildPaymentOption(String title, String subtitle, IconData icon) {
    final isSelected = selectedPayment == title;
    const primary = Color(0xFFC2185B);
    return GestureDetector(
      onTap: () => setState(() => selectedPayment = title),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? primary : primary.withOpacity(0.05)),
          boxShadow: isSelected ? [BoxShadow(color: primary.withOpacity(0.05), blurRadius: 10)] : null,
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? primary : Colors.grey),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              ),
            ),
            Icon(isSelected ? Icons.radio_button_checked : Icons.radio_button_off, color: isSelected ? primary : Colors.grey, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: isTotal ? Colors.black : Colors.grey, fontSize: isTotal ? 14 : 13, fontWeight: isTotal ? FontWeight.bold : FontWeight.normal)),
          Text(value, style: TextStyle(fontWeight: FontWeight.w600, fontSize: isTotal ? 16 : 13, color: isTotal ? primary : Colors.black)),
        ],
      ),
    );
  }
}

class SuccessScreen extends StatelessWidget {
  const SuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFFC2185B);
    const background = Color(0xFFFFF0F5);
    const berryText = Color(0xFF4A152C);

    return Scaffold(
      backgroundColor: background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: primary.withOpacity(0.1), blurRadius: 40)]),
                child: const Icon(Icons.check_circle, size: 80, color: Colors.green),
              ),
              const SizedBox(height: 40),
              Text("Order Placed!", style: GoogleFonts.dmSerifDisplay(fontSize: 36, color: berryText)),
              const SizedBox(height: 12),
              const Text("Your sweet delight is being prepared\nby our master artisans.", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, height: 1.5)),
              const SizedBox(height: 48),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: primary.withOpacity(0.05))),
                child: Column(
                  children: [
                    const Text("ORDER ID", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2, color: Colors.grey)),
                    const SizedBox(height: 8),
                    Text("#SN-2024-089", style: GoogleFonts.dmSerifDisplay(fontSize: 20, color: berryText)),
                  ],
                ),
              ),
              const SizedBox(height: 64),
              ElevatedButton(
                onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                ),
                child: const Text("TRACK ORDER", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 16),
              TextButton(onPressed: () => Navigator.popUntil(context, (route) => route.isFirst), child: Text("VIEW ALL ORDERS", style: TextStyle(color: primary.withOpacity(0.6), fontWeight: FontWeight.bold))),
            ],
          ),
        ),
      ),
    );
  }
}
