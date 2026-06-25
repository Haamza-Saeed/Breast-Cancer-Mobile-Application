// lib/services/supabase_service.dart
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class SupabaseService {
  SupabaseService._();
  static final SupabaseService instance = SupabaseService._();

  SupabaseClient get _client => Supabase.instance.client;

  static const String supabaseUrl =
      "https://tutioytqvbukrveotayv.supabase.co";

  static const String supabaseAnonKey =
      "6326a648f4b3aa145cdc37ff73664c06b329f60073cc276101e1d026ee478e9c";

  static const String uploadFn = "bright-action";
  static const String getImagesFn = "bright-task";
  static const String chatUploadFn = "super-task";
  static const String doctorUploadFn = "clever-responder";

  static const String bucket = "patient-images";
  static const String doctorBucket = "doctor-uploads";
  static const String signupBucket = "med_qual";

  static const int signedUrlExpiry = 60 * 60;
  static const int maxUploadBytes = 15 * 1024 * 1024;

  Map<String, dynamic> _asMap(dynamic data) {
    if (data == null) return {};

    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }

    if (data is String) {
      try {
        final decoded = jsonDecode(data);
        if (decoded is Map) {
          return Map<String, dynamic>.from(decoded);
        }
      } catch (_) {}
    }

    if (data is Uint8List) {
      try {
        final decoded = jsonDecode(utf8.decode(data));
        if (decoded is Map) {
          return Map<String, dynamic>.from(decoded);
        }
      } catch (_) {}
    }

    return {};
  }

  String _pretty(dynamic data) {
    try {
      return const JsonEncoder.withIndent("  ").convert(data);
    } catch (_) {
      return data.toString();
    }
  }

  Exception _fnError(
      String fn,
      int status,
      dynamic data, {
        Object? cause,
      }) {
    final parsed = _asMap(data);
    final serverMsg =
    (parsed["error"] ?? parsed["message"] ?? parsed["msg"] ?? "")
        .toString();

    final extra = serverMsg.isNotEmpty ? "\nServer: $serverMsg" : "";

    return Exception(
      "Supabase Function '$fn' failed (HTTP $status)"
          "$extra\nResponse: ${_pretty(data)}\nCause: $cause",
    );
  }

  Exception _storageError(String action, StorageException e) {
    return Exception(
      "Supabase Storage $action failed"
          "\nstatusCode=${e.statusCode}"
          "\nmessage=${e.message}"
          "\nerror=${e.error}",
    );
  }

  String _safeFileName(String name) {
    final cleaned = name.trim().replaceAll(RegExp(r"[^\w\.\-]+"), "_");
    if (cleaned.isEmpty) return "${const Uuid().v4()}.bin";
    return "${const Uuid().v4()}_$cleaned";
  }

  void _guardUploadArgs({
    required String firebaseUid,
    required String folderId,
    required Uint8List bytes,
    required String mimeType,
  }) {
    if (firebaseUid.trim().isEmpty) throw Exception("firebaseUid is empty");
    if (folderId.trim().isEmpty) throw Exception("folderId is empty");
    if (bytes.isEmpty) throw Exception("File is empty");

    if (bytes.length > maxUploadBytes) {
      throw Exception(
        "File too large (${bytes.length} bytes). Max allowed: $maxUploadBytes bytes.",
      );
    }

    if (mimeType.trim().isEmpty) throw Exception("mimeType is empty");
  }

  void _guardDoctorArgs({
    required String doctorId,
    required String exerciseId,
    required Uint8List bytes,
    required String mimeType,
  }) {
    if (doctorId.trim().isEmpty) throw Exception("doctorId is empty");
    if (exerciseId.trim().isEmpty) throw Exception("exerciseId is empty");
    if (bytes.isEmpty) throw Exception("File is empty");

    if (bytes.length > maxUploadBytes) {
      throw Exception(
        "File too large (${bytes.length} bytes). Max allowed: $maxUploadBytes bytes.",
      );
    }

    if (mimeType.trim().isEmpty) throw Exception("mimeType is empty");
  }

  Future<String> uploadFileViaEdgeToBucket({
    required String firebaseUid,
    required String folderId,
    required Uint8List bytes,
    required String fileName,
    required String mimeType,
    required String targetBucket,
  }) async {
    _guardUploadArgs(
      firebaseUid: firebaseUid,
      folderId: folderId,
      bytes: bytes,
      mimeType: mimeType,
    );

    final safeName = _safeFileName(fileName);
    final fnUrl = Uri.parse("$supabaseUrl/functions/v1/$chatUploadFn");

    final body = {
      "firebaseUid": firebaseUid,
      "chatId": folderId,
      "fileName": safeName,
      "mime": mimeType,
      "dataBase64": base64Encode(bytes),
      "bucket": targetBucket,
      "signedUrlExpiry": 0,
    };

    final resp = await http.post(
      fnUrl,
      headers: {
        "Content-Type": "application/json",
        "apikey": supabaseAnonKey,
        "Authorization": "Bearer $supabaseAnonKey",
      },
      body: jsonEncode(body),
    );

    dynamic decoded;
    try {
      decoded = jsonDecode(resp.body);
    } catch (_) {
      decoded = resp.body;
    }

    if (resp.statusCode != 200) {
      throw _fnError(chatUploadFn, resp.statusCode, decoded);
    }

    final map = _asMap(decoded);

    if (map.isEmpty) {
      throw _fnError(
        chatUploadFn,
        resp.statusCode,
        decoded,
        cause: "Response was not a JSON object",
      );
    }

    if (map["ok"] != true) {
      throw _fnError(
        chatUploadFn,
        resp.statusCode,
        map,
        cause: map["error"] ?? "ok != true",
      );
    }

    final publicUrl = (map["publicUrl"] ?? "").toString().trim();
    final url = (map["url"] ?? map["signedUrl"] ?? "").toString().trim();

    final finalUrl = publicUrl.isNotEmpty ? publicUrl : url;

    if (finalUrl.isEmpty) {
      throw _fnError(
        chatUploadFn,
        resp.statusCode,
        map,
        cause: "No publicUrl/url returned from Edge",
      );
    }

    return finalUrl;
  }

  Future<String> uploadSignupDocumentViaEdge({
    required String firebaseUid,
    required Uint8List bytes,
    required String fileName,
    required String mimeType,
  }) async {
    return uploadFileViaEdgeToBucket(
      firebaseUid: firebaseUid,
      folderId: "signup_documents/$firebaseUid",
      bytes: bytes,
      fileName: fileName,
      mimeType: mimeType,
      targetBucket: signupBucket,
    );
  }

  Future<String> uploadChatFileViaEdge({
    required String firebaseUid,
    required String chatId,
    required Uint8List bytes,
    required String fileName,
    required String mimeType,
  }) async {
    return uploadFileViaEdgeToBucket(
      firebaseUid: firebaseUid,
      folderId: chatId,
      bytes: bytes,
      fileName: fileName,
      mimeType: mimeType,
      targetBucket: bucket,
    );
  }

  Future<String> uploadDoctorProfileImageViaEdge({
    required String firebaseUid,
    required Uint8List bytes,
    required String fileName,
    required String mimeType,
  }) async {
    return uploadChatFileViaEdge(
      firebaseUid: firebaseUid,
      chatId: "doctors/$firebaseUid/profile",
      bytes: bytes,
      fileName: fileName,
      mimeType: mimeType,
    );
  }

  Future<String> uploadPatientProfileImageViaEdge({
    required String firebaseUid,
    required Uint8List bytes,
    required String fileName,
    required String mimeType,
    String? firebaseIdToken,
  }) async {
    return uploadChatFileViaEdge(
      firebaseUid: firebaseUid,
      chatId: "profiles",
      bytes: bytes,
      fileName: fileName,
      mimeType: mimeType,
    );
  }

  Future<String> uploadAdminProfileImageViaEdge({
    required String firebaseUid,
    required Uint8List bytes,
    required String fileName,
    required String mimeType,
  }) async {
    return uploadChatFileViaEdge(
      firebaseUid: firebaseUid,
      chatId: "admins/$firebaseUid/profile",
      bytes: bytes,
      fileName: fileName,
      mimeType: mimeType,
    );
  }

  Future<String> uploadChatFile({
    required String firebaseUid,
    required String chatId,
    required Uint8List bytes,
    required String fileName,
    required String mimeType,
  }) async {
    _guardUploadArgs(
      firebaseUid: firebaseUid,
      folderId: chatId,
      bytes: bytes,
      mimeType: mimeType,
    );

    final safeName = _safeFileName(fileName);
    final path = "$firebaseUid/chats/$chatId/$safeName";

    try {
      await _client.storage.from(bucket).uploadBinary(
        path,
        bytes,
        fileOptions: FileOptions(
          contentType: mimeType,
          upsert: true,
        ),
      );

      final signed = await _client.storage
          .from(bucket)
          .createSignedUrl(path, signedUrlExpiry);

      if (signed.isEmpty) {
        throw Exception("Upload succeeded but signed URL is empty.");
      }

      return signed;
    } on StorageException catch (e) {
      throw _storageError("uploadBinary($bucket/$path)", e);
    }
  }

  String publicUrlFromPath(String path, {String useBucket = bucket}) {
    final clean = path.startsWith("/") ? path.substring(1) : path;
    return "$supabaseUrl/storage/v1/object/public/$useBucket/$clean";
  }

  String tryConvertSignedToPublic(String url) {
    final u = url.trim();
    if (u.isEmpty) return u;

    final marker = "/storage/v1/object/sign/";
    final idx = u.indexOf(marker);
    if (idx == -1) return u;

    final after = u.substring(idx + marker.length);
    final q = after.indexOf("?");
    final noQuery = q == -1 ? after : after.substring(0, q);

    final firstSlash = noQuery.indexOf("/");
    if (firstSlash == -1) return u;

    final b = noQuery.substring(0, firstSlash);
    final path = noQuery.substring(firstSlash + 1);

    if (b.isEmpty || path.isEmpty) return u;

    return publicUrlFromPath(path, useBucket: b);
  }

  DoctorUploadResult _doctorUploadResultFromMap(
      Map<String, dynamic> map, {
        required String fallbackFileName,
        required String fallbackMime,
        required int fallbackSize,
      }) {
    final publicUrl = (map["publicUrl"] ?? "").toString().trim();
    final url = (map["url"] ?? map["signedUrl"] ?? "").toString().trim();
    final path = (map["path"] ?? "").toString().trim();

    final finalUrl = publicUrl.isNotEmpty ? publicUrl : url;

    return DoctorUploadResult(
      url: finalUrl,
      path: path,
      fileName: (map["fileName"] ?? fallbackFileName).toString(),
      size: map["size"] is int ? map["size"] as int : fallbackSize,
      mime: (map["mime"] ?? fallbackMime).toString(),
      bucket: (map["bucket"] ?? doctorBucket).toString(),
    );
  }

  Future<DoctorUploadResult> uploadDoctorExerciseViaEdge({
    required String doctorId,
    required String exerciseId,
    required Uint8List bytes,
    required String fileName,
    required String mimeType,
    int signedExpirySeconds = 0,
  }) async {
    _guardDoctorArgs(
      doctorId: doctorId,
      exerciseId: exerciseId,
      bytes: bytes,
      mimeType: mimeType,
    );

    final safeName = _safeFileName(fileName);
    final fnUrl = Uri.parse("$supabaseUrl/functions/v1/$doctorUploadFn");

    final body = {
      "doctorId": doctorId,
      "exerciseId": exerciseId,
      "fileName": safeName,
      "mime": mimeType,
      "dataBase64": base64Encode(bytes),
      "bucket": doctorBucket,
      "signedUrlExpiry": signedExpirySeconds,
    };

    final resp = await http.post(
      fnUrl,
      headers: {
        "Content-Type": "application/json",
        "apikey": supabaseAnonKey,
        "Authorization": "Bearer $supabaseAnonKey",
      },
      body: jsonEncode(body),
    );

    dynamic decoded;
    try {
      decoded = jsonDecode(resp.body);
    } catch (_) {
      decoded = resp.body;
    }

    if (resp.statusCode != 200) {
      throw _fnError(doctorUploadFn, resp.statusCode, decoded);
    }

    final map = _asMap(decoded);

    if (map.isEmpty) {
      throw _fnError(
        doctorUploadFn,
        resp.statusCode,
        decoded,
        cause: "Response was not a JSON object",
      );
    }

    if (map["ok"] != true) {
      throw _fnError(
        doctorUploadFn,
        resp.statusCode,
        map,
        cause: map["error"] ?? "ok != true",
      );
    }

    final result = _doctorUploadResultFromMap(
      map,
      fallbackFileName: safeName,
      fallbackMime: mimeType,
      fallbackSize: bytes.length,
    );

    if (result.url.trim().isEmpty || result.path.trim().isEmpty) {
      throw _fnError(
        doctorUploadFn,
        resp.statusCode,
        map,
        cause: "Missing url/publicUrl or path in edge response",
      );
    }

    return result;
  }

  Future<String> uploadDoctorMediaViaEdge({
    required String doctorId,
    required String exerciseId,
    required Uint8List bytes,
    required String fileName,
    required String mimeType,
  }) async {
    final r = await uploadDoctorExerciseViaEdge(
      doctorId: doctorId,
      exerciseId: exerciseId,
      bytes: bytes,
      fileName: fileName,
      mimeType: mimeType,
      signedExpirySeconds: 0,
    );

    return r.url;
  }

  Future<Map<String, dynamic>> uploadReportImages({
    required String firebaseUid,
    required String reportId,
    required List<Uint8List> images,
    String defaultMime = "image/jpeg",
  }) async {
    if (firebaseUid.trim().isEmpty) throw Exception("firebaseUid is empty");
    if (reportId.trim().isEmpty) throw Exception("reportId is empty");
    if (images.isEmpty) return {"ok": true, "uploaded": []};

    for (final img in images) {
      if (img.isEmpty) continue;

      if (img.length > maxUploadBytes) {
        throw Exception(
          "One image is too large (${img.length} bytes). Max allowed: $maxUploadBytes bytes.",
        );
      }
    }

    final payload = images
        .where((b) => b.isNotEmpty)
        .map((bytes) => {
      "dataBase64": base64Encode(bytes),
      "mime": defaultMime,
    })
        .toList();

    final res = await _client.functions.invoke(
      uploadFn,
      body: {
        "firebaseUid": firebaseUid,
        "reportId": reportId,
        "images": payload,
      },
    );

    if (res.status != 200) {
      throw _fnError(uploadFn, res.status, res.data);
    }

    final map = _asMap(res.data);

    if (map.isEmpty) {
      throw _fnError(
        uploadFn,
        res.status,
        res.data,
        cause: "Response was not a JSON object.",
      );
    }

    if (map["ok"] != true) {
      throw _fnError(
        uploadFn,
        res.status,
        map,
        cause: map["error"] ?? "ok != true",
      );
    }

    return map;
  }

  Future<List<String>> getReportImageUrls({
    required String firebaseUid,
    required String reportId,
    bool fallbackToStorageList = true,
  }) async {
    if (firebaseUid.trim().isEmpty) throw Exception("firebaseUid is empty");
    if (reportId.trim().isEmpty) throw Exception("reportId is empty");

    final res = await _client.functions.invoke(
      getImagesFn,
      body: {
        "firebaseUid": firebaseUid,
        "reportId": reportId,
      },
    );

    if (res.status != 200) {
      throw _fnError(getImagesFn, res.status, res.data);
    }

    final map = _asMap(res.data);

    if (map.isEmpty) {
      if (!fallbackToStorageList) return const [];
      return _fallbackSignedUrlsFromStorage(
        firebaseUid: firebaseUid,
        reportId: reportId,
      );
    }

    if (map["ok"] != true) {
      throw _fnError(
        getImagesFn,
        res.status,
        map,
        cause: map["error"] ?? "ok != true",
      );
    }

    final urls = map["urls"];
    final urlList = urls is List
        ? urls.map((e) => e.toString()).where((s) => s.isNotEmpty).toList()
        : <String>[];

    if (urlList.isEmpty && fallbackToStorageList) {
      return _fallbackSignedUrlsFromStorage(
        firebaseUid: firebaseUid,
        reportId: reportId,
      );
    }

    return urlList;
  }

  Future<Map<String, dynamic>> getReportImagesDebug({
    required String firebaseUid,
    required String reportId,
  }) async {
    final res = await _client.functions.invoke(
      getImagesFn,
      body: {
        "firebaseUid": firebaseUid,
        "reportId": reportId,
      },
    );

    final debug = <String, dynamic>{
      "function": getImagesFn,
      "httpStatus": res.status,
      "request": {
        "firebaseUid": firebaseUid,
        "reportId": reportId,
      },
      "rawDataType": res.data?.runtimeType.toString(),
      "rawData": res.data,
    };

    final map = _asMap(res.data);

    if (map.isNotEmpty) {
      debug["parsed"] = map;
      debug["ok"] = map["ok"];
      debug["prefix"] = map["prefix"];
      debug["paths"] = map["paths"];
      debug["urls"] = map["urls"];
      debug["error"] = map["error"];
      debug["note"] = map["note"];
    }

    return debug;
  }

  Future<List<String>> _fallbackSignedUrlsFromStorage({
    required String firebaseUid,
    required String reportId,
  }) async {
    final prefix = "$firebaseUid/reports/$reportId";

    try {
      final files = await _client.storage.from(bucket).list(
        path: prefix,
        searchOptions: const SearchOptions(limit: 100),
      );

      if (files.isEmpty) return const [];

      final paths = files
          .where((f) => (f.name ?? "").isNotEmpty)
          .map((f) => "$prefix/${f.name}")
          .toList();

      final signed = await _client.storage
          .from(bucket)
          .createSignedUrls(paths, signedUrlExpiry);

      return signed.map((s) => s.signedUrl).where((u) => u.isNotEmpty).toList();
    } on StorageException {
      return const [];
    } catch (_) {
      return const [];
    }
  }
}

class DoctorUploadResult {
  final String url;
  final String path;
  final String fileName;
  final int size;
  final String mime;
  final String bucket;

  DoctorUploadResult({
    required this.url,
    required this.path,
    required this.fileName,
    required this.size,
    required this.mime,
    required this.bucket,
  });
}