import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class CustomCacheManager extends CacheManager {
  static const String key = 'customCache';

  static final CustomCacheManager _instance = CustomCacheManager._internal();

  factory CustomCacheManager() {
    return _instance;
  }

  CustomCacheManager._internal()
      : super(
    Config(
      key,
      stalePeriod: const Duration(days: 365 * 100), // 100 years
      maxNrOfCacheObjects: 1000000,
      repo: JsonCacheInfoRepository(databaseName: key),
      fileService: HttpFileService(),
    ),
  );
//
//   @override
//   Future<FileInfo> getFile(String url, {bool force = false}) async {
//     print('Fetching file for URL: $url');
//     return super.getFile(url, force: force);
//   }
//
//   @override
//   Future<FileInfo> downloadFile(String url, {Map<String, String>? headers}) async {
//     print('Downloading file from URL: $url');
//     return super.downloadFile(url, headers: headers);
//   }
 }
