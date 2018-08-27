import 'dart:io';
import 'dart:async';

/// # ビルド前 Flavor 代用クラス
///
/// flutter コマンドの --flavor オプションを使った、
/// Android Studio の Product Flavor や Xcode の Scheme でのビルド設定切り替えの代わりに、
/// 引数で指定された flavor値 ごとに強制的にリソースを切り替えることで、擬似的に flavor を代用します。
///
/// * プロジェクトディレクトリの **flavor** サブディレクトリに flavor ごとのリソースフォルダが作られます。
///
/// * flavor ごとにグローバル・プロパティファイルの参照先の切り替えや、
/// リソースフォルダから Platform ディレクトリへのリソースファイルの強制上書きコピーを行うため、
/// **ビルド前時** と **アプリ起動時** に **切替操作を行う必要があります。**
///
/// ## ビルド前用： FlavorSubstitute#preBuildSetting(String flavor)
/// 引数 flavor に、"debug", "staging", "release" などのリソース切替環境を指定してください。
/// flavor 内容に従ってリソースファイルの強制切り替え(上書きコピー)が行われます。
///
/// ## アプリ起動時用： FlavorSubstitute#lunchApp()
/// preBuildSetting()で指定した flavor 内容に従ってリソースファイルの強制切り替えや、
/// **globalProperty** グローバル・プロパティファイルの参照先を切り替えます。
///
/// ## グローバル・プロパティの使い方
/// FlavorSubstitute#globalProperty は、現在の flavor 指定に従ったプロパティ値を提供します。
///
/// flavor ごとのリソースフォルダに global.properties ファイルを作成し、KEY=VALUE 形式でプロパティを記録しておけば、
/// globalProperty.getProperties()\[KEY\] で、現在の flavor の VALUE が取得できます。
///
/// ## リソースファイル切替の使い方
/// SwitchableFlavorResource は、コンストラクタ引数 flavor, srcSubPath, distSubPath, fileName に従って、
/// リソースフォルダに flavor ごとのサブディレクトリに配置した fileName のリソースファイルを distSubPath に上書きコピーします。
///
/// *srcSubPath, disSubPathは、プロジェクトディレクトリからの相対パスを指定します。*
abstract class BaseFlavor {
  /// flavor プロパティ
  static final String flavorSubPath = "flavor/";
  static final String flavorPropName = "flavor.properties";
  static final String flavorPropKey = "FLAVOR";

  /// グローバル・プロパティ
  static final String globalPropName = "global.properties";

  /// flavor の設定を行います。
  void setup();
}


/// # プロパティ
///
/// 行フォーマットが、Key=Value 形式のプロパティファイルを
/// プロパティ・オブジェクトとして扱えるようにします。
///
/// *任意 KEY のプロパティ値の取得や、新規プロパティの追加機能が提供されます。*
class Property {
  String _propPath;
  Map<String, String> _propMap;
  File _propFile;

  /// PreBuild用のプロパティを新規作成する
  ///
  /// * require:
  ///   * projectPath プロジェクトディレクトリパス
  ///   * propPath プロパティファイルパス
  Property.forPreBuild(String projectPath, String propPath) {
    _propPath = _getNormalizePath(projectPath + "/", subPath: propPath);
    _propFile = new File(_propPath);

    print("Property.forPreBuild  propPath=$propPath"); // FIXME プロパティ設定開始・デバッグ出力
    if (!_propFile.existsSync()) {
      _propFile.createSync(recursive: true);
    }

    _propMap = new Map<String, String>();
    List<String> lines = _propFile.readAsLinesSync();
    _setProperties(lines, _propMap);
  }

  /// Application用のプロパティを作成する
  ///
  /// * require:
  ///   * _propPath プロパティファイルパス
  Property.forApp(propPath, List<String> lines) {
    print("Property.forApp  propPath=$propPath"); // FIXME プロパティ設定開始・デバッグ出力
    _propPath = propPath;
    _propMap = new Map<String, String>();
    _setProperties(lines, _propMap);
 }

  /// プロパティを追加する
  Future<void> addProperty(String key, String value) async {
    if (_propFile == null) {
      throw new AssertionError("addProperty method can be only use for PreBuild!");
    }

    IOSink ioSink = _propFile.openWrite(mode: FileMode.append);
    ioSink.writeln("${key}=${value}");
    await ioSink.flush();
    await ioSink.close();

    _propMap = new Map<String, String>();
    List<String> lines = _propFile.readAsLinesSync();
    _setProperties(lines, _propMap);
  }

  /// プロパティを取得する
  String getValue(String key) {
    return _propMap != null ? _propMap[key] : null;
  }

  /// 全プロパティをマップとして取得する
  Map<String, String> getProperties() {
    return _propMap;
  }

  void _setProperties(List<String> lines, Map<String, String> props) {
    if (lines == null || lines.isEmpty) {
      return;
    }

    lines.forEach((String line) {
      String first = line.replaceFirst(new RegExp("=.*\$"), "");
      String last = line.replaceFirst(new RegExp("^[^=]+="), "");
      if (first == null || last == null || first == last) return;
      String key = first;
      String value = last;
      props.addAll({key: value});
      print("Property  {$key:$value}"); // FIXME プロパティ・デバッグ出力
    });
  }

  /// プロパティファイルを削除する。
  void deletePropertyFile() {
    if (_propFile == null) {
      throw new AssertionError("delete method can be only use for PreBuild!");
    }
    _propFile.deleteSync();
  }

  /// PreBuild用に指定パスをプラットフォーム用に正式化します。
  ///
  /// * require:
  ///   * path パス文字列
  /// * optional:
  ///   * subPath パス文字列の追加パス
  ///   * pathSeparator パス文字列のパス区切り文字（デフォルトは '/'）
  /// * return:
  ///   * プラットフォーム用に正式化したパス
  static String _getNormalizePath(String path, {subPath: "", pathSeparator: "/"}) {
    return ((path ?? "") + subPath).replaceAll(pathSeparator, Platform.pathSeparator);
  }
}
