// ignore_for_file: avoid_redundant_argument_values

import 'package:app_flutter/ui/pages/activity_log_page.dart';
import 'package:app_flutter/ui/pages/admin_panel_page.dart';
import 'package:app_flutter/ui/pages/chat_page.dart';
import 'package:app_flutter/ui/pages/days_counter_page.dart';
import 'package:app_flutter/ui/pages/premium_upgrade_page.dart';
import 'package:app_flutter/ui/pages/user_profile_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import "package:flutter/material.dart";
import "package:persistent_bottom_nav_bar/persistent_bottom_nav_bar.dart";
import 'package:supabase_flutter/supabase_flutter.dart';

class HomePage extends StatefulWidget {
  final String role;
  final String suscripcion;

  const HomePage({Key? key, required this.role, required this.suscripcion})
    : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late PersistentTabController _controller;
  late bool _hideNavBar;

  @override
  void initState() {
    super.initState();
    _controller = PersistentTabController(initialIndex: 0);
    _hideNavBar = false;
  }

  List<Widget> _buildScreens() {
    final isAdmin = widget.role == 'admin';

    return [
      WelcomeView(role: widget.role),
      const ActivityLogPage(),
      const PremiumOfferScreen(),
      if (isAdmin) const AdminEventPage() else const DaysCounterPage(),
      const UserProfilePage(),
    ];
  }

  List<PersistentBottomNavBarItem> _navBarsItems() {
    final isAdmin = widget.role == 'admin';

    return [
      PersistentBottomNavBarItem(
        icon: const Icon(Icons.home),
        title: "Inicio",
        activeColorPrimary: Colors.blue,
        inactiveColorPrimary: Colors.grey,
      ),
      PersistentBottomNavBarItem(
        icon: const Icon(Icons.local_activity),
        title: "Actividades",
        activeColorPrimary: Colors.teal,
        inactiveColorPrimary: Colors.grey,
      ),
      PersistentBottomNavBarItem(
        icon: const Icon(Icons.add),
        title: "Agregar",
        activeColorPrimary: Colors.blueAccent,
        inactiveColorPrimary: Colors.grey,
      ),
      PersistentBottomNavBarItem(
        icon: isAdmin
            ? const Icon(Icons.admin_panel_settings)
            : const Icon(Icons.timer),
        title: isAdmin ? "Admin" : "Contador",
        activeColorPrimary: isAdmin ? Colors.red : Colors.deepOrange,
        inactiveColorPrimary: Colors.grey,
      ),
      PersistentBottomNavBarItem(
        icon: const Icon(Icons.settings),
        title: "Ajustes",
        activeColorPrimary: Colors.indigo,
        inactiveColorPrimary: Colors.grey,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text("Menú Principal"),
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      actions: [
        IconButton(
          icon: const Icon(Icons.logout),
          tooltip: 'Cerrar sesión',
          onPressed: () async {
            await FirebaseAuth.instance.signOut();
            if (context.mounted) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text("Sesión cerrada")));
            }
          },
        ),
      ],
    ),
    drawer: Drawer(
      child: FutureBuilder<Map<String, dynamic>?>(
        future: Supabase.instance.client
            .from('usuarios')
            .select('suscripcion')
            .eq('id', FirebaseAuth.instance.currentUser!.uid)
            .maybeSingle(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data;
          final isPremium = data?['suscripcion'] == 'premium';

          return ListView(
            padding: EdgeInsets.zero,
            children: [
              const DrawerHeader(
                decoration: BoxDecoration(color: Colors.teal),
                child: Text(
                  'Menú Lateral',
                  style: TextStyle(color: Colors.white, fontSize: 20),
                ),
              ),

              // ✅ Chat global y privado solo para premium
              if (isPremium) ...[
                ListTile(
                  leading: const Icon(Icons.chat),
                  title: const Text('Chat Global'),
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => const ChatPage()),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.people),
                  title: const Text('Chat con usuarios'),
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.pushNamed(context, '/usuarios');
                  },
                ),
              ] else ...[
                ListTile(
                  leading: const Icon(Icons.lock),
                  title: const Text('Chat Global (Premium)'),
                  subtitle: const Text(
                    'Solo para usuarios con suscripción premium',
                  ),
                  onTap: () {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          '⚠️ Funcionalidad disponible solo para usuarios premium',
                        ),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.lock),
                  title: const Text('Chat con usuarios (Premium)'),
                  subtitle: const Text(
                    'Solo para usuarios con suscripción premium',
                  ),
                  onTap: () {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          '⚠️ Funcionalidad disponible solo para usuarios premium',
                        ),
                      ),
                    );
                  },
                ),
              ],
            ],
          );
        },
      ),
    ),
    body: PersistentTabView(
      context,
      controller: _controller,
      screens: _buildScreens(),
      items: _navBarsItems(),
      handleAndroidBackButtonPress: true,
      resizeToAvoidBottomInset: false,
      stateManagement: true,
      hideNavigationBarWhenKeyboardAppears: true,
      popBehaviorOnSelectedNavBarItemPress: PopBehavior.once,
      backgroundColor: Colors.grey.shade900,
      navBarHeight: kBottomNavigationBarHeight,
      navBarStyle: NavBarStyle.style12,
    ),
  );
}

class WelcomeView extends StatelessWidget {
  final String role;

  const WelcomeView({super.key, required this.role});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🖼️ Banner superior
          Container(
            width: double.infinity,
            height: 180,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: const LinearGradient(
                colors: [Colors.purple, Colors.blue],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Mobile Design Template",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Find your need now and get Discount",
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // 🔘 Accesos rápidos
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: const [
              QuickAccessButton(
                icon: Icons.phone_iphone,
                label: "Responsive",
                color: Colors.pinkAccent,
              ),
              QuickAccessButton(
                icon: Icons.lightbulb,
                label: "Fresh Idea",
                color: Colors.blueAccent,
              ),
              QuickAccessButton(
                icon: Icons.support_agent,
                label: "Support",
                color: Colors.purpleAccent,
              ),
            ],
          ),

          const SizedBox(height: 30),
          const Text(
            "Services",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),

          // 🧩 Cards de servicios
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: const [
              ServiceCard(icon: Icons.android, label: "Android"),
              ServiceCard(icon: Icons.web, label: "Joomla"),
            ],
          ),
        ],
      ),
    );
  }
}

class QuickAccessButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const QuickAccessButton({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      icon: Icon(icon, color: Colors.white),
      label: Text(label, style: const TextStyle(color: Colors.white)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onPressed: () {},
    );
  }
}

class ServiceCard extends StatelessWidget {
  final IconData icon;
  final String label;

  const ServiceCard({super.key, required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 130,
        height: 150,
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: Colors.deepPurple),
            const SizedBox(height: 12),
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text(
              "Lorem ipsum dolor sit amet consectetur",
              style: TextStyle(fontSize: 10),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
