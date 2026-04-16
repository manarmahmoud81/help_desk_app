import 'package:help_desk/main.dart';

// دالة إرسال الشكوى (شغالة تمام وزي الفل)
Future<void> insertComplaint(String title, String description) async {
  try {
    await supabase.from('complaints').insert({
      'title': title,
      'description': description,
      'status': 'not done', // القيمة الافتراضية اللي حددتيها
    });
    print('تم إرسال الشكوى بنجاح!');
  } catch (e) {
    print('حدث خطأ أثناء الإرسال: $e');
  }
}

// التعديل هنا: حولناها لدالة بتاخد ID الشكوى كمعامل (Parameter)
Stream getRepliesStream(int complaintId) {
  return supabase
      .from('replies')
      .stream(primaryKey: ['id'])
      .eq('complaint_id', complaintId) // سيجلب الردود الخاصة بهذا الـ ID فقط
      .order('created_at');
}