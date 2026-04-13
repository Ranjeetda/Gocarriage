import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../resource/pref_utils.dart';
import 'URLS.dart';

class FileUploadProvider with ChangeNotifier {
  bool _fileLoading = false;

  bool get fileLoading => _fileLoading;

  Future<Map<String, dynamic>?> uploadFileOnServer({
    required String folder,
    File? mFile,
  }) async {
    _fileLoading = true;
    notifyListeners();

    final Uri url = Uri.parse(URLS.fileUpload);

    try {
      final request = http.MultipartRequest('POST', url);

      /// HEADERS
      request.headers.addAll({
        'Authorization': 'Bearer ${PrefUtils.getToken()}',
        'Accept': 'application/json',
      });

      /// FIELDS
      request.fields.addAll({"folder": folder});

      /// FILE
      if (mFile != null) {
        String filePath = mFile.path.toLowerCase();
        String fileName = mFile.path.split('/').last;

        debugPrint("FILE NAME: $fileName");
        debugPrint("FILE PATH: $filePath");

        MediaType mediaType;

        if (filePath.endsWith('.jpg') || filePath.endsWith('.jpeg')) {
          mediaType = MediaType('image', 'jpeg');
        } else if (filePath.endsWith('.png')) {
          mediaType = MediaType('image', 'png');
        } else if (filePath.endsWith('.pdf')) {
          mediaType = MediaType('application', 'pdf');
        } else {
          throw Exception("❌ Unsupported file type. Only JPG, PNG, PDF allowed.");
        }

        request.files.add(
          await http.MultipartFile.fromPath(
            'file', // 🔥 confirm this field name with backend if needed
            mFile.path,
            filename: fileName,
            contentType: mediaType,
          ),
        );
      }

      /// 🔍 PRINT REQUEST
      debugPrint('=========== REQUEST ===========');
      debugPrint('URL: ${request.url}');
      debugPrint('METHOD: ${request.method}');
      debugPrint('HEADERS: ${request.headers}');
      debugPrint('FIELDS: ${request.fields}');
      debugPrint('================================');

      /// SEND REQUEST
      final streamedResponse = await request.send();

      debugPrint('STREAM STATUS CODE: ${streamedResponse.statusCode}');

      final response = await http.Response.fromStream(streamedResponse);

      /// 🔍 PRINT RESPONSE
      debugPrint('=========== RESPONSE ===========');
      debugPrint('STATUS CODE: ${response.statusCode}');
      debugPrint('BODY: ${response.body}');
      debugPrint('================================');

      final responseData = json.decode(response.body);

      return responseData;
    } catch (e) {
      debugPrint('❌ ERROR: $e');
      return null;
    } finally {
      _fileLoading = false;
      notifyListeners();
    }
  }
}