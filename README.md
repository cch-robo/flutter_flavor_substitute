# flavor_substitute

Flutter 疑似 flavor ライブラリ.


## ライブラリの概要

IntelliJ IDEA 系の Before lunch オプションを使い、
疑似 flavor 指定による debug/staging/release環境 ごとにリソースを切り替えるコンセプト・ライブラリです。

1. `flavor_substitute` ライブラリの導入と事前設定を行い、

1. **flavor 切替リソース・ディレクトリ** のルートに、
**選択flavorプロパティファイル**、**切替リソース設定プロパティファイル** を追加し、

1. **flavor 切替リソース・ディレクトリ** の flavor ごとのサブディレクトリに、
flavor ごとに切り替える、**グローバル・プロパティファイル**、**リソースファイル** を用意しておくことで、

1. 疑似 flavor 指定ごとに、接続先サーバや固有アプリ名（バンドルID、アプリケーションID）、
および GoogleService-Info.plist や google-service.json を切り替えられるようにします。


*IntelliJ IDEA 系の Before lunch オプションを使わなくても、'$ flutter run` を実行する前に、
`$ dart prebuild_main.dart debug` のように **ビルド前リソース切替スクリプト** を実行させれば、
同様の効果が得られます。*



## `flavor_substitute` ライブラリの導入と事前設定

### 1. **pubspec.yaml** での`flavor_substitute`ライブラリ導入

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


### 5. IntelliJ IDEA 系の Before lunch オプションの設定

疑似 flavor ごとの **ビルド前リソース切替スクリプト** が実行できるよう、IntelliJ IDEA 系の **Before lunch** オプションを設定します。

IntelliJ IDEA 系の Run > Edit Configurations... からの **Before lunch** オプションの設定については、以下の資料を参照ください。

[Before lunch オプションを使って Flutterでstaging/release環境を切り替える](https://drive.google.com/open?id=18y34btiLo8HUXDcn7Z3UufXqvNElFYPlZ9Cou1kFnCs).



## example 説明

example では、flavor (debug/staging/release)ごとに、
アプリ名(iOS⇒バンドルID,Android⇒applicationId)と画面タイトル(グローバル・プロパティのTITLE_PREFIX)が切り替わります。

iOS と Android における切り替えリソースと設定の違いは、下記のようになっています。

* iOS
ios/Runner/Info.plist の CFBundleIdentifier キーでバンドルID、CFBundleName キーでアプリ名を切り替えています。

* Android
android/gradle.properties の flavorApplicationI プロパティでアプリケーションID(アプリパッケージ名)、
android/app/src/main/res/string.xml の app_name でアプリ名を切り替えています。
  * android/app/build.gradle の applicationId と android/app/src/main/AndroidManifest.xml の label で、切り替えリソースを参照していることに注意。



## 関連資料

Flutter における、ビルド構成切り替えの基本や問題点や、
当該疑似 flavor および、

IntelliJ IDEA 系の Run > Edit Configurations... からの
Before lunch オプションの設定については、以下の資料を参照ください。

[Before lunch オプションを使って Flutterでstaging/release環境を切り替える](https://drive.google.com/open?id=18y34btiLo8HUXDcn7Z3UufXqvNElFYPlZ9Cou1kFnCs).
