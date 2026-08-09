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

- [ ] `android/app/src/main/AndroidManifest.xml` の `android:label` を「撮影用ポスト画面メーカー」に変更
- [ ] `flutter analyze` でビルド確認

## Task 2: アプリアイコン作成・適用

- [ ] Claudeが簡易案(1024×1024マスター画像)を作成し、アーティファクトでユーザーに確認・承認
- [ ] `flutter_launcher_icons` を導入し、`assets/icon/app_icon.png` に正方形フルブリード版を配置
- [ ] Android全解像度(mipmap-*)に適用し、`flutter analyze`で確認

## Task 3: リリース署名用keystore生成(ユーザー本人作業)

- [ ] `keytool -genkeypair` コマンドをユーザー自身のWindows環境で実行し、`upload-keystore.jks` を生成(手順はセッション内で提示済み)
- [ ] `android/key.properties` を作成(storePassword/keyPassword/keyAlias/storeFile)。`.gitignore`で除外済みであることは確認済み
- [ ] keystoreファイルとパスワードを安全な場所にバックアップ

## Task 4: リリースビルド確認

- [ ] `flutter analyze` クリーン確認
- [ ] ユーザーのWindows環境で `flutter build appbundle --release` を実行し、署名済みAABが生成されることを確認

## Task 5: プライバシーポリシー作成・公開

- [ ] `docs/privacy-policy.md` を作成(収集情報なし・写真ライブラリはローカル処理のみ・Hiveによる端末内保存の旨を明記)
- [ ] GitHub Pagesを有効化(ユーザー承認のうえ)し、公開URLを確定

## Task 6: ストア掲載情報ドラフト作成

- [ ] `store-listing-draft.md` を作成(アプリ名・簡単な説明・詳細な説明・コンテンツレーティング方針・データセーフティ回答方針・スクリーンショット撮影案)

## Task 7: 実機動作確認

- [ ] `requirements.md` §5の既知リスクを踏まえ、まずPlay Console内部テストトラックへAABをアップロードし、物理Android端末への配布リンク経由での確認を試みる(devcontainer→Windows AVD間のadb接続は前例で未解決のため、無理な再試行はしない)
- [ ] フェーズ1機能一式(投稿詳細・タイムライン・画像添付・リプライ・フルスクリーン表示・画像書き出し)が問題なく動作することを確認

## Task 8: 最終チェック・引き継ぎ

- [ ] `requirements.md` §4の受け入れ条件を全項目確認
- [ ] Play Console登録・審査提出をユーザー本人の作業として引き継ぐ`handoff.md`を作成

---

## 完了条件

`requirements.md` の受け入れ条件をすべて満たし、Play Consoleへの提出に必要な技術的準備(署名済みAAB・アイコン・プライバシーポリシーURL・掲載文ドラフト)が揃っている状態。
