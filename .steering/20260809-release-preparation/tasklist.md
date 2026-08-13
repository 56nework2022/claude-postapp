# リリース準備 タスクリスト

> **作業ディレクトリ:** `.steering/20260809-release-preparation/`
> **作成日:** 2026-08-09

---

## 決定事項(再掲)

- アイコン: Claudeが簡易案を作成し、アーティファクトで確認・承認を得てから適用
- プライバシーポリシー公開先: GitHub Pages(`claude-postapp`は既にPublicリポジトリ)
- keystore生成: ユーザー本人がWindows環境で実施(コマンドは提示済み。devcontainer内にはAndroid SDK/keytool相当の実行環境が無いため代行不可)

---

## Task 1: アプリ表示名変更

- [x] `android/app/src/main/AndroidManifest.xml` の `android:label` を「撮影用ポスト画面メーカー」に変更
- [x] `flutter analyze` でビルド確認

## Task 2: アプリアイコン作成・適用

- [x] Claudeが簡易案(1024×1024マスター画像)を作成し、アーティファクトでユーザーに確認・承認
- [x] `flutter_launcher_icons` を導入し、`assets/icon/app_icon.png` に正方形フルブリード版を配置
- [x] Android全解像度(mipmap-*)に適用し、`flutter analyze`で確認

## Task 3: リリース署名用keystore生成(ユーザー本人作業)

- [x] `keytool -genkeypair` コマンドをユーザー自身のWindows環境で実行し、`upload-keystore.jks` を生成(PowerShellでの識別名入力ループ回避のため`-dname`オプションを使用)
- [x] `android/key.properties` を作成(storePassword/keyPassword/keyAlias/storeFile)。`android/.gitignore`で除外済み
- [x] keystoreファイルとパスワードを安全な場所にバックアップ済み
  - 補足: `upload-keystore.jks`はプロジェクトルート直下に生成されたが、ルート`.gitignore`に除外設定がなく`git status`で未追跡表示になっていた不具合を発見・修正済み(ルート`.gitignore`に`/upload-keystore.jks`・`*.jks`・`*.keystore`を追加)

## Task 4: リリースビルド確認

- [x] `flutter analyze` クリーン確認(devcontainerで実施、問題なし)
- [x] ユーザーのWindows環境で `flutter build appbundle --release` を実行し、署名済みAAB(`build\app\outputs\bundle\release\app-release.aab`, 49.1MB)が生成されることを確認
  - ハマりどころ: `android/app/build.gradle.kts`の`storeFile = file(...)`は`android/app/`からの相対パスで解決される(`key.properties`自体の読み込みは`rootProject.file(...)`で`android/`基準なのとは別)。`upload-keystore.jks`がプロジェクトルートにある場合、`key.properties`の`storeFile`は`../../upload-keystore.jks`(2階層上)が正しい。`../upload-keystore.jks`だと`android/upload-keystore.jks`を探しに行きビルド失敗した

## Task 5: プライバシーポリシー作成・公開

- [x] `docs/privacy-policy.md` を作成(収集情報なし・写真ライブラリはローカル処理のみ・Hiveによる端末内保存の旨を明記)(コミット`aebcb5c`)
- [x] GitHub Pagesを有効化(ユーザー承認のうえ)し、公開URLを確定
  - 補足: Free プランではPrivateリポジトリでGitHub Pagesが使えないため、リポジトリをPublicに変更したうえで有効化(ユーザー本人が実施)
  - 公開URL: `https://56nework2022.github.io/claude-postapp/privacy-policy`(200応答・内容確認済み)

## Task 6: ストア掲載情報ドラフト作成

- [x] `store-listing-draft.md` を作成(アプリ名・簡単な説明・詳細な説明・コンテンツレーティング方針・データセーフティ回答方針・スクリーンショット撮影案)(コミット`e729b31`)
- [x] `screenshot-shooting-guide.md` を作成(撮影シーン別の具体的な操作手順・撮影方法・技術要件・納品先 `assets/store/screenshots/` を明記)
- [ ] ユーザー本人がWindows環境のエミュレータ/実機で7枚のスクリーンショットを撮影し、`assets/store/screenshots/` に配置(devcontainerにはAndroid SDK/ディスプレイが無いため代行不可)

## Task 7: 実機動作確認

- [x] AVDストレージ不足を解消し、Windows環境で`flutter run`(デバッグビルド)によりエミュレータでアプリ起動を確認
- [x] 免責ダイアログの表示・非表示の動作確認、およびフェーズ1機能一式(投稿詳細・タイムライン・画像添付・リプライ・フルスクリーン表示・画像書き出し)が問題なく動作することをエミュレータ(デバッグビルド)で確認
- [ ] `requirements.md` §5の既知リスクを踏まえ、Task 4で生成した**署名済みリリースAAB**をPlay Console内部テストトラックへアップロードし、物理Android端末への配布リンク経由でリリースビルドの動作確認を行う(デバッグビルドとリリースビルドは最適化・署名の有無が異なるため別確認が必要。Play Console登録はユーザー本人の作業)

## Task 8: 最終チェック・引き継ぎ

- [ ] `requirements.md` §4の受け入れ条件を全項目確認
- [ ] Play Console登録・審査提出をユーザー本人の作業として引き継ぐ`handoff.md`を作成

---

## 完了条件

`requirements.md` の受け入れ条件をすべて満たし、Play Consoleへの提出に必要な技術的準備(署名済みAAB・アイコン・プライバシーポリシーURL・掲載文ドラフト)が揃っている状態。
