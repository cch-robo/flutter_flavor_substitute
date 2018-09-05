import 'dart:io';
import 'dart:async';
import 'package:flavor_substitute/src/flavor/base_flavor.dart';

/// # PreBuild Flavor 代用クラス
///
/// flutter コマンドの --flavor オプションを使った、
/// Android Studio の Product Flavor や Xcode の Scheme でのビルド設定切り替えの代わりに、
/// 引数で指定された flavor値 ごとに強制的にリソースを切り替えることで、擬似的に flavor を代用します。
///
/// * プロジェクトディレクトリの **flavor** サブディレクトリに flavor ごとのリソースフォルダが作られます。
///
/// * flavor ごとにグローバル・プロパティファイルの参照先の切り替えや、
/// リソースフォルダから Platform ディレクトリへのリソースファイルの強制上書きコピーを行うため、
/// **ビルド前時** に **切替操作を行う必要があります。**
///
/// ## ビルド前用： FlavorSubstitute#preBuildSetting(String flavor)
/// 引数 flavor に、"debug", "staging", "release" などのリソース切替環境を指定してください。
/// flavor 内容に従ってリソースファイルの強制切り替え(上書きコピー)が行われます。
///
/// ## グローバル・プロパティの使い方
/// FlavorSubstitute#globalProperty は、現在の flavor 指定に従ったプロパティ値を提供します。
///
/// flavor ごとのリソースフォルダに global.properties ファイルを作成し、KEY=VALUE 形式でプロパティを記録しておけば、
/// globalProperty.getProperties()\[KEY\] で、現在の flavor の VALUE が取得できます。
///
/// ## リソースファイルの切替(上書きコピー)を使う場合
/// flavor ごとに、プラットフォーム側の Android や iOS のリソースファイルを切替(上書きコピー)できます。
///
/// flavor ごとに Android や iOS のリソースファイルを切替(上書きコピー)する場合は、
/// プロジェクトディレクトリの **flavor** サブディレクトリに resource.properties ファイルを作成し、
/// KEY=VALUE ⇒ プラットフォームリソースファイル相対パス=リソースファイル名 形式でプロパティを記録して、
/// flavor ごとのリソースフォルダに flavor ごとに変更した内容のリソースファイルを配置しておいてください。
///
/// ## リソースファイル切替のユーティリティ
/// リソースファイル切替(強制上書きコピー)のユーティリティとして、SwitchableFlavorResource クラスを利用しています。
///
/// SwitchableFlavorResource は、コンストラクタ引数 flavor, srcSubPath, distSubPath, fileName に従って、
/// リソースフォルダに flavor ごとのサブディレクトリに配置した fileName のリソースファイルを distSubPath に上書きコピーします。
///
/// *srcSubPath, disSubPathは、プロジェクトディレクトリからの相対パスを指定します。*
class FlavorSubstitute extends BaseFlavor {
  /// プロジェクトディレクトリパス
  String _projectPath;

  /// flavor プロパティ
  Property _flavorProperty;
  String _flavor;

  /// リソース設定・プロパティ
  Property _resourceProperty;

  /// グローバル・プロパティ
  Property _globalProperty;

  /// インスタンス
  static FlavorSubstitute _instance;

  /// デフォルトコンストラクタ
  FlavorSubstitute();

  /// ビルド前の flavor 設定を行います。
  ///
  /// * require:
  ///   * flavor フレーバー
  FlavorSubstitute.preBuild(String flavor) {
    if(_instance == null){
      _flavor = flavor;
      setup();
      _instance = this;
    }
  }

  @override
  Future<void> setup() async {
    /// プロジェクト・ディレクトリ取得
    _projectPath = PreBuildFileService.getProjectDirectory();

    /// flavor プロパティファイル作成
    String flavorSub = PreBuildFileService
        .getNormalizePath(BaseFlavor.flavorSubPath, subPath: BaseFlavor.flavorPropName, pathSeparator: "/");
    if (PreBuildFileService.isFileExist(flavorSub)) {
      PreBuildFileService.deleteFile(flavorSub);
    }

    /// flavor プロパティ作成
    _flavorProperty = new Property.forDart(_projectPath, BaseFlavor.flavorSubPath + BaseFlavor.flavorPropName);
    await _flavorProperty.addProperty(BaseFlavor.flavorPropKey, _flavor);

    /// flavor ごとのグローバルプロパティ切替
    _switchFlavorProperty();

    /// リソース設定プロパティ作成
    _resourceProperty = new Property.forDart(_projectPath, BaseFlavor.flavorSubPath + BaseFlavor.resourcePropName);

    /// flavor ごとのリソースファイル強制上書きコピー
    _copyToResources();
  }

