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
    // ここでは、Android リソースファイルの切り替えサンプルを示します。
    final String androidSubPath = PreBuildFileService.getNormalizePath("android/app", subPath: "/src/main/res/values", pathSeparator: "/");
    final String androidString = "strings.xml";

    // flavor に従って、Android リソースファイルを切り替える
    SwitchableFlavorResource androidStringResource = new SwitchableFlavorResource(flavor, flavorSubPath, androidSubPath, androidString);
    androidStringResource.copyTo();
  }
}