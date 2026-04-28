import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';

class DnsFallbackInterceptor extends Interceptor {
  final void Function(String)? onLog;

  DnsFallbackInterceptor({this.onLog});

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // 移除了IP直连逻辑，保留拦截器结构以备将来扩展或记录请求信息
    // 依靠系统默认DNS解析
    super.onRequest(options, handler);
  }
}

class WebDavErrorLoggerInterceptor extends Interceptor {
  final void Function(String)? onLog;

  WebDavErrorLoggerInterceptor({this.onLog});

  void _writeLog(String message) {
    try {
      if (onLog != null) {
        onLog!(message);
      } else {
        print(message);
      }
    } catch (e) {
      print('Failed to write WebDAV error log: $e');
    }
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final buffer = StringBuffer();
    buffer.writeln('=== [WebDAV Error] ===');
    buffer.writeln('DioException: [${err.type}] ${err.message}');
    
    // Request Details
    buffer.writeln('\n--- Request Details ---');
    buffer.writeln('Method: ${err.requestOptions.method}');
    buffer.writeln('URL: ${err.requestOptions.uri}');
    buffer.writeln('Headers:');
    err.requestOptions.headers.forEach((key, value) {
      if (key.toLowerCase() == 'authorization') {
        buffer.writeln('  $key: [HIDDEN]');
      } else {
        buffer.writeln('  $key: $value');
      }
    });
    if (err.requestOptions.data != null) {
      buffer.writeln('Request Data: ${err.requestOptions.data}');
    }

    // Response Details
    buffer.writeln('\n--- Response Details ---');
    if (err.response != null) {
      buffer.writeln('Status Code: ${err.response?.statusCode}');
      buffer.writeln('Status Message: ${err.response?.statusMessage}');
      buffer.writeln('Response Headers:');
      err.response?.headers.forEach((key, values) {
        buffer.writeln('  $key: ${values.join(', ')}');
      });
      buffer.writeln('Response Data: ${err.response?.data}');
    } else {
      buffer.writeln('No Response Received.');
    }

    // Underlying Error Details
    buffer.writeln('\n--- Underlying Error ---');
    if (err.error != null) {
      buffer.writeln('Error Details: ${err.error}');
      if (err.error is SocketException) {
        final se = err.error as SocketException;
        buffer.writeln('SocketException: ${se.message}, osError: ${se.osError}');
      } else if (err.error is TlsException) {
        final te = err.error as TlsException;
        buffer.writeln('TlsException: ${te.message}, osError: ${te.osError}');
      } else if (err.error is HttpException) {
        final he = err.error as HttpException;
        buffer.writeln('HttpException: ${he.message}, uri: ${he.uri}');
      }
    } else {
      buffer.writeln('None.');
    }
    
    buffer.writeln('==================================================');
    _writeLog(buffer.toString());
    
    super.onError(err, handler);
  }
}

class WebDavClient {
  late final Dio dio;

  WebDavClient({
    required String baseUrl,
    required String username,
    required String password,
    void Function(String)? onLog,
  }) {
    final credentials = base64Encode(utf8.encode('$username:$password'));
    dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        'Authorization': 'Basic $credentials',
      },
    ));

    // Custom HttpClientAdapter for DNS bypassing or SSL bypassing
    dio.httpClientAdapter = IOHttpClientAdapter(
      createHttpClient: () {
        final client = HttpClient();
        // Allow bypassing certificate errors for IP fallback
        client.badCertificateCallback = (X509Certificate cert, String host, int port) => true;
        // By default findProxy is direct, but ensuring it avoids broken proxy configs
        client.findProxy = (uri) => 'DIRECT';
        return client;
      },
    );

    // DNS/IP fallback interceptor
    dio.interceptors.add(DnsFallbackInterceptor(onLog: onLog));

    // Error Logger Interceptor
    dio.interceptors.add(WebDavErrorLoggerInterceptor(onLog: onLog));
  }

  /// 统一的请求入口，支持 PROPFIND, MKCOL 等自定义 Method
  Future<Response<T>> request<T>(
    String path, {
    required String method,
    dynamic data,
    Map<String, dynamic>? headers,
    ResponseType responseType = ResponseType.plain,
  }) async {
    return await dio.request<T>(
      path,
      data: data,
      options: Options(
        method: method,
        headers: headers,
        responseType: responseType,
      ),
    );
  }
}
