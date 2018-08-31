import 'dart:async';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flavor_substitute/src/flavor/base_flavor.dart';

/// # Application Flavor 代用クラス
///
/// flutter コマンドの --flavor オプションを使った、
/// Android Studio の Product Flavor や Xcode の Scheme でのビルド設定切り替えの代わりに、
/// 引数で指定された flavor値 ごとに強制的にリソースを切り替えることで、擬似的に flavor を代用します。
///
/// * プロジェクトディレクトリの **flavor** サブディレクトリに flavor ごとのリソースフォルダとプロパティファイルおよび、
/// **pubspec.yaml** の assets: に flavor 用プロパティファイルの設定追加が必要です。
/// ```
/// assets:
///   ... ’debug’ flavor を使う場合のプロパティファイル用アセット設定
///   - flavor/flavor.properties
///   - flavor/debug/global.properties
/// ```
///
/// * flavor ごとにグローバル・プロパティファイルの参照先の切り替えを行うため、
/// **アプリ起動時** に Flavor切替操作を行う必要があります。**
///
/// ## アプリ起動時用： FlavorSubstitute#forApp()
/// **globalProperty** グローバル・プロパティファイルの参照先を切り替えます。
///
/// ## グローバル・プロパティの使い方
/// FlavorSubstitute#globalProperty は、現在の flavor 指定に従ったプロパティ値を提供します。
///
/// flavor ごとのリソースフォルダに global.properties ファイルを作成し、KEY=VALUE 形式でプロパティを記録しておけば、
/// globalProperty.getProperties()\[KEY\] で、現在の flavor の VALUE が取得できます。
class FlavorSubstitute extends BaseFlavor {
  /// flavor プロパティ
  Property _flavorProperty;
  String _flavor;

  /// グローバル・プロパティ
  Property _globalProperty;

  /// インスタンス
  static FlavorSubstitute _instance;

  /// コンストラクタ
  FlavorSubstitute.forFlutter() {
    if(_instance == null){
      _instance = this;
    }
  }

  /// flavor 設定
  @override
  Future<void> setup() async {
    /// 現在の flavor を取得、
    String flavorPropPath = BaseFlavor.flavorSubPath + BaseFlavor.flavorPropName;
    List<String> flavorLines = await _loadAsset(flavorPropPath);
    _flavorProperty = new Property.forFlutter(flavorPropPath, flavorLines);
    _flavor = _flavorProperty.getProperties()[BaseFlavor.flavorPropKey];
    if (_flavor == null) throw new AssertionError("flavor is missing.");

    /// 現在の flavor 環境用のグローバル・プロパティを取得
    String flavorGlobalPath = BaseFlavor.flavorSubPath + _flavor + "/" + BaseFlavor.globalPropName;
    List<String> globalLines = await _loadAsset(flavorGlobalPath);
    _globalProperty = new Property.forFlutter(flavorGlobalPath, globalLines);
    if (_globalProperty == null) throw new AssertionError("flavor globalProperty missing.");
  }

  Future<List<String>> _loadAsset(String propAssetPath) async {
    String lines =  await rootBundle.loadString(propAssetPath);
    return lines.split("\n").toList();
  }

  /// アプリの flavor プロパティ設定を行います。
  static Future<void> setupProperty() async {
    new FlavorSubstitute.forFlutter();
    await _instance.setup();
  }

  /// 現在の flavor
  static String get flavor => _instance._flavor;

  /// 現在の flavor 用のグローバル・プロパティ
  static Property get globalProperty => _instance._globalProperty;
}
