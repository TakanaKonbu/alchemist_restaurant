import 'dart:io';
import 'package:flutter/foundation.dart';

class AdHelper {
  static String get rewardedAdUnitId {
    // デバッグモード（テスト環境）ではテスト用IDを返す
    if (kDebugMode) {
      return 'ca-app-pub-3940256099942544/5224354917';
    }

    // リリースモード（本番環境）ではプラットフォームに応じたIDを返す
    if (Platform.isAndroid) {
      return 'ca-app-pub-2836653067032260/6099149659';
    } else if (Platform.isIOS) {
      return 'ca-app-pub-2836653067032260/3273675763';
    } else {
      // サポートされていないプラットフォーム（例：Web）の場合
      throw UnsupportedError('Rewarded ads are not supported on this platform');
    }
  }
}