  /// flavor ごとのグローバルプロパティ切替
  void _switchFlavorProperty() {
    if (_flavor == null) throw AssertionError("flavor is missing.");

    // 現在の flavor 用のリソースを収めるワークディレクトリを取得
    String flavorGlobalSub = PreBuildFileService
        .getNormalizePath(BaseFlavor.flavorSubPath, subPath: _flavor, pathSeparator: "/");
    if (!PreBuildFileService.isDirectoryExist(flavorGlobalSub)) {
      PreBuildFileService.createDirectory(flavorGlobalSub);
    }

    // 現在の flavor 用のグローバル・プロパティを取得
    String flavorGlobalPropPath = PreBuildFileService.getNormalizePath(
        (flavorGlobalSub + "/"),
        subPath:(BaseFlavor.globalPropName),
        pathSeparator: "/");
    _globalProperty = new Property.forDart(_projectPath, flavorGlobalPropPath);
  }

  /// Flavor ごとのリソースファイル上書き
  void _copyToResources() {
    if (_flavor == null) throw AssertionError("flavor is missing.");

    // 現在の flavor 用のリソースを収めるワークディレクトリを取得
    String flavorResourceSub = PreBuildFileService
        .getNormalizePath(BaseFlavor.flavorSubPath, subPath: "", pathSeparator: "/");
    if (!PreBuildFileService.isDirectoryExist(flavorResourceSub)) {
      PreBuildFileService.createDirectory(flavorResourceSub);
    }

    // リソースファイル上書き
    Map<String,String> resources = _resourceProperty.getProperties();
    resources.keys.forEach((String key){
      String distResourceFilePath = key;
      String distResourceFileName = resources[key];
      if (distResourceFilePath != null) {
        if (!PreBuildFileService.isFileExist(distResourceFilePath)) return;

        File resourceFile = PreBuildFileService.getFile(distResourceFilePath);
        String platformResourceSub = resourceFile.parent.path;
        String platformResourceName =PreBuildFileService.getFileName(distResourceFilePath);
        SwitchableFlavorResource resource = new SwitchableFlavorResource(flavor, flavorResourceSub, platformResourceSub, platformResourceName);
        resource.copyTo();
      }
    });
  }

  /// 現在の flavor
  String get flavor => _instance._flavor;

  /// 現在の flavor 用のグローバル・プロパティ
  Property get globalProperty => _instance._globalProperty;
}


/// PreBuild用の Flavor リソース切替
///
/// flavor 指定に従って、入力元のリソースファイルを出力先にコピー（上書き）可能にします。
class SwitchableFlavorResource {
  String _projectPath;
  String _flavor;
  String _srcPath;
  String _distPath;
  String _fileName;
  String _pathSeparator;
  bool _isSrcFileExist;

  /// 可変切替リソース・コンストラクタ
  ///
  /// * require:
  ///   * flavor フレーバー
  ///   * srcSubPath 入力元のサブパス （プロジェクトパスからの相対位置）
  ///   * distSubPath 出力先のサブパス （プロジェクトパスからの相対位置）
  ///   * fileName リソースファイル名
  /// * optional:
  ///   * pathSeparator パス文字列のパス区切り文字（デフォルトは '/'）
  SwitchableFlavorResource(String flavor, String srcSubPath, String distSubPath, String fileName, {pathSeparator: "/"}) {
    if (flavor == null || srcSubPath == null || distSubPath == null || fileName == null || pathSeparator == null) {
      throw new AssertionError("SwitchableResource constructor parameters must not be a null.");
    }

    _pathSeparator = pathSeparator;
    _projectPath = PreBuildFileService.getProjectDirectory() + "/";
    _flavor = flavor;
    _srcPath = PreBuildFileService.getNormalizePath((_projectPath + srcSubPath), subPath: _flavor, pathSeparator: _pathSeparator);
    _distPath = PreBuildFileService.getNormalizePath((_projectPath + distSubPath), pathSeparator: _pathSeparator);
    bool isSrcMissing = !PreBuildFileService.isDirectoryExist(_srcPath);
    bool isDistMissing = !PreBuildFileService.isDirectoryExist(_distPath);
    if (isSrcMissing || isDistMissing) {
      throw AssertionError("SwitchableResource parameters thease srcSubPath and distSubPath are must be exist.");
    }

    _fileName = fileName;
    bool isSrcFileExist = PreBuildFileService.isFileExist((_srcPath + _pathSeparator), subPath: _fileName);
    _isSrcFileExist = isSrcFileExist;
  }

