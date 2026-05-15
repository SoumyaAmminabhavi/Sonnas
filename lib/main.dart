import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'customer/providers/cart_provider.dart';
import 'customer/providers/favorites_provider.dart';
import 'customer/main.dart';
import 'customer/screens/welcome_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await dotenv.load(fileName: "assets/.env");
  } catch (e) {
    debugPrint("Warning: .env file not found or failed to load: $e");
  }

  final String supabaseUrl = dotenv.isInitialized 
      ? dotenv.get('SUPABASE_URL', fallback: const String.fromEnvironment('SUPABASE_URL'))
      : const String.fromEnvironment('SUPABASE_URL');
      
  final String supabaseAnonKey = dotenv.isInitialized 
      ? dotenv.get('SUPABASE_ANON_KEY', fallback: const String.fromEnvironment('SUPABASE_ANON_KEY'))
      : const String.fromEnvironment('SUPABASE_ANON_KEY');

  try {
    if (supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty) {
      await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
    }
  } catch (e) {
    debugPrint("Failed to initialize Supabase: $e");
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => FavoritesProvider()),
      ],
      child: const PatisserieApp(),
    ),
  );
}

class PatisserieApp extends StatelessWidget {
  const PatisserieApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Sonna's Patisserie",
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: const ColorScheme.light(
          primary: Color(0xFFFF4D8D),
          secondary: Color(0xFF701235),
          surface: Color(0xFFFFF0F6),
          onSurface: Color(0xFF701235),
          primaryContainer: Color(0xFFFFB6D3),
        ),
        textTheme: _textTheme(const Color(0xFF701235)),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFFF4D8D),
          secondary: Color(0xFFFFB6D3),
          surface: Color(0xFF1A0F14),
          onSurface: Color(0xFFFFF0F6),
          primaryContainer: Color(0xFF701235),
        ),
        textTheme: _textTheme(const Color(0xFFFFF0F6)),
      ),
      // Define routes for easy navigation
      routes: {
        '/home': (context) => const CustomerMainScreen(),
        '/welcome': (context) => const WelcomeScreen(),
      },
      home: Supabase.instance.client.auth.currentSession != null 
          ? const CustomerMainScreen() 
          : const WelcomeScreen(),
    );
  }

  TextTheme _textTheme(Color color) {
    return TextTheme(
      displayLarge: GoogleFonts.notoSerif(color: color),
      headlineLarge: GoogleFonts.notoSerif(color: color),
      bodyLarge: GoogleFonts.plusJakartaSans(color: color),
      labelSmall: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, letterSpacing: 2.0),
    );
  }
}
