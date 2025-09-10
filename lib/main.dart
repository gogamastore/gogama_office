// lib/main.dart (Revisi)
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart'; // Impor untuk inisialisasi lokal
import 'firebase_options.dart';

import 'providers/auth_provider.dart';
import 'screens/auth/auth_screen.dart';
import 'screens/main_tab_controller.dart'; // Import MainTabController

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // PERBAIKAN: Inisialisasi data lokal untuk Bahasa Indonesia
  await initializeDateFormatting('id_ID', null);
  
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateChangesProvider);

    return MaterialApp(
      title: 'Gogama Office',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: authState.when(
        data: (user) {
          if (user != null) {
            return const MainTabController(); // Arahkan ke tab controller
          }
          return const AuthScreen();
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => const Center(child: Text('Terjadi kesalahan')),
      ),
    );
  }
}