import 'dart:io';
import 'package:docflownew/core/theme/app_colors.dart';
import 'package:docflownew/core/database/database_helper.dart';
import 'package:docflownew/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

class SecretarialManagementScreen extends StatefulWidget {
  const SecretarialManagementScreen({Key? key}) : super(key: key);

  @override
  State<SecretarialManagementScreen> createState() =>
      _SecretarialManagementScreenState();
}

class _SecretarialManagementScreenState
    extends State<SecretarialManagementScreen> {
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  List<Map<String, dynamic>> _secretaries = [];

  @override
  void initState() {
    super.initState();
    _loadSecretaries();
  }

  Future<void> _loadSecretaries() async {
    final secretaries = await _databaseHelper.getSecretaries();

    if (!mounted) return;

    setState(() {
      _secretaries = secretaries;
    });
  }

  void _showAddSecretaryDialog() {
    print('تم الضغط على زر الإضافة');

    final TextEditingController nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: Text(
              'إضافة أمين سر جديد',
              style: GoogleFonts.instrumentSans(
                fontWeight: FontWeight.bold,
                color: AppColors.text,
              ),
            ),
            content: TextField(
              controller: nameController,
              autofocus: true,
              style: GoogleFonts.inter(
                color: AppColors.text,
              ),
              decoration: InputDecoration(
                hintText: 'أدخل اسم أمين السر',
                hintStyle: GoogleFonts.inter(
                  color: AppColors.text.withOpacity(0.5),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                    color: AppColors.secondary,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'إلغاء',
                  style: GoogleFonts.inter(
                    color: Colors.grey,
                  ),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                ),
                onPressed: () async {
                  print('تم الضغط على زر إضافة داخل النافذة');

                  final name = nameController.text.trim();

                  if (name.isEmpty) {
                    print('الاسم فارغ');
                    return;
                  }

                  try {
                    print('جاري إرسال الاسم للباك اند: $name');

                    await ApiService.createSecretary(name);

                    print('تمت الإضافة في الباك اند');

                    await _databaseHelper.addSecretary(name);

                    print('تمت الإضافة في قاعدة البيانات المحلية');

                    if (!mounted) return;

                    Navigator.pop(context);

                    await _loadSecretaries();

                    ScaffoldMessenger.of(this.context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'تمت إضافة أمين السر بنجاح',
                          style: GoogleFonts.inter(),
                        ),
                      ),
                    );
                  } catch (e) {
                    print('حدث خطأ: $e');

                    if (!mounted) return;

                    ScaffoldMessenger.of(this.context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'تعذر إضافة أمين السر',
                          style: GoogleFonts.inter(),
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                child: Text(
                  'إضافة',
                  style: GoogleFonts.inter(
                    color: AppColors.buttonText,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickHandwritingSamples(String secretaryName) async {
  final ImagePicker picker = ImagePicker();

  final source = await showModalBottomSheet<ImageSource>(
    context: context,
    builder: (context) {
      return Directionality(
        textDirection: TextDirection.rtl,
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('التقاط صورة'),
                onTap: () {
                  Navigator.pop(context, ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('اختيار من الاستديو'),
                onTap: () {
                  Navigator.pop(context, ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      );
    },
  );

  if (source == null) {
    return;
  }

  try {
    final List<File> files = [];

    // =========================
    // التصوير بالكاميرا
    // =========================

    if (source == ImageSource.camera) {
      bool addMore = true;

      while (addMore) {
        final XFile? image = await picker.pickImage(
          source: ImageSource.camera,
        );

        if (image == null) {
          break;
        }

        files.add(File(image.path));

        if (!mounted) return;

        if (files.length >= 20) {
          break;
        }

        addMore = await showDialog<bool>(
              context: context,
              builder: (context) {
                return Directionality(
                  textDirection: TextDirection.rtl,
                  child: AlertDialog(
                    title: Text(
                      'تم التقاط الصورة',
                      style: GoogleFonts.instrumentSans(
                        fontWeight: FontWeight.bold,
                        color: AppColors.text,
                      ),
                    ),
                    content: Text(
                      'تم إضافة ${files.length} صور. هل تريدين تصوير نموذج خط آخر؟',
                      style: GoogleFonts.inter(
                        color: AppColors.text,
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context, false);
                        },
                        child: Text(
                          'انتهيت',
                          style: GoogleFonts.inter(
                            color: Colors.grey,
                          ),
                        ),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                        ),
                        onPressed: () {
                          Navigator.pop(context, true);
                        },
                        child: Text(
                          'إضافة صورة أخرى',
                          style: GoogleFonts.inter(
                            color: AppColors.buttonText,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ) ??
            false;
      }
    }

    // =========================
    // الاستديو
    // =========================

    else {
      final List<XFile> images = await picker.pickMultiImage();

      if (images.isEmpty) {
        return;
      }

      files.addAll(
        images.map(
          (image) => File(image.path),
        ),
      );
    }

    // =========================
    // التأكد من وجود صور
    // =========================

    if (files.isEmpty) {
      return;
    }

    print('أمين السر: $secretaryName');
    print('عدد الصور المختارة: ${files.length}');
    print('جاري إرسال النماذج للباك إند...');

    // =========================
    // إرسال جميع الصور دفعة واحدة
    // =========================

    await ApiService.enrollSecretary(
      secretaryName,
      files,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'تمت إضافة ${files.length} نماذج خط بنجاح',
          style: GoogleFonts.inter(),
        ),
      ),
    );
  } catch (e) {
    print('حدث خطأ أثناء إرسال نماذج الخط: $e');

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'تعذر إضافة نماذج الخط',
          style: GoogleFonts.inter(),
        ),
        backgroundColor: Colors.red,
      ),
    );
  }
}

  void _showEditSecretaryDialog(int index) {
    final TextEditingController nameController =
        TextEditingController(
      text: _secretaries[index]['name'],
    );

    showDialog(
      context: context,
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: Text(
              'تعديل اسم أمين السر',
              style: GoogleFonts.instrumentSans(
                fontWeight: FontWeight.bold,
                color: AppColors.text,
              ),
            ),
            content: TextField(
              controller: nameController,
              autofocus: true,
              style: GoogleFonts.inter(
                color: AppColors.text,
              ),
              decoration: InputDecoration(
                hintText: 'أدخل الاسم الجديد',
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                    color: AppColors.secondary,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'إلغاء',
                  style: GoogleFonts.inter(
                    color: Colors.grey,
                  ),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                ),
                onPressed: () async {
                  final name = nameController.text.trim();

                  if (name.isNotEmpty) {
                   final id = _secretaries[index]['id'];
                    final oldName = _secretaries[index]['name'];

                    await ApiService.updateSecretary(oldName, name);
                    await _databaseHelper.updateSecretary(id, name);

                    Navigator.pop(context);
                    await _loadSecretaries();
                  }
                },
                child: Text(
                  'حفظ التعديل',
                  style: GoogleFonts.inter(
                    color: AppColors.buttonText,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showOptionsBottomSheet(int index) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 20,
              horizontal: 10,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(
                    Icons.edit,
                    color: AppColors.primary,
                  ),
                  title: Text(
                    'تعديل الاسم',
                    style: GoogleFonts.inter(
                      color: AppColors.text,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _showEditSecretaryDialog(index);
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.delete_outline,
                    color: Colors.red,
                  ),
                  title: Text(
                    'حذف أمين السر',
                    style: GoogleFonts.inter(
                      color: Colors.red,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onTap: () async {
                    final id = _secretaries[index]['id'];
                      final name = _secretaries[index]['name'];

                      await ApiService.deleteSecretary(name);
                      await _databaseHelper.deleteSecretary(id);

                      Navigator.pop(context);
                      await _loadSecretaries();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,

        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          automaticallyImplyLeading: false,
          centerTitle: true,
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.description,
                color: AppColors.primary,
              ),
              const SizedBox(width: 6),
              Text(
                'Docflow',
                style: GoogleFonts.instrumentSans(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                ),
              ),
            ],
          ),
        ),

        body: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
              ),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  Center(
                    child: Text(
                      'إدارة أمناء السر',
                      style: GoogleFonts.instrumentSans(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: AppColors.text,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  Expanded(
                    child: _secretaries.isEmpty
                        ? Center(
                            child: Text(
                              'لا يوجد أمناء سر مضافون حتى الآن',
                              style: GoogleFonts.inter(
                                color: AppColors.text.withOpacity(0.5),
                                fontSize: 14,
                              ),
                            ),
                          )
                        : ListView.separated(
                            itemCount: _secretaries.length,
                            padding: const EdgeInsets.only(
                              bottom: 90,
                            ),
                            separatorBuilder: (context, index) =>
                                const SizedBox(
                              height: 16,
                            ),
                            itemBuilder: (context, index) {
                              return SecretaryCard(
                                name: _secretaries[index]['name'],
                                isActive:
                                    _secretaries[index]['isActive'] == 1,
                                onEditTap: () =>
                                    _showOptionsBottomSheet(index),
                                onSelectSignature: () {},
                                onAddNewTemplate: () =>
                                    _pickHandwritingSamples(
                                  _secretaries[index]['name'],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),

            Positioned(
              bottom: 20,
              right: 20,
              child: FloatingActionButton.extended(
                onPressed: _showAddSecretaryDialog,
                backgroundColor: AppColors.primary,
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                icon: const Icon(
                  Icons.add,
                  color: AppColors.buttonText,
                ),
                label: Text(
                  'إضافة أمين سر جديد',
                  style: GoogleFonts.inter(
                    color: AppColors.buttonText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),

        bottomNavigationBar: BottomNavigationBar(
          currentIndex: 1,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFF775132),
          unselectedItemColor:
              AppColors.text.withOpacity(0.4),
          selectedLabelStyle: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: GoogleFonts.inter(
            fontSize: 12,
          ),
          onTap: (index) {
            if (index == 0) {
              Navigator.pop(context);
            }
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              label: 'الرئيسية',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people_outline),
              label: 'المستخدمون',
            ),
          ],
        ),
      ),
    );
  }
}

class SecretaryCard extends StatelessWidget {
  final String name;
  final bool isActive;
  final VoidCallback onEditTap;
  final VoidCallback onSelectSignature;
  final VoidCallback onAddNewTemplate;

  const SecretaryCard({
    Key? key,
    required this.name,
    this.isActive = true,
    required this.onEditTap,
    required this.onSelectSignature,
    required this.onAddNewTemplate,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor:
                      AppColors.secondary.withOpacity(0.4),
                  child: const Icon(
                    Icons.person,
                    size: 32,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const SizedBox(height: 6),
                    Text(
                      name,
                      style: GoogleFonts.instrumentSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.text,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(
                    Icons.edit_note,
                    color:
                        AppColors.text.withOpacity(0.5),
                    size: 26,
                  ),
                  onPressed: onEditTap,
                  constraints:
                      const BoxConstraints(),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed:
                              onAddNewTemplate,
                          style:
                              OutlinedButton.styleFrom(
                                backgroundColor: const Color(0xFF775132),
                            side:
                                const BorderSide(
                              color:
                                  Color(0xFF775132),
                            ),
                            shape:
                                RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(20),
                            ),
                            padding:
                                const EdgeInsets.symmetric(
                              vertical: 10,
                            ),
                          ),
                          child: Text(
                            'إضافة نموذج خط جديد',
                            style: GoogleFonts.inter(
                              color: const Color(0xFFFFFFFF)
                                  .withOpacity(0.7),
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 65),
              ],
            ),
          ],
        ),
      ),
    );
  }
}