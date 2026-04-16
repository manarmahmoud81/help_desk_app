import 'package:flutter/material.dart';
import 'package:help_desk/main.dart'; // الوصول لمتغير supabase المعرف عالمياً

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  String searchQuery = "";

  // دالة إظهار نافذة الرد وتحديث الحالة
  void _showReplyDialog(BuildContext context, int complaintId) {
    final TextEditingController replyController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("إضافة رد حل للمشكلة"),
        content: TextField(
          controller: replyController,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: "اكتب حلاً أو رداً هنا...",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("إلغاء"),
          ),
          ElevatedButton(
            onPressed: () async {
              if (replyController.text.trim().isNotEmpty) {
                try {
                  // 1. إرسال الرد لجدول الـ replies
                  await supabase.from('replies').insert({
                    'complaint_id': complaintId,
                    'content': replyController.text.trim(),
                  });

                  // 2. تحديث الحالة في جدول الشكاوى (complaints) لتصبح done
                  await supabase
                      .from('complaints')
                      .update({'status': 'done'})
                      .eq('id', complaintId);

                  if (context.mounted) {
                    Navigator.pop(context); // إغلاق النافذة
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("تم إرسال الرد وتحديث الحالة إلى 'تم الحل' ✅")),
                    );
                    // إعادة بناء الواجهة لتحديث الألوان والأيقونات
                    setState(() {});
                  }
                } catch (e) {
                  debugPrint("خطأ أثناء إرسال الرد: $e");
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("حدث خطأ: $e")),
                    );
                  }
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("يرجى كتابة رد أولاً")),
                );
              }
            },
            child: const Text("إرسال الرد"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("لوحة تحكم المسؤول (Admin)"),
        centerTitle: true,
        backgroundColor: Colors.blue.shade100,
      ),
      body: Column(
        children: [
          // حقل البحث (Search Bar)
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: "بحث عن عنوان أو وصف الشكوى...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) => setState(() => searchQuery = value),
            ),
          ),

          // عرض الشكاوى باستخدام StreamBuilder للتحديث اللحظي
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: supabase
                  .from('complaints')
                  .stream(primaryKey: ['id'])
                  .order('created_at', ascending: false),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text("لا توجد شكاوى حالياً."));
                }

                // تصفية النتائج بناءً على البحث
                final filteredComplaints = snapshot.data!.where((c) {
                  final title = c['title']?.toString().toLowerCase() ?? "";
                  final desc = c['description']?.toString().toLowerCase() ?? "";
                  final query = searchQuery.toLowerCase();
                  return title.contains(query) || desc.contains(query);
                }).toList();

                return ListView.builder(
                  itemCount: filteredComplaints.length,
                  itemBuilder: (context, index) {
                    final item = filteredComplaints[index];
                    final bool isDone = item['status'] == 'done';

                    return FutureBuilder<List<Map<String, dynamic>>>(
                      future: supabase.from('replies').select().eq('complaint_id', item['id']),
                      builder: (context, replySnapshot) {
                        final bool hasReply = replySnapshot.hasData && replySnapshot.data!.isNotEmpty;

                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          elevation: 2,
                          color: isDone ? Colors.green.shade50 : Colors.white,
                          child: ListTile(
                            leading: Icon(
                              isDone ? Icons.check_circle : Icons.pending_actions,
                              color: isDone ? Colors.green : Colors.orange,
                              size: 30,
                            ),
                            title: Text(
                              item['title'] ?? "بدون عنوان",
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item['description'] ?? ""),
                                const SizedBox(height: 4),
                                Text(
                                  "الحالة: ${isDone ? 'تم الحل' : 'قيد الانتظار'}",
                                  style: TextStyle(
                                    color: isDone ? Colors.green.shade700 : Colors.orange.shade800,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            trailing: hasReply
                                ? const Icon(Icons.done_all, color: Colors.blue)
                                : const Icon(Icons.reply, color: Colors.grey),
                            onTap: () {
                              if (!isDone) {
                                _showReplyDialog(context, item['id']);
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("هذه الشكوى تم حلها بالفعل.")),
                                );
                              }
                            },
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}