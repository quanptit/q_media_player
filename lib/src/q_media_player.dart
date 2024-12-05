import 'dart:async';

import 'package:applovin_max/applovin_max.dart';
import 'package:common_utils/l.dart';

// Completer<bool>? _completer = null;
// Future<bool> test() {
//   if (_completer != null) return _completer!.future;
//   _completer = Completer();
//   Future.delayed(
//     Duration(seconds: 3),
//     () => _completer?.complete(true),
//   );
//   return _completer!.future;
// }
// test1(){
//   test().then((value) => print('1'));

//   Future.delayed(Duration(seconds: 1), () => test().then((value) => print('2')),);
// }

class MAXInitUtils {
  //region singleton
  static final MAXInitUtils _singleton = MAXInitUtils._internal();
  factory MAXInitUtils() {
    return _singleton;
  }
  MAXInitUtils._internal();
  //endregion
  static MAXInitUtils get instance => _singleton;

  Completer<bool>? _completer;
  bool isInitialized = false;
  bool isIniting = false;

  static Future<bool> initAds(String sdkKey){
    return instance._initAds(sdkKey);
  }
  static void showMediationDebugger(){
    AppLovinMAX.showMediationDebugger();
  }

  Future<bool> _initAds(String sdkKey) {
    // AppLovinMAX.setVerboseLogging(true); 
    // var isInitialized  = await AppLovinMAX.isInitialized();
    // if(isInitialized.isTrue()) return;

    if (isInitialized) return Future.value(true);
    if (isIniting && _completer != null) return _completer!.future;
     L.d("AppLovinMAX.initialize");
    // AppLovinMAX.targetingData.maximumAdContentRating = AdContentRating.everyoneOverTwelve;
    isIniting = true;
    _completer = Completer();
    AppLovinMAX.initialize(sdkKey).then((value) {
      isIniting = false;
      isInitialized = true;
      _completer?.complete(true);
      _completer = null;
      // AppLovinMAX.targetingData.maximumAdContentRating = AdContentRating.everyoneOverTwelve;
    }).onError((error, stackTrace) {
      isIniting = false;
      _completer?.completeError(error ?? "ERROR AppLovinMAX init", stackTrace);
      _completer = null;
    });
    return _completer!.future;
  }
}
