import 'package:flutter/material.dart';
import 'package:help_desk/main.dart'; // الوصول لمتغير supabase

class ComplaintDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> complaint;
  const ComplaintDetailsScreen({super.key, required this.complaint});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(complaint['title'] ?? 'تفاصيل الشكوى'),
        centerTitle: true,
        backgroundColor: Colors.blue.shade50,
      ),
      body: Column(
        children: [
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("وصف المشكلة:", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(complaint['description'] ?? ''),

                  if (complaint['image_url'] != null) ...[
                    const SizedBox(height: 15),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(complaint['image_url'], height: 200, width: double.infinity, fit: BoxFit.cover),
                    ),
                  ],

                  const Divider(height: 30),
                  // عرض الحالة (تتحدث تلقائياً من الأدمن)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("الحالة الحالية:"),
                      StreamBuilder<List<Map<String, dynamic>>>(
                        stream: supabase.from('complaints').stream(primaryKey: ['id']).eq('id', complaint['id']),
                        builder: (context, snapshot) {
                          final status = (snapshot.hasData && snapshot.data!.isNotEmpty)
                              ? snapshot.data!.first['status']
                              : complaint['status'];
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: status == 'done' ? Colors.green.shade100 : Colors.orange.shade100,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(status == 'done' ? "تم الحل" : "قيد المعالجة"),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Align(alignment: Alignment.centerRight, child: Text("ردود الدعم الفني:", style: TextStyle(fontWeight: FontWeight.bold))),
          ),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: supabase.from('replies').stream(primaryKey: ['id']).eq('complaint_id', complaint['id']).order('created_at'),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.isEmpty) return const Center(child: Text("لا توجد ردود بعد."));
                final replies = snapshot.data!;
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: replies.length,
                  itemBuilder: (context, index) => Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 5),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(15)),
                      child: Text(replies[index]['content'] ?? ''),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}