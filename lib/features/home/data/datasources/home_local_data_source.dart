import 'dart:convert';

import 'package:flutter/services.dart';

import '../../../../core/constants/asset_constants.dart';
import '../models/home_dashboard_model.dart';

abstract class HomeLocalDataSource {
  Future<HomeDashboardModel> getDashboard();
}

class HomeLocalDataSourceImpl implements HomeLocalDataSource {
  const HomeLocalDataSourceImpl();

  @override
  Future<HomeDashboardModel> getDashboard() async {
    final raw = await rootBundle.loadString(AssetConstants.homeDashboardJson);
    final json = jsonDecode(raw) as Map<String, dynamic>;
    return HomeDashboardModel.fromJson(json);
  }
}
