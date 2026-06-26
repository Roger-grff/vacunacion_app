import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../providers/autenticacion_proveedor.dart';
import '../dashboard/dashboard_vista.dart';
import '../vaccinations/lista_vacunacion_vista.dart';
import '../sectors/gestionar_sectores_vista.dart';
import '../users/gestionar_usuarios_vista.dart';
import 'menu_lateral.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  final Connectivity _connectivity = Connectivity();

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.userModel;

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Configurar pestañas y títulos basados en el rol del usuario
    final List<Widget> tabs = [];
    final List<Widget> tabViews = [];

    // Todos los roles ven el Dashboard
    tabs.add(const Tab(icon: Icon(Icons.dashboard_outlined), text: 'Dashboard'));
    tabViews.add(const DashboardView());

    if (user.rol == 'coordinador_campana') {
      // Coordinador de Campaña: Dashboard, Sectores, Usuarios
      tabs.add(const Tab(icon: Icon(Icons.business_outlined), text: 'Sectores'));
      tabViews.add(const ManageSectorsView());
      
      tabs.add(const Tab(icon: Icon(Icons.people_outline), text: 'Usuarios'));
      tabViews.add(const ManageUsersView());
    } else if (user.rol == 'coordinador_brigada') {
      // Coordinador de Brigada: Dashboard, Vacunaciones, Usuarios
      tabs.add(const Tab(icon: Icon(Icons.assignment_outlined), text: 'Vacunaciones'));
      tabViews.add(const VaccinationListView());

      tabs.add(const Tab(icon: Icon(Icons.people_outline), text: 'Vacunadores'));
      tabViews.add(const ManageUsersView());
    } else {
      // Vacunador: Dashboard, Vacunaciones
      tabs.add(const Tab(icon: Icon(Icons.assignment_outlined), text: 'Vacunaciones'));
      tabViews.add(const VaccinationListView());
    }

    return DefaultTabController(
      length: tabs.length,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Vacunación Canina & Felina'),
          backgroundColor: const Color(0xFF203A43),
          foregroundColor: Colors.white,
          actions: [
            // Indicador de conexión en la barra superior
            StreamBuilder<List<ConnectivityResult>>(
              stream: _connectivity.onConnectivityChanged,
              builder: (context, snapshot) {
                final results = snapshot.data;
                final isOnline = results != null &&
                    results.isNotEmpty &&
                    results.any((result) => result != ConnectivityResult.none);

                return Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: Tooltip(
                    message: isOnline ? 'Dispositivo Conectado (Online)' : 'Dispositivo Desconectado (Offline)',
                    child: Icon(
                      isOnline ? Icons.wifi : Icons.wifi_off,
                      color: isOnline ? Colors.greenAccent : Colors.redAccent,
                    ),
                  ),
                );
              },
            ),
          ],
          bottom: TabBar(
            tabs: tabs,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            indicatorSize: TabBarIndicatorSize.tab,
          ),
        ),
        drawer: const SidebarMenu(),
        body: TabBarView(
          children: tabViews,
        ),
      ),
    );
  }
}