  String get srcSupPath => _getSubPath(_srcPath);
  String get distSupPath => _getSubPath(_distPath);
  String get fileName => _fileName;
  bool get isResourceExist => _isSrcFileExist;

  /// 入力元のリソースファイルを出力先に上書きコピーします。
  void copyTo() {
    if (isResourceExist) {
      PreBuildFileService.copyTo(_srcPath, _distPath, _fileName);
    }
  }

  String _getSubPath(String subAbsolutePath) {
    return subAbsolutePath.replaceFirst(_projectPath, "");
  }
}


/// PreBuild用のファイル操作や情報を提供する
class PreBuildFileService {
  /// プロジェクトディレクトリを取得する。
  ///
  /// * return:
  ///   * プロジェクトディレクトリ
  static String getProjectDirectory() {
    // スクリプトが実行される起点パスより、
    // プロジェクト・パスを推定する。
    String projectPth = Directory.current.path;
    return projectPth;
  }

  /// 指定パスにファイルが存在するかチェックします。
  ///
  /// * require:
  ///   * path パス文字列
  /// * optional:
  ///   * subPath パス文字列の追加パス
  ///   * pathSeparator パス文字列のパス区切り文字（デフォルトは '/'）
  /// * return:
  ///   * ファイル存在可否 （true:存在する, false:存在しない）
  static bool isFileExist(String path, {subPath: "", pathSeparator: "/"}) {
    String checkPath = getNormalizePath(
        path, subPath: subPath, pathSeparator: pathSeparator);
    return new File(checkPath).existsSync();
  }

  /// 指定パスのファイルを取得します。
  ///
  /// * require:
  ///   * path パス文字列
  /// * optional:
  ///   * subPath パス文字列の追加パス
  ///   * pathSeparator パス文字列のパス区切り文字（デフォルトは '/'）
  /// * return:
  ///   * 取得したファイル
  static File getFile(String path, {subPath: "", pathSeparator: "/"}) {
    String filePath = getNormalizePath(
        path, subPath: subPath, pathSeparator: pathSeparator);
    File file = new File(filePath);
    return file;
  }

  /// 指定パスのファイル名を取得します。
  ///
  /// * require:
  ///   * path パス文字列
  /// * optional:
  ///   * subPath パス文字列の追加パス
  ///   * pathSeparator パス文字列のパス区切り文字（デフォルトは '/'）
  /// * return:
  ///   * 取得したファイル名
  static String getFileName(String path, {subPath: "", pathSeparator: "/"}) {
    File file = getFile(path, subPath: subPath, pathSeparator: pathSeparator);
    if (file.existsSync()) {
      String dirPath = file.parent.path;
      String fileName = file.path.replaceAll(dirPath, "").replaceFirst(Platform.pathSeparator, "");
      return fileName;
    }
    return null;
  }

  /// 指定パスにファイルを作成します。
  ///
  /// * require:
  ///   * path パス文字列
  /// * optional:
  ///   * subPath パス文字列の追加パス
  ///   * pathSeparator パス文字列のパス区切り文字（デフォルトは '/'）
  /// * return:
  ///   * 作成したファイル
  static File createFile(String path, {subPath: "", pathSeparator: "/"}) {
    String createPath = getNormalizePath(
        path, subPath: subPath, pathSeparator: pathSeparator);
    File created = new File(createPath);
    created.createSync(recursive: true);
    return created;
  }

