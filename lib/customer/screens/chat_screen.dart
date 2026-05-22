import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'tracking_screen.dart';




class ChatMessage {
  final String text;
  final bool isBakery;
  final String time;

  ChatMessage({required this.text, required this.isBakery, required this.time});
}

class ChatScreen extends StatefulWidget {
  final VoidCallback? onBack;
  const ChatScreen({super.key, this.onBack});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<ChatMessage> _messages = [
    ChatMessage(
      isBakery: true,
      text: "Hi! Welcome to Sonna’s 💖 What would you like today?",
      time: "10:02 AM",
    ),
    ChatMessage(
      isBakery: false,
      text: "I'd like to see your chocolate cakes.",
      time: "10:05 AM",
    ),
  ];

  void _sendMessage() {
    if (_controller.text.trim().isEmpty) return;
    setState(() {
      _messages.add(ChatMessage(
        text: _controller.text,
        isBakery: false,
        time: TimeOfDay.now().format(context),
      ));
      _controller.clear();
    });
    
    // Simulate bakery response
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _messages.add(ChatMessage(
            text: "That's a wonderful choice! Our classic Valrhona chocolate is a bestseller. Would you like to see the details?",
            isBakery: true,
            time: TimeOfDay.now().format(context),
          ));
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    const Color primary = Color(0xFFFF4D8D);
    const Color background = Color(0xFFFFF0F6);
    const Color secondary = Color(0xFF701235);
    const Color primaryContainer = Color(0xFFFFB6D3);
    const Color surfaceContainerHighest = Color(0xFFFFDCC5);

    return Scaffold(
      backgroundColor: background,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: primary, size: 20),
          onPressed: () {
            if (widget.onBack != null) {
              widget.onBack!();
            } else {
              Navigator.pop(context);
            }
          },
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: surfaceContainerHighest,
                image: DecorationImage(
                  image: NetworkImage("https://lh3.googleusercontent.com/aida-public/AB6AXuCW4VX5enGAie3GkYPPdkamq4fQHv3lj8sSmMFCeKGncIWPGw2NHARgnOOW2j3je_VU9aHSOP8VuJ1LYAWt6Ez_KwQqQrJCyQS9c1NRVc1dcFGb1WkErJdj3FZ061YNmFJkRMnbxZ-4QNBayv6uAS6o0ufEqvlWfGJ8d1woBnaqg56KKXT9huUMdmlDVHKH4zlC5paYiO5G1RzogtALXXxTDzYGRRCE1tLgTCbLGMPSl0bNxkbLmT5S9iqwmoefCfT8xYLqFRWFaBe4"),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Sonna's Patisserie",
                  style: GoogleFonts.notoSerif(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontStyle: FontStyle.italic,
                    color: primary,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF10B981),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      "ONLINE",
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                        color: secondary.withValues(alpha: 0.65),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.fiber_manual_record, color: primary, size: 12),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 120, 16, 120),
            itemCount: _messages.length + 2, // +2 for timestamp and quick replies
            itemBuilder: (context, index) {
              if (index == 0) {
                return Center(
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 24),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF1E9),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      "TODAY",
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                        color: const Color(0xFF867277),
                      ),
                    ),
                  ),
                );
              }
              if (index == 1) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildQuickReplyChip("Browse Cakes"),
                      _buildQuickReplyChip("Custom Order"),
                      _buildQuickReplyChip("Track Order"),
                    ],
                  ),
                );
              }
              final message = _messages[index - 2];
              return _buildMessage(
                isBakery: message.isBakery,
                text: message.text,
                time: message.time,
              );
            },
          ),

          // Bottom Input Area
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              decoration: BoxDecoration(
                color: background,
                border: Border(top: BorderSide(color: secondary.withValues(alpha: 0.1))),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline, color: secondary),
                    onPressed: () {},
                  ),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                        color: const Color(0xFFFFF1E9),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _controller,
                              onSubmitted: (_) => _sendMessage(),
                              decoration: InputDecoration(
                                hintText: "Type your message...",
                                hintStyle: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  color: secondary.withValues(alpha: 0.4),
                                ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              maxLines: null,
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.image_outlined, color: secondary.withValues(alpha: 0.4)),
                            onPressed: () {},
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _sendMessage,
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [primary, primaryContainer],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: const Icon(Icons.send, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessage({required bool isBakery, required String text, required String time}) {
    const Color primary = Color(0xFFFF4D8D);
    const Color secondary = Color(0xFF701235);
    const Color primaryContainer = Color(0xFFFFB6D3);
    const Color surfaceContainerLowest = Color(0xFFFFFFFF);

    return Align(
      alignment: isBakery ? Alignment.centerLeft : Alignment.centerRight,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: isBakery ? CrossAxisAlignment.start : CrossAxisAlignment.end,
          children: [
            Container(
              constraints: const BoxConstraints(maxWidth: 300),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isBakery ? surfaceContainerLowest : primaryContainer.withValues(alpha: 0.38),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(24),
                  topRight: const Radius.circular(24),
                  bottomLeft: isBakery ? const Radius.circular(4) : const Radius.circular(24),
                  bottomRight: isBakery ? const Radius.circular(24) : const Radius.circular(4),
                ),
                boxShadow: isBakery ? [
                  BoxShadow(
                    color: secondary.withValues(alpha: 0.06),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ] : null,
              ),
              child: Text(
                text,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  height: 1.6,
                  color: isBakery ? secondary : primary,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              time,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
                color: secondary.withValues(alpha: 0.4),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickReplyChip(String label) {
    const Color primary = Color(0xFFFF4D8D);
    const Color surfaceContainerLowest = Color(0xFFFFFFFF);

    return InkWell(
      onTap: () {
        if (label == "Track Order") {
          Navigator.push(
            context,
            MaterialPageRoute<void>(builder: (context) => const CustomerTrackingScreen()),
          );
        } else {
          _controller.text = label;
          _sendMessage();
        }
      },
      borderRadius: BorderRadius.circular(99),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: surfaceContainerLowest,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: const Color(0xFFD8C1C6).withValues(alpha: 0.52)),
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: primary,
          ),
        ),
      ),
    );
  }
}
