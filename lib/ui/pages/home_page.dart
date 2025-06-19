import 'package:app_flutter/core/services/notification_service.dart';
import 'package:app_flutter/ui/pages/activity_log_page.dart';
import 'package:app_flutter/ui/pages/admin_panel_page.dart';
import 'package:app_flutter/ui/pages/admin_payment_validation.dart';
import 'package:app_flutter/ui/pages/admin_users_page.dart';
import 'package:app_flutter/ui/pages/chat_page.dart';
import 'package:app_flutter/ui/pages/days_counter_page.dart';
import 'package:app_flutter/ui/pages/event_detail_page.dart';
import 'package:app_flutter/ui/pages/mood_tracker_page.dart';
import 'package:app_flutter/ui/pages/premium_upgrade_page.dart';
import 'package:app_flutter/ui/pages/user_profile_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import "package:flutter/material.dart";
import 'package:intl/intl.dart';
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
      WelcomeView(role: widget.role, suscripcion: widget.suscripcion),
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
            await NotificationService.clearToken();
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
              if (widget.role == 'admin') ...[
                ListTile(
                  leading: const Icon(Icons.supervised_user_circle),
                  title: const Text('Gestionar usuarios'),
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const AdminUsersPage()),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.payment),
                  title: const Text('Pagos pendientes'),
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const AdminPendingPaymentsPage(),
                      ),
                    );
                  },
                ),
              ],

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
                  title: const Text('Asesoria'),
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
              ListTile(
                leading: const Icon(Icons.emoji_emotions),
                title: const Text('Mi estado de ánimo'),
                onTap: () {
                  Navigator.of(context).pop(); // cierra drawer
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const MoodTrackerPage()),
                  );
                },
              ),
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
  final String suscripcion;

  const WelcomeView({super.key, required this.role, required this.suscripcion});
  Future<List<Map<String, dynamic>>> _fetchEventos() async {
    final filters = {'estado': 'activo'};

    if (suscripcion != 'premium') {
      filters['tipo_suscripcion'] = 'básico';
    }

    final data = await Supabase.instance.client
        .from('eventos')
        .select()
        .match(filters)
        .order('fecha', ascending: true);

    return List<Map<String, dynamic>>.from(data);
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🖼️ Banner superior
          const SizedBox(height: 20),

          // 🔘 Accesos rápidos
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              QuickAccessButton(
                icon: Icons.support_agent,
                label: "Support",
                color: Colors.purpleAccent,
              ),
            ],
          ),

          const SizedBox(height: 30),
          const Text(
            "Eventos",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),

          // 🧩 Cards de servicios + eventos
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _fetchEventos(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final eventos = snapshot.data!;
              if (eventos.isEmpty) {
                return const Text("No hay eventos disponibles.");
              }

              return GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                padding: const EdgeInsets.all(12),
                itemCount: eventos.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.8,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemBuilder: (context, index) {
                  final evento = eventos[index];
                  final fecha = DateTime.tryParse(evento['fecha'] ?? '');
                  final fechaTexto = fecha != null
                      ? DateFormat.yMMMd('es_ES').format(fecha)
                      : 'Sin fecha';

                  return GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => EventDetailPage(evento: evento),
                        ),
                      );
                    },
                    child: Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      elevation: 5,
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (evento['imagen'] != null &&
                              evento['imagen'].toString().isNotEmpty)
                            Image.network(
                              evento['imagen'],
                              height: 120,
                              fit: BoxFit.cover,
                            )
                          else
                            Container(
                              height: 120,
                              color: Colors.teal.shade100,
                              child: const Icon(
                                Icons.event,
                                size: 40,
                                color: Colors.white,
                              ),
                            ),
                          Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  evento['titulo'] ?? 'Sin título',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.calendar_today,
                                      size: 14,
                                      color: Colors.teal,
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        fechaTexto,
                                        style: const TextStyle(fontSize: 12),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
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
    Key? key,
    required this.icon,
    required this.label,
    required this.color,
  }) : super(key: key);

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
