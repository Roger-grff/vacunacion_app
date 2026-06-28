import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'providers/autenticacion_proveedor.dart';
import 'providers/sector_proveedor.dart';
import 'providers/vacunacion_proveedor.dart';
import 'views/auth/login_vista.dart';
import 'views/auth/cambiar_contrasena_vista.dart';
import 'views/shared/pantalla_navegacion_principal.dart';
import 'firebase_options.dart';

void main() async {
  // Asegurar que los bindings de Flutter estén listos
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicialización de Firebase para el backend
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    print('Firebase initialization warning: $e');
    print('Recuerda configurar Firebase usando flutterfire configure para habilitar el backend.');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => SectorProvider()),
        ChangeNotifierProvider(create: (_) => VaccinationProvider()),
      ],
      child: MaterialApp(
        title: 'Campaña de Vacunación',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF203A43),
            primary: const Color(0xFF203A43),
            secondary: const Color(0xFF2C5364),
          ),
          appBarTheme: const AppBarTheme(
            elevation: 0,
            centerTitle: true,
            titleTextStyle: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.grey[50],
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF203A43), width: 1.5),
            ),
            labelStyle: const TextStyle(color: Colors.black54),
          ),
          chipTheme: ChipThemeData(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
        ),
        home: const AuthenticationWrapper(),
      ),
    );
  }
}

// Controla el flujo inicial de pantallas basado en la autenticación del usuario
class AuthenticationWrapper extends StatelessWidget {
  const AuthenticationWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    if (authProvider.isInitialLoading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Color(0xFF203A43)),
              SizedBox(height: 16),
              Text('Cargando sesión...', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      );
    }

    if (!authProvider.isAuthenticated) {
      return const LoginView();
    }

    if (authProvider.forcePasswordChange) {
      return const ChangePasswordView();
    }

    return const MainNavigationScreen();
  }
}

