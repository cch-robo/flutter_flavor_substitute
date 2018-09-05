import 'dart:io';
import 'dart:async';
import 'package:flavor_substitute/pre_build.dart';



/// # PreBuild 用スクリプト
///
/// flutter コマンドの --flavor オプションを使った、
/// Android Studio の Product Flavor や Xcode の Scheme でのビルド設定切り替えの代わりに、
/// FlavorSubstitute（Flavor 代用）クラスを使って環境ごとのリソース切り替えを行わせるスクリプトです。
///
/// リソース切替操作が行なわれるよう、
/// **ビルド前時** にこのスクリプトを実行させる必要があります。
///
/// * ビルド前時のスクリプトには、第一引数に flavor値(例：debug や staging など) を指定してください。
void main([List<String> args]) async {
  try {
    if (args != null && args.length == 1) {
      // flavor パラメータがある場合
      new FlavorSubstitute.preBuild(args[0]);

      exitCode = 0;
    } else {
      // パラメータ不正の場合
      stderr.writeln("need to specify flavore as the first argument.");
      exitCode = 2;
    }
  } catch (error) {
    stderr.writeln('Something went wrong.');
    stderr.writeln("  type ⇒ ${error?.runtimeType ?? ''}");
    stderr.writeln("  error ⇒ {\n${error?.toString() ?? ''}\n}");
    if (error is Error) {
      stderr.writeln("  stacktrace ⇒ {\n${error?.stackTrace ?? ''}\n}");
    }
    rethrow;
  }
}