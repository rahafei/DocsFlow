import 'dart:convert';
import 'dart:io';

import 'package:docflownew/core/theme/app_colors.dart';
import 'package:docflownew/screens/user/secretarial_management_screen.dart';
import 'package:docflownew/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ImagePicker _picker = ImagePicker();

  final List<XFile> _selectedPages = [];

  final List<Map<String, dynamic>> _recentDocuments = [];



  @override
  void initState() {
    super.initState();
    _loadRecentDocuments();
  }

  Future<void> _loadRecentDocuments() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final savedDocuments = prefs.getStringList('recent_documents');

      if (savedDocuments == null || savedDocuments.isEmpty) {
        return;
      }

      final loadedDocuments = <Map<String, dynamic>>[];

      for (final document in savedDocuments) {
        try {
          final decoded = jsonDecode(document);

          if (decoded is Map<String, dynamic>) {
            loadedDocuments.add(decoded);
          }
        } catch (e) {
          print('تعذر قراءة مستند محفوظ: $e');
        }
      }

      if (!mounted) return;

      setState(() {
        _recentDocuments
          ..clear()
          ..addAll(loadedDocuments);
      });
    } catch (e) {
      print('حدث خطأ أثناء تحميل المستندات المحفوظة: $e');
    }
  }


  Future<void> _saveRecentDocuments() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final documents = _recentDocuments
          .map((document) => jsonEncode(document))
          .toList();

      await prefs.setStringList(
        'recent_documents',
        documents,
      );
    } catch (e) {
      print('حدث خطأ أثناء حفظ المستندات: $e');
    }
  }


  Future<void> _openDocument(String url) async {
    try {
      print('جاري تحميل ملف Word...');

      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}$url'),
      );

      if (response.statusCode != 200) {
        throw Exception('فشل تحميل الملف');
      }

      final directory = await getTemporaryDirectory();

      final fileName = url.split('/').last;

      final file = File(
        '${directory.path}/$fileName',
      );

      await file.writeAsBytes(response.bodyBytes);

      print('تم حفظ الملف في: ${file.path}');

      final result = await OpenFilex.open(file.path);

      print('نتيجة فتح الملف: ${result.message}');

      if (result.type != ResultType.done) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'لم يتم العثور على تطبيق لفتح ملف Word',
              style: GoogleFonts.tajawal(),
            ),
          ),
        );
      }
    } catch (e) {
      print('حدث خطأ أثناء فتح ملف Word: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'تعذر فتح ملف Word',
            style: GoogleFonts.tajawal(),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _processDocument() async {
    if (_selectedPages.isEmpty) {
      return;
    }

    try {
      print(
        'جاري إرسال ${_selectedPages.length} صفحات للباك إند...',
      );

      final files = _selectedPages
    .map((page) => File(page.path))
    .toList();

    final result = await ApiService.processDocument(
      files,
    );
      print('RESULT FROM BACKEND: $result');
      print('تمت معالجة المستند بنجاح');
      print('النص: ${result['text']}');
      print('أمين السر: ${result['secretary']}');
      print('مسار Word: ${result['docx_path']}');
      print('رابط Word: ${result['docx_url']}');

      if (!mounted) return;

      if (result['docx_url'] != null) {
        final newDocument = {
          'name': result['docx_path'] ?? 'مستند.docx',
          'url': result['docx_url'],
          'text': result['text'] ?? '',
        };

        setState(() {
          _recentDocuments.insert(
            0,
            newDocument,
          );

          _selectedPages.clear();
        });

        await _saveRecentDocuments();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result['secretary']?['matched'] == true
                ? 'تم التعرف على أمين السر وإنشاء ملف Word'
                : 'تمت معالجة المستند',
            style: GoogleFonts.inter(),
          ),
        ),
      );
    } catch (e) {
      print('حدث خطأ أثناء معالجة المستند: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'تعذر معالجة المستند',
            style: GoogleFonts.inter(),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }


  Future<void> _openCamera() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.camera,
    );

    if (image == null) {
      return;
    }

    setState(() {
      _selectedPages.add(image);
    });

    _showPagesPreview();
  }

  Future<void> _pickFromGallery() async {
    final List<XFile> images = await _picker.pickMultiImage();

    if (images.isEmpty) {
      return;
    }

    setState(() {
      _selectedPages.addAll(images);
    });

    _showPagesPreview();
  }


  void _showPagesPreview() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Directionality(
              textDirection: TextDirection.rtl,
              child: Container(
                height: MediaQuery.of(context).size.height * 0.75,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 12),

                    Container(
                      width: 45,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),

                    const SizedBox(height: 18),

                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'صفحات المستند',
                              style: GoogleFonts.tajawal(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppColors.text,
                              ),
                            ),
                          ),
                          Text(
                            '${_selectedPages.length} صفحات',
                            style: GoogleFonts.tajawal(
                              fontSize: 14,
                              color: AppColors.text.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 15),

                    Expanded(
                      child: _selectedPages.isEmpty
                          ? Center(
                              child: Text(
                                'لم تتم إضافة صفحات',
                                style: GoogleFonts.tajawal(
                                  color: AppColors.text.withOpacity(0.5),
                                ),
                              ),
                            )
                          : GridView.builder(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 10,
                              ),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: 0.75,
                              ),
                              itemCount: _selectedPages.length,
                              itemBuilder: (context, index) {
                                final page = _selectedPages[index];

                                return Stack(
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade100,
                                        borderRadius:
                                            BorderRadius.circular(14),
                                        border: Border.all(
                                          color: Colors.grey.shade200,
                                        ),
                                      ),
                                      clipBehavior: Clip.antiAlias,
                                      child: Column(
                                        children: [
                                          Expanded(
                                            child: Image.file(
                                              File(page.path),
                                              width: double.infinity,
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                          Padding(
                                            padding:
                                                const EdgeInsets.symmetric(
                                              vertical: 8,
                                            ),
                                            child: Text(
                                              'الصفحة ${index + 1}',
                                              style: GoogleFonts.tajawal(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                                color: AppColors.text,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    Positioned(
                                      top: 8,
                                      left: 8,
                                      child: GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _selectedPages.removeAt(index);
                                          });

                                          setSheetState(() {});
                                        },
                                        child: Container(
                                          width: 32,
                                          height: 32,
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black
                                                    .withOpacity(0.12),
                                                blurRadius: 6,
                                              ),
                                            ],
                                          ),
                                          child: const Icon(
                                            Icons.close,
                                            size: 19,
                                            color: Colors.red,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                    ),

                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          20,
                          10,
                          20,
                          20,
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () async {
                                      Navigator.pop(context);

                                      await Future.delayed(
                                        const Duration(
                                          milliseconds: 200,
                                        ),
                                      );

                                      _showDocumentOptions();
                                    },
                                    icon: const Icon(
                                      Icons.add,
                                    ),
                                    label: Text(
                                      'إضافة صفحة',
                                      style: GoogleFonts.tajawal(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppColors.primary,
                                      side: BorderSide(
                                        color: AppColors.primary,
                                      ),
                                      minimumSize:
                                          const Size.fromHeight(50),
                                      shape:
                                          RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(14),
                                      ),
                                    ),
                                  ),
                                ),

                                const SizedBox(width: 10),

                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed:
                                        _selectedPages.isEmpty
                                            ? null
                                            : () async {
                                                Navigator.pop(
                                                  context,
                                                );

                                                await _processDocument();
                                              },
                                    icon: const Icon(
                                      Icons.auto_awesome,
                                    ),
                                    label: Text(
                                      'معالجة المستند',
                                      style: GoogleFonts.tajawal(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          AppColors.primary,
                                      foregroundColor:
                                          AppColors.buttonText,
                                      minimumSize:
                                          const Size.fromHeight(50),
                                      shape:
                                          RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(14),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showDocumentOptions() {
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
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 15,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: const Icon(
                      Icons.camera_alt_outlined,
                      color: AppColors.primary,
                    ),
                    title: Text(
                      'تصوير المستند',
                      style: GoogleFonts.tajawal(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.text,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _openCamera();
                    },
                  ),
                  ListTile(
                    leading: const Icon(
                      Icons.photo_library_outlined,
                      color: AppColors.primary,
                    ),
                    title: Text(
                      'اختيار من الاستديو',
                      style: GoogleFonts.tajawal(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.text,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _pickFromGallery();
                    },
                  ),
                ],
              ),
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
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 10,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),

                Column(
                  children: [
                    SizedBox(
                      height: 230,
                      width: double.infinity,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Positioned(
                            bottom: 25,
                            left: 0,
                            right: 0,
                            child: Center(
                              child: GestureDetector(
                                onTap: _showDocumentOptions,
                                child: Image.asset(
                                  'assets/images/scanfile.png',
                                  width: 200,
                                  height: 200,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      'ابدأ برقمنة مستندك',
                      style: GoogleFonts.tajawal(
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                        color: AppColors.text,
                      ),
                    ),

                    const SizedBox(height: 6),

                    Text(
                      'صوّر مستندك أو اختره من الاستديو لتحويله إلى ملف Word',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.tajawal(
                        fontSize: 14,
                        color: AppColors.text.withOpacity(0.65),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 25),

                if (_selectedPages.isNotEmpty) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.grey.shade200,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 45,
                          height: 45,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.description_outlined,
                            color: AppColors.primary,
                          ),
                        ),

                        const SizedBox(width: 12),

                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                'مستند قيد التجهيز',
                                style: GoogleFonts.tajawal(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.text,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '${_selectedPages.length} صفحات جاهزة للمعالجة',
                                style: GoogleFonts.tajawal(
                                  fontSize: 12,
                                  color:
                                      AppColors.text.withOpacity(0.55),
                                ),
                              ),
                            ],
                          ),
                        ),

                        TextButton(
                          onPressed: _showPagesPreview,
                          child: Text(
                            'عرض',
                            style: GoogleFonts.tajawal(
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 25),
                ],

                Text(
                  'المضافة مؤخرًا',
                  style: GoogleFonts.tajawal(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.text,
                  ),
                ),

                const SizedBox(height: 15),

                _recentDocuments.isEmpty
                    ? Text(
                        'لا توجد مستندات مضافة حتى الآن',
                        style: GoogleFonts.tajawal(
                          fontSize: 14,
                          color: AppColors.text.withOpacity(0.5),
                        ),
                      )
                    : SizedBox(
                        height: 120,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _recentDocuments.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(width: 12),
                          itemBuilder: (context, index) {
                            final document =
                                _recentDocuments[index];

                            final fileName =
                                document['name'] as String;

                            final text =
                                document['text'] as String;

                            final url =
                                document['url'] as String;

                            return GestureDetector(
                              onTap: () {
                                _openDocument(url);
                              },
                              child: Container(
                                width: 190,
                                height: 120,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius:
                                      BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.grey.shade200,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 45,
                                      height: 55,
                                      decoration: BoxDecoration(
                                        color: Colors.red.shade50,
                                        borderRadius:
                                            BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        Icons.description_outlined,
                                        color: Colors.red.shade400,
                                        size: 28,
                                      ),
                                    ),

                                    const SizedBox(width: 10),

                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            fileName,
                                            maxLines: 1,
                                            overflow:
                                                TextOverflow.ellipsis,
                                            style: GoogleFonts.inter(
                                              fontSize: 13,
                                              fontWeight:
                                                  FontWeight.w600,
                                              color: AppColors.text,
                                            ),
                                          ),

                                          const SizedBox(height: 6),

                                          Text(
                                            text,
                                            maxLines: 2,
                                            overflow:
                                                TextOverflow.ellipsis,
                                            style: GoogleFonts.tajawal(
                                              fontSize: 11,
                                              color: AppColors.text
                                                  .withOpacity(0.6),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                const SizedBox(height: 25),
              ],
            ),
          ),
        ),


        bottomNavigationBar: BottomNavigationBar(
          currentIndex: 0,
          onTap: (index) {
            if (index == 1) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      const SecretarialManagementScreen(),
                ),
              );
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