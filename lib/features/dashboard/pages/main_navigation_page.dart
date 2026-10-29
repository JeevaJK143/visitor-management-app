import 'dart:async';

import 'package:flutter/material.dart';

import '../../../shared/utils/visitor_actions.dart';
import '../../qr_scanner/pages/qr_scanner_page.dart';
import '../../visitors/pages/visitor_list_page.dart';
import 'dashboard_page.dart';

class MainNavigationPage extends StatefulWidget {
  const MainNavigationPage({super.key});

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  static const _exitWindow = Duration(seconds: 2);

  int _selectedIndex = 0;

  bool _canExit = false;
  Timer? _exitTimer;

  static const _pages = [
    DashboardPage(),
    VisitorListPage(),
    QrScannerPage(),
  ];

  @override
  void dispose() {
    _exitTimer?.cancel();
    super.dispose();
  }

  void _onBack(bool didPop) {
    if (didPop) return;

    if (_selectedIndex != 0) {
      setState(() => _selectedIndex = 0);
      return;
    }

    showAppSnackBar(
      context,
      'Press back again to exit the app',
      duration: _exitWindow,
    );

    setState(() => _canExit = true);
    _exitTimer?.cancel();
    _exitTimer = Timer(_exitWindow, () {
      if (mounted) setState(() => _canExit = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _selectedIndex == 0 && _canExit,
      onPopInvokedWithResult: (didPop, _) => _onBack(didPop),
      child: Scaffold(
        body: _pages[_selectedIndex],
        bottomNavigationBar: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: (index) {
            setState(() => _selectedIndex = index);
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Dashboard',
            ),
            NavigationDestination(
              icon: Icon(Icons.people_outline),
              selectedIcon: Icon(Icons.people),
              label: 'Visitors',
            ),
            NavigationDestination(
              icon: Icon(Icons.qr_code_scanner),
              label: 'Scan QR',
            ),
          ],
        ),
      ),
    );
  }
}