  /// 指定パスのファイルを削除します。
  ///
  /// * require:
  ///   * path パス文字列
  /// * optional:
  ///   * subPath パス文字列の追加パス
  ///   * pathSeparator パス文字列のパス区切り文字（デフォルトは '/'）
  /// * return:
  ///   * 削除したファイル
  static File deleteFile(String path, {subPath: "", pathSeparator: "/"}) {
    String deletePath = getNormalizePath(
        path, subPath: subPath, pathSeparator: pathSeparator);
    File deleted = new File(deletePath);
    deleted.deleteSync();
    return deleted;
  }

  /// 指定パスにディレクトリが存在するかチェックします。
  ///
  /// * require:
  ///   * path パス文字列
  /// * optional:
  ///   * subPath パス文字列の追加パス
  ///   * pathSeparator パス文字列のパス区切り文字（デフォルトは '/'）
  /// * return:
  ///   * ディレクトリ存在可否 （true:存在する, false:存在しない）
  static bool isDirectoryExist(String path, {subPath: "", pathSeparator: "/"}) {
    String checkPath = getNormalizePath(
        path, subPath: subPath, pathSeparator: pathSeparator);
    return new Directory(checkPath).existsSync();
  }

  /// 指定パスにディレクトリを作成します。
  ///
  /// * require:
  ///   * path パス文字列
  /// * optional:
  ///   * subPath パス文字列の追加パス
  ///   * pathSeparator パス文字列のパス区切り文字（デフォルトは '/'）
  /// * return:
  ///   * 作成したディレクトリ
  static Directory createDirectory(String path,
      {subPath: "", pathSeparator: "/"}) {
    String createPath = getNormalizePath(
        path, subPath: subPath, pathSeparator: pathSeparator);
    Directory created = new Directory(createPath);
    created.createSync(recursive: true);
    return created;
  }

  /// 指定パスのディレクトリを削除します。
  ///
  /// * require:
  ///   * path パス文字列
  /// * optional:
  ///   * subPath パス文字列の追加パス
  ///   * pathSeparator パス文字列のパス区切り文字（デフォルトは '/'）
  /// * return:
  ///   * 削除したディレクトリ
  static Directory deleteDirectory(String path,
      {subPath: "", pathSeparator: "/"}) {
    String deletePath = getNormalizePath(
        path, subPath: subPath, pathSeparator: pathSeparator);
    Directory deleted = new Directory(deletePath);
    deleted.deleteSync();
    return deleted;
  }

  /// 指定パスのファイルを宛先にコピーします。
  ///
  /// * require:
  ///   * srcPath 入力元ディレクトリパス文字列
  ///   * distPath 出力先ディレクトリパス文字列
  ///   * fileName ファイル名
  /// * optional:
  ///   * pathSeparator パス文字列のパス区切り文字（デフォルトは '/'）
  /// * return:
  ///   * コピーしたファイル
  static File copyTo(String srcPath, String distPath, String fileName,
      {pathSeparator: "/"}) {
    bool isDistFileExist = isFileExist(
        (distPath + pathSeparator), subPath: fileName,
        pathSeparator: pathSeparator);
    if (isDistFileExist) {
      deleteFile((distPath + pathSeparator), subPath: fileName,
          pathSeparator: pathSeparator);
    }

    String srcFilePath = getNormalizePath(
        (srcPath + pathSeparator), subPath: fileName,
        pathSeparator: pathSeparator);
    String distFilePath = getNormalizePath(
        (distPath + pathSeparator), subPath: fileName,
        pathSeparator: pathSeparator);
    File srcFile = new File(srcFilePath);
    return srcFile.copySync(distFilePath);
  }

  /// 指定パスをプラットフォーム用に正式化します。
  ///
  /// * require:
  ///   * path パス文字列
  /// * optional:
  ///   * subPath パス文字列の追加パス
  ///   * pathSeparator パス文字列のパス区切り文字（デフォルトは '/'）
  /// * return:
  ///   * プラットフォーム用に正式化したパス
  static String getNormalizePath(String path,
      {subPath: "", pathSeparator: "/"}) {
    return ((path ?? "") + subPath).replaceAll(
        pathSeparator, Platform.pathSeparator);
  }
}