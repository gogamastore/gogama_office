import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/auth_provider.dart';
import '../../services/user_service.dart';
import 'profile_settings_screen.dart';
import 'security_screen.dart'; // Impor file baru

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userData = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil Saya'),
        centerTitle: true,
      ),
      body: userData.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Terjadi kesalahan: $error')),
        data: (user) {
          final displayName = (user != null && user.name.isNotEmpty) ? user.name : (user?.email ?? 'Pengguna');
          final photoUrl = user?.photoURL ?? '';

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Center(
                  child: CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.grey.shade300,
                    backgroundImage: photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
                    child: photoUrl.isEmpty
                        ? Icon(Icons.person, size: 60, color: Colors.grey.shade600)
                        : null,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  displayName,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    children: [
                      _buildProfileMenuItem(context, icon: Icons.settings, title: 'Pengaturan'),
                      const Divider(height: 1, indent: 16, endIndent: 16),
                      _buildProfileMenuItem(context, icon: Icons.bar_chart, title: 'Laporan'),
                      const Divider(height: 1, indent: 16, endIndent: 16),
                      _buildProfileMenuItem(context, icon: Icons.person, title: 'Profil'),
                      const Divider(height: 1, indent: 16, endIndent: 16),
                      _buildProfileMenuItem(context, icon: Icons.security, title: 'Keamanan'),
                    ],
                  ),
                ),

                const Spacer(),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.logout, color: Colors.white),
                    label: const Text('Logout', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.redAccent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () async {
                      await ref.read(authServiceProvider).signOut();
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileMenuItem(BuildContext context, {required IconData icon, required String title}) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).primaryColor),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () {
        // DIPERBARUI: Menambahkan navigasi untuk Keamanan
        if (title == 'Profil') {
          Navigator.of(context).push(MaterialPageRoute(builder: (context) => const ProfileSettingsScreen()));
        } else if (title == 'Keamanan') {
          Navigator.of(context).push(MaterialPageRoute(builder: (context) => const SecurityScreen()));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Navigasi untuk "$title" belum diimplementasikan.')),
          );
        }
      },
    );
  }
}
