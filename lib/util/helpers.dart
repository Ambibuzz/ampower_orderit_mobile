import 'dart:io';
import 'package:orderit/locators/locator.dart';
import 'package:orderit/common/services/storage_service.dart';
import 'package:orderit/util/enums.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:html/parser.dart';

Future initDb() async {
  await locator.get<StorageService>().initHiveStorage();
  await locator<StorageService>().initHiveBox('offline');
  await locator<StorageService>().initHiveBox('config');
}

Future<String> getDownloadPath() async {
  if (defaultTargetPlatform == TargetPlatform.android) {
    return '/storage/emulated/0/Download/';
  } else if (defaultTargetPlatform == TargetPlatform.iOS) {
    var downloadsDirectory = await getApplicationDocumentsDirectory();
    return downloadsDirectory.path;
  }
  return '';
}

Future<bool> verifyOnline() async {
  var isOnline = false;
  try {
    final result = await InternetAddress.lookup('google.com');
    if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
      isOnline = true;
    } else {
      isOnline = false;
    }
  } on SocketException catch (_) {
    isOnline = false;
  }

  return isOnline;
}

String parseHtmlString(String htmlString) {
  var parsedString = '';
  final document = parse(htmlString);
  if (document.body?.text.isNotEmpty == true) {
    parsedString = parse(document.body?.text).documentElement?.text ?? '';
  }
  return parsedString;
}

//Split String by first occurance
List<String> split(String string, String separator, {int max = 0}) {
  var result = <String>[];

  if (separator.isEmpty) {
    result.add(string);
    return result;
  }

  while (true) {
    var index = string.indexOf(separator, 0);
    if (index == -1 || (max > 0 && result.length >= max)) {
      result.add(string);
      break;
    }

    result.add(string.substring(0, index));
    string = string.substring(index + separator.length);
  }

  return result;
}

Future fileShare(String path, String title, String text) async {
  await Share.shareXFiles(
    [XFile(path)],
    text: text,
  );
}

String defaultDateFormat(String date) {
  return DateFormat('dd-MM-yyyy').format(DateTime.parse(date));
}
