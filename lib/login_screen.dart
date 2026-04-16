import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:help_desk/main.dart'; // التأكد من الوصول لمتغير الـ supabase المعرف في main
import 'package:help_desk/AdminDashboard.dart';
import 'package:help_desk/add_complaint_screen.dart';

class LoginScreen extends StatefulWidget {
  final bool isAdminRole;
  const LoginScreen({super.key, required this.isAdminRole});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _handleLogin() async {
    // التأكد من إدخال البيانات
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("يرجى إدخال البريد الإلكتروني وكلمة المرور")),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      // 1. محاولة تسجيل الدخول عبر Supabase Auth
      final response = await supabase.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (response.user != null) {
        // 2. جلب رتبة المستخدم (Role) من جدول profiles الذي أنشأتيه في سوبابيز
        final userData = await supabase
            .from('profiles')
            .select('role')
            .eq('id', response.user!.id)
            .single();

        String actualRole = userData['role']; // ستكون إما 'admin' أو 'user'

        if (mounted) {
          // 3. التحقق من تطابق الرتبة مع الواجهة المختارة

          // إذا كان المستخدم أدمن واختار واجهة الأدمن
          if (widget.isAdminRole && actualRole == 'admin') {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const AdminDashboard()),
                  (route) => false,
            );
          }
          // إذا كان المستخدم عادي واختار واجهة المستخدم
          else if (!widget.isAdminRole && actualRole == 'user') {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const AddComplaintScreen()),
                  (route) => false,
            );
          }
          // منع الدخول في حال عدم تطابق الرتبة (حماية الواجهات)
          else {
            await supabase.auth.signOut(); // تسجيل الخروج فوراً للحماية
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("عذراً، ليس لديك صلاحية الوصول لهذه الواجهة!")),
            );
          }
        }
      }
    } on AuthException catch (e) {
      // التعامل مع أخطاء تسجيل الدخول (مثل Invalid credentials)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("خطأ في الدخول: ${e.message}")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("حدث خطأ غير متوقع، تأكد من اتصالك بالإنترنت")),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isAdminRole ? "دخول المسؤول (Admin)" : "دخول المستخدم (User)"),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // أيقونة توضيحية بناءً على الدور
              Icon(
                widget.isAdminRole ? Icons.admin_panel_settings : Icons.person,
                size: 80,
                color: Colors.blue,
              ),
              const SizedBox(height: 30),

              // حقل البريد الإلكتروني
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: "البريد الإلكتروني",
                  prefixIcon: Icon(Icons.email_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),

              // حقل كلمة المرور
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: "كلمة المرور",
                  prefixIcon: Icon(Icons.lock_outline),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 30),

              // زر تسجيل الدخول أو مؤشر التحميل
              _isLoading
                  ? const CircularProgressIndicator()
                  : SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text("تسجيل الدخول", style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}