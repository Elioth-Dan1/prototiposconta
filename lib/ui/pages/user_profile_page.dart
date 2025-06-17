import 'package:app_flutter/ui/pages/edit_user_profile_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UserProfilePage extends StatefulWidget {
  const UserProfilePage({super.key});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  Map<String, dynamic>? _userData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final response = await Supabase.instance.client
        .from('usuarios')
        .select()
        .eq('id', user.uid)
        .maybeSingle();

    setState(() {
      _userData = response;
      _isLoading = false;
    });
  }

  void _openEditModal() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const EditUserProfilePage(),
    );
    await _loadUserData();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final data = _userData;
    if (data == null) {
      return const Scaffold(
        body: Center(child: Text("No se encontró la información.")),
      );
    }

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.deepPurple, Colors.purpleAccent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(40),
                ),
              ),
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person, size: 50, color: Colors.purple),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    data['nombres'] ?? '',
                    style: const TextStyle(
                      fontSize: 22,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            _ProfileTile(
              icon: Icons.cake,
              label: 'Fecha de nacimiento',
              value: data['fecha_nacimiento'] ?? '',
            ),
            _ProfileTile(
              icon: Icons.phone,
              label: 'Teléfono',
              value: data['telefono'] ?? '',
            ),
            _ProfileTile(
              icon: Icons.email,
              label: 'Email',
              value: data['email'] ?? '',
            ),
            _ProfileTile(
              icon: Icons.key,
              label: 'Rol',
              value: data['rol'] ?? '',
            ),
            _ProfileTile(
              icon: Icons.workspace_premium,
              label: 'Suscripción',
              value: data['suscripcion'] ?? '',
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _openEditModal,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text(
                "Editar perfil",
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ProfileTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Colors.deepPurple),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(value.isEmpty ? 'No definido' : value),
    );
  }
}
