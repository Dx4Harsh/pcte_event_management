import 'dart:developer';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

class ResultApiCalls {
  final dio = Dio();

  Future<List<Map<String, dynamic>>> getResultById({required String eventId, int? year}) async {
    try {
      year ??= DateTime.now().year;
      final response = await dio.get(
        'https://koshish-backend.vercel.app/api/result/get/$eventId?year=${year.toString()}',
      );

      log("Status Code: ${response.statusCode}");
      log("Status Message: ${response.statusMessage}");


      if (response.statusCode == 200) {
        Map<String,dynamic> jsonData = response.data['data'];
        List<Map<String,dynamic>> resultList = List<Map<String,dynamic>>.from(jsonData['result']);
        log(resultList.toString());


        return resultList;
      }
      else if(response.statusCode == 404)
      {
        return [];
      }
      else {
        log("Unexpected Status Code: ${response.statusCode}");
        return [];
      }
    } on DioException catch (e) {
      log("DioException: ${e.response?.statusCode ?? "No Status Code"}");
      log("Error Message: ${e.response?.statusMessage ?? e.message}");
      log("Response Data: ${e.response?.data ?? "No Response Data"}");
      return [];
    } catch (e) {
      log("Unexpected Error: $e");
      return [];
    }
  }



  Future<List<Map<String, dynamic>>> getFinalResults({required int year, required String type}) async {
    try {
      final response = await dio.get(
        'https://koshish-backend.vercel.app/api/result/finalResult',
        queryParameters: {'year': year, 'type': type},
      );

      log("Status Code: ${response.statusCode}");
      log("Status Message: ${response.statusMessage}");

      if (response.statusCode == 200) {
        List<Map<String, dynamic>> resultList = List<Map<String, dynamic>>.from(response.data['topClasses']);
        log(resultList.toString());
        return resultList;
      } else if (response.statusCode == 404) {
        return [];
      } else {
        log("Unexpected Status Code: ${response.statusCode}");
        return [];
      }
    } on DioException catch (e) {
      log("DioException: ${e.response?.statusCode ?? "No Status Code"}");
      log("Error Message: ${e.response?.statusMessage ?? e.message}");
      log("Response Data: ${e.response?.data ?? "No Response Data"}");
      return [];
    } catch (e) {
      log("Unexpected Error: $e");
      return [];
    }
  }

}
