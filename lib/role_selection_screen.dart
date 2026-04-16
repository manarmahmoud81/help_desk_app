import 'package:flutter/material.dart';
import 'package:help_desk/login_screen.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.support_agent_rounded, size: 100, color: Colors.blue),
              const SizedBox(height: 20),
              const Text("Help Desk System", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.blue)),
              const SizedBox(height: 40),

              // زر المستخدم
              _buildRoleButton(
                context,
                title: "واجهة المستخدم (User)",
                icon: Icons.person_outline,
                isAdmin: false,
              ),

              const SizedBox(height: 20),

              // زر المسؤول
              _buildRoleButton(
                context,
                title: "لوحة المسؤول (Admin)",
                icon: Icons.admin_panel_settings_outlined,
                isAdmin: true,
                isOutlined: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleButton(BuildContext context, {required String title, required IconData icon, required bool isAdmin, bool isOutlined = false}) {
    return SizedBox(
      width: double.infinity,
      child: isOutlined
          ? OutlinedButton.icon(
        onPressed: () => _navigateToLogin(context, isAdmin),
        icon: Icon(icon),
        label: Text(title),
      )
          : ElevatedButton.icon(
        onPressed: () => _navigateToLogin(context, isAdmin),
        icon: Icon(icon),
        label: Text(title),
        style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
      ),
    );
  }

  void _navigateToLogin(BuildContext context, bool isAdmin) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen(isAdminRole: isAdmin)),
    );
  }
}