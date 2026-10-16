import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart';

class ApiService {
  // 10.0.2.2 = your PC, as seen from the Android emulator
  static final Dio _dio = Dio(BaseOptions(baseUrl: 'http://10.0.2.2:8000'))
    ..interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await FirebaseAuth.instance.currentUser?.getIdToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
    ));

  static Future<List<dynamic>> getSubjects() async {
    final res = await _dio.get('/subjects');
    return res.data;
  }

  static Future<List<dynamic>> getFeed({String? subjectId}) async {
    final res = await _dio.get('/feed',
        queryParameters: {if (subjectId != null) 'subject_id': subjectId});
    return res.data;
  }

  static Future<Map<String, dynamic>> getMe() async =>
    (await _dio.get('/auth/me')).data;

static Future<List<dynamic>> getMaterials(String subjectId) async =>
    (await _dio.get('/materials', queryParameters: {'subject_id': subjectId})).data;

static Future<void> uploadMaterial(String subjectId, PlatformFile file) async {
  final form = FormData.fromMap({
    'subject_id': subjectId,
    'file': MultipartFile.fromBytes(file.bytes!, filename: file.name),
  });
  await _dio.post('/materials/upload', data: form);
}

static Future<void> createPost(
    {String? subjectId, required String title, String body = ''}) async {
  await _dio.post('/feed',
      data: {'subject_id': subjectId, 'title': title, 'body': body});
}
}