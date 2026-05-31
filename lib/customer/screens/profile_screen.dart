import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import '../providers/favorites_provider.dart';
import 'product_detail_screen.dart';
import 'contact_screen.dart';
import 'welcome_screen.dart';
import 'auth_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isEditing = false;
  bool _isLoading = true;
  bool _isLocalGuestLoggedIn = false;

  final TextEditingController _nameController = TextEditingController(text: "Sonnas Cafe");
  final TextEditingController _emailController = TextEditingController(text: "soonas@gmail.com");
  final TextEditingController _phoneController = TextEditingController(text: "09113231424");
  final TextEditingController _addressController = TextEditingController(text: "4TH Phase, Shop No. 5,6,7 Ground Floor, \"Aum Shree\" Commercial & Residential Apartment Plot No-25, Akshay Colony, Unkal, Village, Karnataka 580021");

  String _avatarUrl = "https://images.unsplash.com/photo-1576618148400-f54bed99fcfd?w=120&h=120&fit=crop";
  List<String> _savedAddresses = [];
  String _defaultAddress = "";

  bool _notifOrderTracking = true;
  bool _notifStockAlerts = true;
  bool _notifSpecialOffers = false;

  int _totalOrders = 0;
  double _totalSpent = 0.0;
  String _loyaltyLevel = "Bronze Gourmet";
  Stream<List<Map<String, dynamic>>>? _orderStream;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool('is_guest_logged_in') ?? false;
      final guestName = prefs.getString('guest_name') ?? "Guest";
      final guestPhone = prefs.getString('guest_phone') ?? "";
      final guestEmail = prefs.getString('guest_email') ?? "";

      setState(() {
        _isLocalGuestLoggedIn = isLoggedIn;
        if (guestPhone.isNotEmpty) _phoneController.text = guestPhone;
        if (guestEmail.isNotEmpty) _emailController.text = guestEmail;
        if (guestName != "Guest") _nameController.text = guestName;
      });
      
      // Load all other offline/online details concurrently!
      await _loadAvatar();
      await _loadSavedAddresses();
      await _loadNotificationPrefs();
      try {
        await _fetchOrderStats();
      } catch (e) {
        debugPrint("Failed to fetch order stats: $e");
      }
      
      if (mounted) {
        setState(() {
          _initOrderStream();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadAvatar() async {
    final prefs = await SharedPreferences.getInstance();
    final user = Supabase.instance.client.auth.currentUser;
    final metadata = user?.userMetadata ?? {};
    final cloudAvatar = metadata['avatar_url']?.toString();
    
    if (mounted) {
      setState(() {
        _avatarUrl = prefs.getString('avatar_url') ?? cloudAvatar ?? "https://images.unsplash.com/photo-1576618148400-f54bed99fcfd?w=120&h=120&fit=crop";
      });
    }
  }

  Future<void> _updateAvatar(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('avatar_url', url);
    setState(() {
      _avatarUrl = url;
    });
    
    try {
      final supabase = Supabase.instance.client;
      if (supabase.auth.currentUser != null) {
        await supabase.auth.updateUser(
          UserAttributes(
            data: {
              'avatar_url': url,
            },
          ),
        );
      }
    } catch (e) {
      debugPrint("Failed to sync avatar with cloud: $e");
    }
  }

  Future<void> _loadSavedAddresses() async {
    final prefs = await SharedPreferences.getInstance();
    final user = Supabase.instance.client.auth.currentUser;
    final metadata = user?.userMetadata ?? {};
    final cloudAddress = metadata['default_address']?.toString();
    
    final addressJson = prefs.getString('saved_addresses');
    final defAddr = prefs.getString('default_address') ?? cloudAddress ?? _addressController.text;
    
    if (mounted) {
      setState(() {
        if (addressJson != null) {
          final List<dynamic> decoded = jsonDecode(addressJson);
          _savedAddresses = decoded.map((e) => e.toString()).toList();
        } else if (cloudAddress != null && cloudAddress.isNotEmpty) {
          _savedAddresses = [cloudAddress];
        } else {
          _savedAddresses = [
            "4TH Phase, Shop No. 5,6,7 Ground Floor, \"Aum Shree\" Commercial & Residential Apartment Plot No-25, Akshay Colony, Unkal, Village, Karnataka 580021"
          ];
        }
        _defaultAddress = defAddr;
        if (_defaultAddress.isNotEmpty) {
          _addressController.text = _defaultAddress;
        }
      });
    }
  }

  Future<void> _saveAddressesToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('saved_addresses', jsonEncode(_savedAddresses));
    await prefs.setString('default_address', _defaultAddress);
  }

  Future<void> _loadNotificationPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _notifOrderTracking = prefs.getBool('notif_order_tracking') ?? true;
        _notifStockAlerts = prefs.getBool('notif_stock_alerts') ?? true;
        _notifSpecialOffers = prefs.getBool('notif_special_offers') ?? false;
      });
    }
  }

  Future<void> _saveNotificationPref(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  Future<void> _fetchOrderStats() async {
    try {
      final supabase = Supabase.instance.client;
      final rawPhone = _phoneController.text.replaceAll(RegExp(r'\D'), '');

      final userPhone = rawPhone.length > 10
          ? rawPhone.substring(rawPhone.length - 10)
          : rawPhone;

      final userEmail = _emailController.text.trim();

      var query = supabase
          .from('Order')
          .select('totalPrice');

      List<String> filters = [];
      if (userEmail.isNotEmpty) {
        filters.add('customerEmail.eq.$userEmail');
      }
      if (userPhone.isNotEmpty) {
        filters.add('customerPhone.eq.$userPhone');
        filters.add('customerPhone.eq.91$userPhone');
        filters.add('customerPhone.eq.+91$userPhone');
        filters.add('whatsappPhone.eq.$userPhone');
        filters.add('whatsappPhone.eq.91$userPhone');
        filters.add('whatsappPhone.eq.+91$userPhone');
      }

      if (filters.isEmpty) {
        return;
      }

      query = query.or(filters.join(','));

      final data = await query;

      double spentSum = 0;
      for (var row in data) {
        final price = double.tryParse(row['totalPrice']?.toString() ?? '0') ?? 0.0;
        spentSum += price;
      }

      final count = data.length;
      final spentRupees = spentSum / 100.0;

      String level = "Bronze Gourmet \u{1F370}";
      if (count >= 6) {
        level = "Gold Patissier \u{1F451}";
      } else if (count >= 3) {
        level = "Silver Connoisseur \u2728";
      }

      if (mounted) {
        setState(() {
          _totalOrders = count;
          _totalSpent = spentRupees;
          _loyaltyLevel = level;
        });
      }
    } catch (e) {
      debugPrint("Error fetching profile order stats: $e");
    }
  }

  void _initOrderStream() {
    final rawPhone = _phoneController.text.replaceAll(RegExp(r'\D'), '');
    final cleanPhone = rawPhone.length > 10 
        ? rawPhone.substring(rawPhone.length - 10) 
        : rawPhone;
    final email = _emailController.text.trim();
    final client = Supabase.instance.client;

    final streams = <Stream<List<Map<String, dynamic>>>>[];

    if (cleanPhone.isNotEmpty) {
      streams.add(client
          .from('Order')
          .stream(primaryKey: ['id'])
          .eq('customerPhone', cleanPhone)
          .limit(1));
      streams.add(client
          .from('Order')
          .stream(primaryKey: ['id'])
          .eq('customerPhone', '91$cleanPhone')
          .limit(1));
      streams.add(client
          .from('Order')
          .stream(primaryKey: ['id'])
          .eq('customerPhone', '+91$cleanPhone')
          .limit(1));
      streams.add(client
          .from('Order')
          .stream(primaryKey: ['id'])
          .eq('whatsappPhone', cleanPhone)
          .limit(1));
      streams.add(client
          .from('Order')
          .stream(primaryKey: ['id'])
          .eq('whatsappPhone', '91$cleanPhone')
          .limit(1));
      streams.add(client
          .from('Order')
          .stream(primaryKey: ['id'])
          .eq('whatsappPhone', '+91$cleanPhone')
          .limit(1));
    }
    if (email.isNotEmpty) {
      streams.add(client
          .from('Order')
          .stream(primaryKey: ['id'])
          .eq('customerEmail', email)
          .limit(1));
    }

    if (streams.isEmpty) {
      _orderStream = const Stream<List<Map<String, dynamic>>>.empty();
    } else if (streams.length == 1) {
      _orderStream = streams.first;
    } else {
      _orderStream = _mergeOrderStreamsList(streams);
    }
  }



  Future<void> _saveProfile() async {
    setState(() => _isLoading = true);
    try {
      final name = _nameController.text.trim();
      final phone = _phoneController.text.trim();
      final address = _addressController.text.trim();

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('guest_name', name);
      await prefs.setString('guest_phone', phone);
      await prefs.setString('default_address', address);
      
      try {
        final supabase = Supabase.instance.client;
        if (supabase.auth.currentUser != null) {
          await supabase.auth.updateUser(
            UserAttributes(
              data: {
                'full_name': name,
                'phone': phone,
                'default_address': address,
              },
            ),
          );
        }
      } catch (e) {
        debugPrint("Could not update cloud user: $e");
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Profile updated successfully"),
            backgroundColor: Color(0xFFFF4D8D),
            behavior: SnackBarBehavior.floating,
          ),
        );
        setState(() {
          _initOrderStream();
          _isEditing = false;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Profile update error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Error updating profile. Please try again later."),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildGuestView() {
    const Color primary = Color(0xFFFF4D8D);
    const Color background = Color(0xFFFFF0F6);
    const Color onSurface = Color(0xFF701235);
    const Color secondary = Color(0xFF701235);

    return Scaffold(
      backgroundColor: background,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: primary.withValues(alpha: 0.1),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    )
                  ],
                ),
                child: const Icon(
                  Icons.person_outline_rounded,
                  size: 80,
                  color: primary,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                "Welcome to Sonna's!",
                style: GoogleFonts.notoSerif(
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                  color: onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                "Sign in to track your orders, manage saved addresses, and view your loyalty rewards.",
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  color: secondary.withValues(alpha: 0.6),
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AuthScreen(
                          isOwner: false,
                          onSuccess: () {
                            Navigator.pop(context);
                            _fetchUserData();
                          },
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                    elevation: 5,
                    shadowColor: primary.withValues(alpha: 0.3),
                  ),
                  child: Text(
                    "SIGN IN OR REGISTER",
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Stream<List<Map<String, dynamic>>> _mergeOrderStreamsList(
      List<Stream<List<Map<String, dynamic>>>> streams) {
    final controller = StreamController<List<Map<String, dynamic>>>();
    final subscriptions = <StreamSubscription>[];
    final lastData = List<List<Map<String, dynamic>>>.generate(streams.length, (_) => []);

    void emitCombined() {
      final combined = <Map<String, dynamic>>[];
      for (var list in lastData) {
        combined.addAll(list);
      }
      combined.sort((a, b) {
        final aTime = DateTime.tryParse(a['createdAt']?.toString() ?? '') ?? DateTime(1970);
        final bTime = DateTime.tryParse(b['createdAt']?.toString() ?? '') ?? DateTime(1970);
        return bTime.compareTo(aTime);
      });
      final seen = <String>{};
      final unique = combined.where((order) {
        final id = order['id']?.toString() ?? '';
        return seen.add(id);
      }).toList();
      if (!controller.isClosed) {
        controller.add(unique);
      }
    }

    controller.onListen = () {
      for (int i = 0; i < streams.length; i++) {
        final sub = streams[i].listen((data) {
          lastData[i] = data;
          emitCombined();
        }, onError: controller.addError);
        subscriptions.add(sub);
      }
    };

    controller.onCancel = () {
      for (var sub in subscriptions) {
        sub.cancel();
      }
      controller.close();
    };

    return controller.stream;
  }

  @override
  Widget build(BuildContext context) {
    const Color primary = Color(0xFFFF4D8D);
    const Color background = Color(0xFFFFF0F6);
    const Color onSurface = Color(0xFF701235);
    const Color secondary = Color(0xFF701235);
    const Color primaryContainer = Color(0xFFFFB6D3);
    const Color surfaceContainerHigh = Color(0xFFFFDCC5);
    const Color outline = Color(0xFF867277);

    final currentUser = Supabase.instance.client.auth.currentUser;
    if (!_isLocalGuestLoggedIn && currentUser == null) {
      return _buildGuestView();
    }

    if (_isLoading) {
      return const Scaffold(
        backgroundColor: background,
        body: Center(child: CircularProgressIndicator(color: primary)),
      );
    }

    return Scaffold(
      backgroundColor: background,
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 100),
            // Profile Header
            Center(
              child: Column(
                children: [
                  InkWell(
                    onTap: _showAvatarSelector,
                    borderRadius: BorderRadius.circular(56),
                    child: Stack(
                      children: [
                        Container(
                          width: 112,
                          height: 112,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: surfaceContainerHigh, width: 4),
                            boxShadow: [
                              BoxShadow(
                                color: secondary.withValues(alpha: 0.1),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(56),
                            child: Image.network(
                              _avatarUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => Container(
                                color: primary.withValues(alpha: 0.1),
                                child: const Icon(Icons.person, color: primary, size: 40),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: primary,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(Icons.edit_rounded, size: 14, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    _nameController.text,
                    style: GoogleFonts.notoSerif(
                      fontSize: 32,
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w400,
                      color: onSurface,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Loyalty Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: primary.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.emoji_events_rounded, color: primary, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          _loyaltyLevel.toUpperCase(),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.5,
                            color: secondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Stats Summary Cards
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildStatItem(
                            "Total Orders", 
                            "$_totalOrders", 
                            Icons.local_mall_rounded, 
                            primary,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildStatItem(
                            "Total Spent", 
                            "\u20B9${_totalSpent.toStringAsFixed(0)}", 
                            Icons.account_balance_wallet_rounded, 
                            Colors.orange.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(24, 48, 24, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Personal Information
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Personal Information",
                        style: GoogleFonts.notoSerif(
                          fontSize: 20,
                          color: onSurface,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          if (_isEditing) {
                            _saveProfile();
                          } else {
                            setState(() => _isEditing = true);
                          }
                        },
                        child: Text(
                          _isEditing ? "SAVE CHANGES" : "EDIT DETAILS",
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1,
                            color: primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: secondary.withValues(alpha: 0.06),
                          blurRadius: 40,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildEditableInfoItem("FULL NAME", _nameController, outline, onSurface),
                        const SizedBox(height: 24),
                        _buildEditableInfoItem("EMAIL ADDRESS", _emailController, outline, onSurface, isEnabled: false),
                        const SizedBox(height: 24),
                        _buildEditableInfoItem("PHONE NUMBER", _phoneController, outline, onSurface),
                        const SizedBox(height: 24),
                        _buildEditableInfoItem("DEFAULT DELIVERY", _addressController, outline, onSurface, maxLines: 2),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),
                  
                  // My Wishlist Section
                  Consumer<FavoritesProvider>(
                    builder: (context, favorites, _) {
                      if (favorites.favorites.isEmpty) return const SizedBox.shrink();
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "MY WISHLIST",
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 2,
                                  color: primary,
                                ),
                              ),
                              Text(
                                "${favorites.favorites.length} ITEMS",
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: secondary.withValues(alpha: 0.4),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 140,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: favorites.favorites.length,
                              itemBuilder: (context, index) {
                                final item = favorites.favorites[index];
                                return Container(
                                  width: 100,
                                  margin: const EdgeInsets.only(right: 16),
                                  child: InkWell(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => ProductDetailScreen(
                                            title: item['title'],
                                            price: item['price'],
                                            imageUrl: item['image'],
                                          ),
                                        ),
                                      );
                                    },
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(12),
                                          child: Image.network(
                                            item['image'],
                                            height: 100,
                                            width: 100,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, _, _) => Container(
                                              height: 100,
                                              width: 100,
                                              color: primary.withValues(alpha: 0.05),
                                              child: const Icon(Icons.cake, color: primary),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          item['title'],
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: secondary,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 32),
                        ],
                      );
                    },
                  ),

                  // Recent Activity
                  Text(
                    "Recent Activity",
                    style: GoogleFonts.notoSerif(
                      fontSize: 20,
                      color: onSurface,
                    ),
                  ),
                  const SizedBox(height: 24),
                  StreamBuilder<List<Map<String, dynamic>>>(
                    key: Key("${_phoneController.text}_${_emailController.text}_${_nameController.text}"),
                    stream: _orderStream,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      
                      final data = snapshot.data ?? [];
                      if (data.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            child: Text(
                              "No recent activity found",
                              style: GoogleFonts.plusJakartaSans(
                                color: outline.withValues(alpha: 0.5),
                                fontSize: 14,
                              ),
                            ),
                          ),
                        );
                      }

                      final latestOrder = data.first;
                      final String status = latestOrder['status'] ?? 'PENDING';
                      final String rawPrice = latestOrder['totalPrice']?.toString() ?? '0';
                      final double priceVal = (double.tryParse(rawPrice) ?? 0.0) / 100.0;
                      
                      return _buildActivityItem(
                        "${latestOrder['customerName']?.toString().split(' ').first}'s Selection",
                        "\u20B9${priceVal.toStringAsFixed(2)}",
                        "ORDER #${latestOrder['orderNumber']?.toString().split('-').last ?? '...'}",
                        status.toUpperCase(),
                        latestOrder['customImageUrl'] ?? "https://images.unsplash.com/photo-1578985545062-69928b1d9587?q=80&w=3578&auto=format&fit=crop",
                        primary, outline, onSurface, surfaceContainerHigh
                      );
                    },
                  ),


                  const SizedBox(height: 32),
                  // Saved Addresses Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Saved Addresses",
                        style: GoogleFonts.notoSerif(
                          fontSize: 20,
                          color: onSurface,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _addNewAddressDialog,
                        icon: const Icon(Icons.add_rounded, size: 16, color: primary),
                        label: Text(
                          "ADD NEW",
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1,
                            color: primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_savedAddresses.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: secondary.withValues(alpha: 0.05)),
                      ),
                      child: Center(
                        child: Text(
                          "No saved addresses yet.",
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: secondary.withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _savedAddresses.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final addr = _savedAddresses[index];
                        final isDefault = addr == _defaultAddress;
                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isDefault ? primary : secondary.withValues(alpha: 0.05),
                              width: isDefault ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                isDefault ? Icons.stars_rounded : Icons.location_on_rounded,
                                color: isDefault ? primary : secondary.withValues(alpha: 0.4),
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (isDefault)
                                      Padding(
                                        padding: const EdgeInsets.only(bottom: 4),
                                        child: Text(
                                          "DEFAULT ADDRESS",
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 8,
                                            fontWeight: FontWeight.w800,
                                            color: primary,
                                            letterSpacing: 1,
                                          ),
                                        ),
                                      ),
                                    Text(
                                      addr,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 12,
                                        height: 1.5,
                                        fontWeight: FontWeight.w600,
                                        color: secondary.withValues(alpha: 0.8),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        if (!isDefault)
                                          TextButton(
                                            onPressed: () {
                                              setState(() {
                                                _defaultAddress = addr;
                                                _addressController.text = addr;
                                              });
                                              unawaited(_saveAddressesToPrefs());
                                            },
                                            style: TextButton.styleFrom(
                                              padding: EdgeInsets.zero,
                                              minimumSize: Size.zero,
                                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                            ),
                                            child: Text(
                                              "SET AS DEFAULT",
                                              style: GoogleFonts.plusJakartaSans(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: primary,
                                              ),
                                            ),
                                          ),
                                        if (!isDefault) const SizedBox(width: 16),
                                        TextButton(
                                          onPressed: () {
                                            setState(() {
                                              _savedAddresses.removeAt(index);
                                              if (isDefault && _savedAddresses.isNotEmpty) {
                                                _defaultAddress = _savedAddresses.first;
                                                _addressController.text = _savedAddresses.first;
                                              }
                                            });
                                            unawaited(_saveAddressesToPrefs());
                                          },
                                          style: TextButton.styleFrom(
                                            padding: EdgeInsets.zero,
                                            minimumSize: Size.zero,
                                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                          ),
                                          child: Text(
                                            "DELETE",
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.red.shade700,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),

                  const SizedBox(height: 32),
                  // Notification Settings Section
                  Text(
                    "Notification Preferences",
                    style: GoogleFonts.notoSerif(
                      fontSize: 20,
                      color: onSurface,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: secondary.withValues(alpha: 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      border: Border.all(color: secondary.withValues(alpha: 0.05)),
                    ),
                    child: Column(
                      children: [
                        _buildSwitchTile(
                          "Order Status Tracking",
                          "Realtime alerts when your cake status changes",
                          _notifOrderTracking,
                          (val) {
                            setState(() => _notifOrderTracking = val);
                            _saveNotificationPref('notif_order_tracking', val);
                          },
                          primary,
                        ),
                        const Divider(height: 24, thickness: 0.5),
                        _buildSwitchTile(
                          "Stock Alerts",
                          "Notifications when favorited items are back in stock",
                          _notifStockAlerts,
                          (val) {
                            setState(() => _notifStockAlerts = val);
                            _saveNotificationPref('notif_stock_alerts', val);
                          },
                          primary,
                        ),
                        const Divider(height: 24, thickness: 0.5),
                        _buildSwitchTile(
                          "Special Offers",
                          "Receive discount codes and special promotions",
                          _notifSpecialOffers,
                          (val) {
                            setState(() => _notifSpecialOffers = val);
                            _saveNotificationPref('notif_special_offers', val);
                          },
                          primary,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 48),
                  
                  // Account Settings
                  Text(
                    "Account Settings",
                    style: GoogleFonts.notoSerif(fontSize: 20, color: onSurface),
                  ),
                  const SizedBox(height: 24),
                  _buildSettingTile(Icons.help_center_outlined, "Help & Support", onSurface, outline, context, onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const ContactScreen()));
                  }),

                  const SizedBox(height: 64),
                  // Sign Out Button
                  Container(
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: const LinearGradient(
                        colors: [primary, primaryContainer],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: primary.withValues(alpha: 0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () async {
                          await Supabase.instance.client.auth.signOut();
                          if (context.mounted) {
                            unawaited(Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(builder: (context) => const WelcomeScreen()),
                              (route) => false,
                            ));
                          }
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.logout, size: 18, color: Colors.white),
                              const SizedBox(width: 8),
                              Text(
                                "SIGN OUT",
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 2,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Center(
                    child: Text(
                      "Sonnas V2.4.0",
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2,
                        color: outline.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditableInfoItem(String label, TextEditingController controller, Color labelColor, Color valueColor, {int maxLines = 1, bool isEnabled = true}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
            color: labelColor.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 4),
        if (_isEditing && isEnabled)
          TextField(
            controller: controller,
            maxLines: maxLines,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: valueColor,
            ),
            decoration: const InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.symmetric(vertical: 8),
              focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFFF4D8D))),
            ),
          )
        else
          Text(
            controller.text,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: valueColor,
              height: 1.4,
            ),
          ),
      ],
    );
  }

  Widget _buildActivityItem(String title, String price, String orderId, String status, String imageUrl, Color primary, Color outline, Color onSurface, Color statusBg) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: const Color(0xFF701235).withValues(alpha: 0.06), blurRadius: 40, offset: const Offset(0, 10)),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(imageUrl, width: 64, height: 64, fit: BoxFit.cover),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text(title, style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: onSurface), maxLines: 1, overflow: TextOverflow.ellipsis)),
                    Text(price, style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.bold, color: primary)),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(orderId, style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w800, color: outline.withValues(alpha: 0.6))),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: statusBg.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(4)),
                      child: Text(status, style: GoogleFonts.plusJakartaSans(fontSize: 9, fontWeight: FontWeight.w800, color: primary)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingTile(IconData icon, String title, Color onSurface, Color outline, BuildContext context, {VoidCallback? onTap}) {
    return Container(
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: outline.withValues(alpha: 0.1)))),
      child: ListTile(
        onTap: onTap ?? () {},
        contentPadding: const EdgeInsets.symmetric(vertical: 8),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(color: const Color(0xFFFFF1E9), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: const Color(0xFF701235), size: 20),
        ),
        title: Text(title, style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600, color: onSurface)),
        trailing: const Icon(Icons.chevron_right, size: 20, color: Color(0xFFD8C1C6)),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color iconColor) {
    const Color secondaryColor = Color(0xFF701235);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: secondaryColor.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: secondaryColor.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                    color: secondaryColor.withValues(alpha: 0.4),
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.notoSerif(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: secondaryColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile(String title, String subtitle, bool value, ValueChanged<bool> onChanged, Color activeColor) {
    const Color secondaryColor = Color(0xFF701235);
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: secondaryColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: secondaryColor.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: Colors.white,
          activeTrackColor: activeColor,
          inactiveThumbColor: Colors.white,
          inactiveTrackColor: Colors.grey.shade300,
        ),
      ],
    );
  }

  Future<void> _addNewAddressDialog() async {
    final controller = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Add Delivery Address", style: GoogleFonts.notoSerif(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: "Enter complete address...",
            filled: true,
            fillColor: const Color(0xFFFFF0F6),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("CANCEL")),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("ADD ADDRESS", style: TextStyle(color: Color(0xFFFF4D8D))),
          ),
        ],
      ),
    );

    if (confirmed == true && controller.text.trim().isNotEmpty) {
      setState(() {
        final newAddr = controller.text.trim();
        _savedAddresses.add(newAddr);
        if (_defaultAddress.isEmpty) {
          _defaultAddress = newAddr;
          _addressController.text = newAddr;
        }
      });
      unawaited(_saveAddressesToPrefs());
    }
  }

  Future<void> _showAvatarSelector() async {
    final List<String> avatars = [
      "https://images.unsplash.com/photo-1576618148400-f54bed99fcfd?w=120&h=120&fit=crop", // cupcake
      "https://images.unsplash.com/photo-1518635017498-87f514b751ba?w=120&h=120&fit=crop", // strawberry
      "https://images.unsplash.com/photo-1555507036-ab1f4038808a?w=120&h=120&fit=crop", // croissant
      "https://images.unsplash.com/photo-1578985545062-69928b1d9587?w=120&h=120&fit=crop", // cake
      "https://images.unsplash.com/photo-1569864358642-9d1684040f43?w=120&h=120&fit=crop", // macaron
      "https://images.unsplash.com/photo-1556910103-1c02745aae4d?w=120&h=120&fit=crop", // chef hat
    ];

    unawaited(showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Choose Your Bakery Avatar",
              style: GoogleFonts.notoSerif(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF701235),
              ),
            ),
            const SizedBox(height: 20),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: avatars.length,
              itemBuilder: (context, index) {
                final url = avatars[index];
                final isSelected = url == _avatarUrl;
                return InkWell(
                  onTap: () {
                    _updateAvatar(url);
                    Navigator.pop(context);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? const Color(0xFFFF4D8D) : Colors.transparent,
                        width: 3,
                      ),
                    ),
                    child: CircleAvatar(
                      backgroundImage: NetworkImage(url),
                      radius: 36,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    ));
  }
}

