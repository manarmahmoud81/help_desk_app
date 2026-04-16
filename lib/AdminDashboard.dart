import 'package:flutter/material.dart';
import 'package:help_desk/main.dart'; // الوصول لمتغير supabase

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  String searchQuery = "";

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
              if (replyController.text.isNotEmpty) {
                try {
                  // 1. إرسال الرد لجدول الـ replies
                  await supabase.from('replies').insert({
                    'complaint_id': complaintId,
                    'content': replyController.text,
                  });

                  // 2. تحديث الحالة لـ done (الأدمن هو المتحكم الآن)
                  await supabase
                      .from('complaints')
                      .update({'status': 'done'})
                      .eq('id', complaintId);

                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("تم إرسال الرد وتحديث الحالة بنجاح!")),
                    );
                    setState(() {});
                  }
                } catch (e) {
                  debugPrint("خطأ أثناء إرسال الرد: $e");
                }
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
        title: const Text("لوحة تحكم الأدمن"),
        centerTitle: true,
        backgroundColor: Colors.blue.shade100,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: "بحث عن عنوان أو وصف الشكوى...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              ),
              onChanged: (value) => setState(() => searchQuery = value),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: supabase.from('complaints').stream(primaryKey: ['id']).order('created_at', ascending: false),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                if (!snapshot.hasData || snapshot.data!.isEmpty) return const Center(child: Text("لا توجد شكاوى حالياً."));

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
                    return FutureBuilder<List<Map<String, dynamic>>>(
                      future: supabase.from('replies').select().eq('complaint_id', item['id']),
                      builder: (context, replySnapshot) {
                        final bool hasReply = replySnapshot.hasData && replySnapshot.data!.isNotEmpty;
                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          color: item['status'] == 'done' ? Colors.green.shade50 : Colors.white,
                          child: ListTile(
                            leading: Icon(
                              item['status'] == 'done' ? Icons.check_circle : Icons.pending_actions,
                              color: item['status'] == 'done' ? Colors.green : Colors.orange,
                            ),
                            title: Text(item['title'] ?? "بدون عنوان", style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text("الحالة: ${item['status'] == 'done' ? 'تم الحل' : 'قيد الانتظار'}"),
                            trailing: hasReply ? const Icon(Icons.done_all, color: Colors.blue) : const Icon(Icons.reply, color: Colors.grey),
                            onTap: () {
                              if (!hasReply) _showReplyDialog(context, item['id']);
                              else ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("تم الرد بالفعل.")));
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