# リリース準備 要求内容

> **作業ディレクトリ:** `.steering/20260809-release-preparation/`
> **作成日:** 2026-08-09

---

## 1. 今回の作業概要

フェーズ1(MVP)の実装・画像添付・リプライスレッド機能まで完了した「撮影用ポスト画面メーカー」を、Google Play(Android)で正式に公開できる状態に仕上げる。iOS(App Store)対応は今回のスコープ外(署名にmacOS/Xcode環境が必要で、現状の開発環境(devcontainer + Windowsホスト)には無いため)。

姉妹アプリ「撮影用トーク画面メーカー(LINE版、`claude-lineapp`)」の`.steering/20260711-release-preparation/`で実施した内容を踏襲する。

---

## 2. 決定事項

| 項目 | 内容 |
|------|------|
| ストア表示名(日本語) | 撮影用ポスト画面メーカー |
| applicationId(パッケージID) | `com.postapp.fake.fake_post_maker`(変更不要。X表記削除時に既に整理済み) |
| 配信方法 | Google Play(Play Console) |
| 対象プラットフォーム | Android のみ(iOS は将来対応) |

---

## 3. 対応対象

### 3-1. アプリ表示名の変更

- `android:label`(`AndroidManifest.xml`)を `Fake Post Maker` → 「撮影用ポスト画面メーカー」に変更
- applicationId/namespace・iOS Bundle Identifierは変更不要(既に対応済み)
- `pubspec.yaml` の `name`(Dartパッケージ名)は内部名称のため変更不要。`description`は必要に応じて見直す

### 3-2. アプリアイコン

- 現在Flutterデフォルトアイコンのままのため、正式なアプリアイコンを作成し全解像度(mipmap-*)に反映

### 3-3. リリースビルド・署名

- `android/app/build.gradle.kts` への署名設定の組み込みは今回のセッションで既に対応済み(`key.properties`を読み込み、存在する場合のみreleaseで使う方式)
- 残作業:リリース用keystore(署名鍵)の生成、`android/key.properties`の作成(いずれもユーザー本人が対話的に実施)、リリースAAB(Android App Bundle)のビルド確認

### 3-4. Play Console登録・ストア掲載情報

- Google Play Console アカウント登録($25、ユーザー本人の作業)
- ストア掲載情報:アプリ名、簡単な説明、詳細な説明、スクリーンショット、フィーチャーグラフィック
- コンテンツレーティング質問票への回答
- データセーフティフォーム(フォトライブラリアクセスの申告)

### 3-5. プライバシーポリシー

- 画像添付・画像書き出し機能で端末の写真ライブラリにアクセスするため、Play Store公開には必須
- 公開先(GitHub Pages)を含めて作成

### 3-6. リリース前チェック

- `flutter analyze` クリーン確認(再確認)
- リリースビルドでの実機動作確認(署名済みAAB/APKをエミュレータ or 実機にインストールして確認)

---

## 4. 受け入れ条件

- [ ] アプリ表示名が「撮影用ポスト画面メーカー」に変更されている
- [ ] 正式なアプリアイコンが全解像度に反映されている
- [ ] リリース用keystoreで署名されたAABがビルドできる
- [ ] プライバシーポリシーが作成され、公開URLが用意されている
- [ ] ストア掲載情報(説明文・スクリーンショット等)の下書きが揃っている
- [ ] リリースビルドを実機(エミュレータ)にインストールし、フェーズ1機能一式が問題なく動作する

---

## 5. 制約事項

- iOS(App Store)対応は今回のスコープ外
- フェーズ2機能・買い切り課金の実装は今回のスコープ外
- Play Console登録(アカウント作成・$25の支払い)はユーザー本人が行う
- Google Playの審査・公開自体(実際のリリースボタンを押す操作)はユーザー承認のうえで行う
- **既知のリスク:** LINE版の同種作業では、devcontainer(WSL2/Docker Desktop)からWindows側AVDへの`adb`接続が`offline`のまま解消せず、リリースビルドの実機確認が最後まで残った。同じ環境のため今回も再発する可能性が高く、その場合はPlay Consoleの内部テストトラック経由で物理端末から確認する方式に切り替える

---

## 6. 関連ドキュメント

- `docs/product-requirements.md` — プロダクト要求定義書
- `docs/architecture.md` — 技術仕様書
- `.steering/20260801-initial-implementation/` — 初回実装のステアリング
- 参考:`claude-lineapp`リポジトリの`.steering/20260711-release-preparation/`(姉妹アプリの同種作業)
