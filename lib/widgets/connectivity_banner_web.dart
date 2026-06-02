// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;
import 'package:flutter/material.dart';

class ConnectivityBanner extends StatefulWidget {
  final Widget child;
  const ConnectivityBanner({super.key, required this.child});

  @override
  State<ConnectivityBanner> createState() => _ConnectivityBannerState();
}

class _ConnectivityBannerState extends State<ConnectivityBanner> {
  bool _isOnline = true;

  @override
  void initState() {
    super.initState();
    _isOnline = html.window.navigator.onLine ?? true;
    html.window.onOnline.listen((_) {
      if (mounted) setState(() => _isOnline = true);
    });
    html.window.onOffline.listen((_) {
      if (mounted) setState(() => _isOnline = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (!_isOnline)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
            color: Colors.orange.shade800,
            child: const SafeArea(
              bottom: false,
              child: Text(
                'You are offline — some features may be unavailable',
                style: TextStyle(color: Colors.white, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        Expanded(child: widget.child),
      ],
    );
  }
}
