# リリース準備 設計

> **作業ディレクトリ:** `.steering/20260809-release-preparation/`
> **作成日:** 2026-08-09

---

## 1. 実装アプローチ

`requirements.md` の6項目(3-1〜3-6)を、依存関係の順に沿って対応する。

```
3-1 アプリ表示名変更 → 3-2 アイコン作成 → 3-3 署名・リリースビルド → 3-6 実機確認
                                        → 3-4 Play Console/ストア掲載情報(並行)
                                        → 3-5 プライバシーポリシー(並行)
```

3-3(署名設定の組み込み)は前段のセッションで既に対応済み。3-4・3-5はコード変更を伴わないため、3-3の残作業(keystore生成・ビルド確認)と並行して進められる。Play Console登録の実行・審査提出はユーザー承認が必要なため、Claudeが担当するのはドラフト作成・技術対応までとする。

---

## 2. 変更するコンポーネント

### 2-1. アプリ表示名の変更

`Fake Post Maker` → 「撮影用ポスト画面メーカー」

**変更対象:**
- `android/app/src/main/AndroidManifest.xml` — `android:label`

**変更しないもの:**
- `pubspec.yaml` の `name: fake_post_maker`(Dartパッケージ名。ストア表示名とは独立の内部名称)
- iOS側(`CFBundleDisplayName`)— 今回iOSはスコープ外のため変更しない(将来iOS対応時に別途決定)
- applicationId/namespace・Bundle Identifier — 変更不要(既に対応済み)

### 2-2. アプリアイコン

- `flutter_launcher_icons` パッケージ(dev_dependencies)を導入し、1枚のマスター画像(1024×1024 PNG)からAndroid全解像度(mipmap-mdpi〜xxxhdpi)+ アダプティブアイコン(前景/背景)を自動生成する
- マスター画像はClaudeが簡易案(1024×1024)を作成し、アーティファクトでユーザーに確認・承認を得てから適用する(LINE版と同方式)
- 生成対象は `android/app/src/main/res/mipmap-*/ic_launcher.png` の置き換え

### 2-3. 署名・リリースビルド設定

- `android/app/build.gradle.kts` への署名設定の組み込みは対応済み(`key.properties`が存在する場合のみreleaseで使い、無ければdebugにフォールバック)
- 残作業(ユーザー本人が対話的に実施、Claudeは手順提示のみ):
  - `keytool -genkeypair` でリリース用keystore(`upload-keystore.jks`)を生成
  - `android/key.properties` を作成(storePassword/keyPassword/keyAlias/storeFile)。`.gitignore`は既に対応済みを確認済み
  - keystoreファイルとパスワードをユーザー自身で安全な場所にバックアップ
- Claude側の確認作業:`flutter analyze` 実行、可能であれば`flutter build appbundle --release`の実行確認(この開発コンテナにAndroid SDKが無いため、実行自体はユーザーのWindows環境で行う想定)

### 2-4. Play Console・ストア掲載情報

コード変更なし。以下のテキスト資産をMarkdownドラフトとして `.steering/20260809-release-preparation/store-listing-draft.md` に作成する。

- アプリ名(日本語)
- 簡単な説明(80文字以内)
- 詳細な説明(4000文字以内)
- スクリーンショット用の撮影シーン案
- コンテンツレーティング質問票の回答方針(暴力・不適切表現なし、対象年齢制限なしを想定)
- データセーフティフォームの回答方針(写真ライブラリへのアクセス:ユーザーが選択した画像のみ使用、外部送信なし、Hiveによるローカル保存のみ)

### 2-5. プライバシーポリシー

- `docs/privacy-policy.md`(日本語)を作成し、GitHub Pages(`claude-postapp`は既にPublicリポジトリのため公開可能)で公開する
- 内容:収集する情報(実質なし。写真ライブラリアクセスはローカル処理のみで外部送信なし)、Hiveによる端末内保存のみである旨、問い合わせ先
- 公開URLの確定・実際のPages有効化はユーザー承認のうえで実施

### 2-6. リリース前チェック

- `flutter analyze` 実行
- `flutter build appbundle --release` でAAB生成確認(ユーザーのWindows環境で実行)
- 実機動作確認:`requirements.md` §5に記載の既知リスク(devcontainer→Windows AVD間の`adb`接続不調)を踏まえ、最初からPlay Console内部テストトラック経由での物理端末確認を優先し、devcontainer側でのadb接続を無理に試行しない

---

## 3. データ構造の変更

なし(Hiveのデータモデル・スキーマに変更は発生しない)。

---

## 4. 影響範囲の分析

| 影響先 | 内容 |
|--------|------|
| `docs/repository-structure.md` | keystore/key.propertiesの配置ルールを追記するか要検討(機密ファイルのため記載は最小限に) |
| `docs/architecture.md` | 署名・ビルド手順は頻繁に変わる情報ではないため、本ステアリングのみに留め`docs/`側は更新不要と判断 |
| GitHubリポジトリ | `key.properties` / `*.jks` は絶対にコミットしない(既に`.gitignore`済みを確認済み) |

---

## 5. 未確定事項(次のtasklist.md作成前に確認したいこと)

1. アプリアイコンのデザイン方向性(Claudeが簡易案を生成してよいか、方向性の希望はあるか)
2. keystore生成のタイミング(ユーザー本人が別途Windows環境で対話的に実行する前提でよいか)
