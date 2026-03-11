import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:handpicked/services/notification_service.dart';
import 'package:handpicked/screens/signup.dart';
import 'package:handpicked/providers/cart_provider.dart';
import 'package:handpicked/providers/favourites_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await NotificationService.instance.init(); 
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return FavouritesProviderWidget(
      child: CartProviderWidget(
        provider: CartProvider(),
        child: const MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Handpicked',
          home: SignUpScreen(),
        ),
      ),
    );
  }
}