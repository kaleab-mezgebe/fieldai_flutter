import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';

class ApiClient {
  static final ApiClient instance = ApiClient._init();
  late Dio dio;

  ApiClient._init() {
    dio = Dio(BaseOptions(
      baseUrl: AppConstants.apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    // Request interceptor for attaching auth JWT token
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString(AppConstants.keyAuthToken);
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (DioException e, handler) {
        // Log network exceptions
        return handler.next(e);
      },
    ));
  }

  // --- Auth API ---

  Future<Response> login(String email, String password) async {
    return await dio.post('/auth/login', data: {
      'email': email,
      'password': password,
    });
  }

  Future<Response> register(String email, String password, String fullName) async {
    return await dio.post('/auth/register', data: {
      'email': email,
      'password': password,
      'full_name': fullName,
    });
  }

  // --- Prediction API ---

  Future<Response> uploadAndPredict({
    required List<int> imageBytes,
    required String fileName,
    String crop = 'Tomato',
    double? latitude,
    double? longitude,
  }) async {
    FormData formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(imageBytes, filename: fileName),
      'crop': crop,
      if (latitude != null) 'latitude': latitude.toString(),
      if (longitude != null) 'longitude': longitude.toString(),
    });

    return await dio.post('/predictions', data: formData);
  }

  // --- Sync API ---

  Future<Response> syncBatch({
    required String batchId,
    required List<Map<String, dynamic>> observations,
  }) async {
    return await dio.post('/sync', data: {
      'batch_id': batchId,
      'observations': observations,
    });
  }

  // --- Chat RAG API ---

  Future<Response> sendChatMessage({
    required String message,
    String? contextPrediction,
  }) async {
    return await dio.post('/chat', data: {
      'message': message,
      'context_crop': 'Tomato',
      'context_prediction': contextPrediction,
    });
  }

  // --- Analytics API ---

  Future<Response> getAnalyticsSummary() async {
    return await dio.get('/analytics/summary');
  }
}
