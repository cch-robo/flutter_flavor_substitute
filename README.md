# flavor_substitute

Flutter 疑似 flavor ライブラリ.


## ライブラリの概要

IntelliJ IDEA 系の Before lunch オプションを使い、  
疑似 flavor 指定による debug/staging/release環境 ごとにリソースを切り替えるコンセプト・ライブラリです。

1. **flavor_substitute ライブラリの導入と事前設定** を行います。

1. **flavor 切替リソース・ディレクトリ** を新設し、  
**選択flavorプロパティファイル**、**切替リソース設定プロパティファイル** を追加します。  
*選択flavorプロパティファイル名 ⇒ flavor.propterties  
切替リソース設定ファイル名 ⇒ resource.properties  
切替リソース設定プロパティフアイルの行フォーマットは、リソースファイル相対パス=ファイル名です。  
例）`ios/Runner/Info.plist=Info.plist`*

1. **flavor 切替リソース・ディレクトリ** の flavor ごとのサブディレクトリに、  
flavor ごとに切り替える、**グローバル・プロパティファイル**、**リソースファイル** を用意しておきます。  
*グローバル・プロパティファイル名 ⇒ grobal.properties  
リソースファイル名 ⇒ GoogleService-Info.plist など  
グローバル・プロパティファイルの行フォーマットは、KEY=VALUE 形式です。*

1. 以上のような設定で、  
疑似 flavor 指定ごとに、グローバル・プロパティを使って接続先サーバを切り替えたり、  
切替リソース設定プロパティとリソースファイルを使って、固有アプリ名(バンドルID、アプリケーションID)や **GoogleService-Info.plist** や **google-service.json** を切り替えられるようにします。


*IntelliJ IDEA 系の Before lunch オプションを使わなくても、  
`$ flutter run` を実行する前に、`$ dart prebuild_main.dart debug` のように  
**ビルド前リソース切替スクリプト** を事前に実行させれば、同様の効果が得られます。*



## flavor_substitute ライブラリの導入と事前設定

### 1. **pubspec.yaml** での **flavor_substitute** ライブラリ導入

**pubspec.yaml** の dependencies に、
`flavor_substitute`ライブラリ導入の記述を追加します。

```yaml
dependencies:
  flavor_substitute:
    git:
      url: git://github.com/cch-robo/flutter_flavor_substitute.git
```


### 2. **pubspec.yaml** へのプロパティ・アセット追加

**pubspec.yaml** の assets に、
疑似 flavor 関連のプロパティ・ファイルを追加します。

```yaml
flutter:

  assets:
    # 疑似 flavor に debug/staging/release を使う場合
    - flavor/flavor.properties
    - flavor/debug/global.properties
    - flavor/staging/global.properties
    - flavor/release/global.properties
```


### 3. .dart エントリポイントへのプロパティ有効化の追加

.dart エントリポイントとは、`main.dart`のような、flutter アプリを起動する dart ファイルを示します。

flavor ごとにプロパティファイルが切り替わるよう、main 関数に FlavorSubstitute.setupProperty() を追加してください。


```dart
import 'package:flavor_substitute/app_lunch.dart';

void main() async {
  await FlavorSubstitute.setupProperty();
  runApp(new MyApp());
}
```


### 4. ビルド前リソース切替スクリプトの設置

**プロジェクト・ディレクトリ** に、exampleの `prebuild_main.dart` ファイルをコピーします。

```dart
import 'dart:io';
import 'package:flavor_substitute/pre_build.dart';

/// # PreBuild 用スクリプト
/// 第一引数に flavor値(例：debug や staging など) を指定してください。
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
```


### 5. IntelliJ IDEA 系の Before lunch オプションの設定

疑似 flavor ごとの **ビルド前リソース切替スクリプト** が実行できるよう、  
IntelliJ IDEA 系の **Before lunch** オプションを設定します。

IntelliJ IDEA 系の Run > Edit Configurations... からの Before lunch オプションの設定については、  
以下の資料を参照ください。

[Before lunch オプションを使って Flutterでstaging/release環境を切り替える](https://drive.google.com/open?id=18y34btiLo8HUXDcn7Z3UufXqvNElFYPlZ9Cou1kFnCs).



## ライブラリの具体的な利用法

ライブラリの具体的な使い方は、**example ディレクトリ** の各ファイル設定を参考にしてください。
```
example/
 |
 + prebuild-main.xml （ビルド前リソース切替スクリプト）
 |
 + pubspec.yaml （ライブラリの導入とアセット指定を行っている）
 |
 + lib/main.dart （疑似flavorプロパティの有効化と、グローバル・プロパティ値の利用を行っている）
 |
 + flavor/ (flavor切替リソース・ディレクトリ)
     |
     + flavor.properties （選択flavorプロパティファイル）
     + resource.properties （切替リソース設定プロパティファイル）
     |
     + debug/ （ｄｅｂｕｇフレーバ・リソース用サブディレクトリ）
     |  |
     |  + global.properties （debug用のグローバル・プロパティファイル）
     |  + Info.plist
     |  + strings.xml
     |  + gradle.properties
     |
     + staging/ (stagingフレーバ・リソース用サブディレクトリ)
     |  |
     |  + global.properties （staging用のグローバル・プロパティファイル）
     |  + Info.plist
     |  + strings.xml
     |  + gradle.properties
     |
     + release/ （releaseフレーバー・リソース用サブディレクトリ）
        |
        + global.properties （release用のグローバル・プロパティファイル）
        + Info.plist
        + strings.xml
        + gradle.properties
```

## example 説明

example では、flavor (debug/staging/release)ごとに、  
アプリ名(iOS⇒バンドルID, Android⇒applicationId)と、  
画面タイトル(グローバル・プロパティのTITLE_PREFIX)が切り替わります。

iOS と Android における切り替えリソースと設定の違いは、下記のようになっています。

* iOS
ios/Runner/Info.plist の CFBundleIdentifier キーでバンドルID、CFBundleName キーでアプリ名を切り替えています。

* Android
android/gradle.properties の flavorApplicationI プロパティでアプリケーションID(アプリパッケージ名)、
android/app/src/main/res/string.xml の app_name でアプリ名を切り替えています。
  * android/app/build.gradle の applicationId と android/app/src/main/AndroidManifest.xml の label で、切り替えリソースを参照していることに注意。



## 関連資料

Flutter における、ビルド構成切り替えの基本や問題点や、当該疑似 flavor および、  
IntelliJ IDEA 系の Run > Edit Configurations... からの Before lunch オプションの設定については、  
以下の資料を参照ください。

[Before lunch オプションを使って Flutterでstaging/release環境を切り替える](https://drive.google.com/open?id=18y34btiLo8HUXDcn7Z3UufXqvNElFYPlZ9Cou1kFnCs).
