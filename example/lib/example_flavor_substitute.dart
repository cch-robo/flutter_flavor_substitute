import 'package:flavor_substitute/pre_build.dart';


/// # PreBuild Flavor 代用クラス
///
/// 独自のリソースファイル上書きを定義するため、
/// FlavorSubstitute を継承して、
/// copyToResources() をオーバーライドしています。
class ExampleFlavorSubstitute extends FlavorSubstitute {

    /// ビルド前の flavor 設定を行います。（リソース上書きオプションを利用）
  ExampleFlavorSubstitute.preBuild(String flavor) {
    new FlavorSubstitute.preBuild(flavor, resourceOverride: this);
  }

  /// Flavor ごとのリソースファイル上書き
  @override
  void copyToResources() {
    final String flavorSubPath = PreBuildFileService.getNormalizePath(BaseFlavor.flavorSubPath, pathSeparator: "/");

    // プロジェクトごとに切替必要かつ可能なリソースが異なるので、
    // ここでは、iOS と Android リソースファイルの切り替えサンプルを示します。
    final String iosSubPath = PreBuildFileService.getNormalizePath("ios", subPath: "/Runner", pathSeparator: "/");
    final String iosPropertyList = "Info.plist";
    final String androidSubPath = PreBuildFileService.getNormalizePath("android", subPath: "/", pathSeparator: "/");
    final String androidGradleProperties = "gradle.properties";
    final String androidResSubPath = PreBuildFileService.getNormalizePath("android", subPath: "/app/src/main/res/values", pathSeparator: "/");
    final String androidString = "strings.xml";

    // flavor に従って、iOS と Android リソースファイルを切り替える
    // iOS では、Runner/Info.plist の CFBundleName や CFBundleIdentifier を切り替えるていることに注意
    // Android では、AndroidManifest.xml の label や app/build.gradle の applicationId を切り替えていることに注意
    SwitchableFlavorResource iosPropertyListResource = new SwitchableFlavorResource(flavor, flavorSubPath, iosSubPath, iosPropertyList);
    iosPropertyListResource.copyTo();
    SwitchableFlavorResource androidGradlePropertiesResource = new SwitchableFlavorResource(flavor, flavorSubPath, androidSubPath, androidGradleProperties);
    androidGradlePropertiesResource.copyTo();
    SwitchableFlavorResource androidStringResource = new SwitchableFlavorResource(flavor, flavorSubPath, androidResSubPath, androidString);
    androidStringResource.copyTo();
  }
}