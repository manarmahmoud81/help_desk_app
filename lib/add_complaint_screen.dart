import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:help_desk/main.dart';
import 'package:help_desk/models.dart';
import 'package:get_storage/get_storage.dart';
import 'complaint_details_screen.dart';

class AddComplaintScreen extends StatefulWidget {
  const AddComplaintScreen({super.key});

  @override
  State<AddComplaintScreen> createState() => _AddComplaintScreenState();
}

class _AddComplaintScreenState extends State<AddComplaintScreen> {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descController = TextEditingController();
  final box = GetStorage();

  File? _selectedImage;
  bool _isUploading = false;

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<String?> _uploadToStorage(File image) async {
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    final path = 'complaints/$fileName';
    await supabase.storage.from('complaint_images').upload(path, image);
    return supabase.storage.from('complaint_images').getPublicUrl(path);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إرسال شكوى جديدة'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'عنوان الشكوى',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.title),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'وصف المشكلة بالتفصيل',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                ),
              ),
              const SizedBox(height: 10),

              if (_selectedImage != null)
                Container(
                  height: 100,
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    image: DecorationImage(image: FileImage(_selectedImage!), fit: BoxFit.cover),
                  ),
                ),

              OutlinedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.add_a_photo),
                label: Text(_selectedImage == null ? 'إرفاق صورة (اختياري)' : 'تغيير الصورة'),
              ),
              const SizedBox(height: 10),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                onPressed: _isUploading ? null : () async {
                  if (titleController.text.isNotEmpty && descController.text.isNotEmpty) {
                    setState(() => _isUploading = true);
                    try {
                      String? imageUrl;
                      if (_selectedImage != null) {
                        imageUrl = await _uploadToStorage(_selectedImage!);
                      }

                      await supabase.from('complaints').insert({
                        'title': titleController.text,
                        'description': descController.text,
                        'image_url': imageUrl,
                        'status': 'not done',
                      });

                      titleController.clear();
                      descController.clear();
                      setState(() => _selectedImage = null);

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('تم إرسال شكواك بنجاح!')),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('عذراً، حدث خطأ: $e')),
                      );
                    } finally {
                      setState(() => _isUploading = false);
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('يرجى ملء جميع الحقول')),
                    );
                  }
                },
                child: _isUploading
                    ? const CircularProgressIndicator()
                    : const Text('إرسال الشكوى الآن', style: TextStyle(fontSize: 16)),
              ),

              const Divider(height: 40),

              const Text(
                'شكاواك السابقة:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),

              SizedBox(
                height: 400,
                child: StreamBuilder<List<Map<String, dynamic>>>(
                  stream: supabase.from('complaints').stream(primaryKey: ['id']).order('created_at'),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      box.write('complaints_cache', snapshot.data);
                    }

                    if (snapshot.connectionState == ConnectionState.waiting && !box.hasData('complaints_cache')) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final List<dynamic> complaints = snapshot.hasData
                        ? snapshot.data!
                        : (box.read('complaints_cache') ?? []);

                    if (complaints.isEmpty) {
                      return const Center(child: Text('لا توجد شكاوى حالياً.'));
                    }

                    return ListView.builder(
                      itemCount: complaints.length,
                      itemBuilder: (context, index) {
                        final item = complaints[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: ListTile(
                            // تعديل لعرض الصورة الحقيقية بدلاً من الأيقونة الزرقاء
                            leading: item['image_url'] != null
                                ? ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: Image.network(
                                item['image_url'],
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.broken_image, color: Colors.grey),
                              ),
                            )
                                : const Icon(Icons.insert_drive_file_outlined),
                            title: Text(item['title'] ?? 'بدون عنوان'),
                            subtitle: Text('الحالة: ${item['status']}'),
                            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ComplaintDetailsScreen(complaint: item),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}