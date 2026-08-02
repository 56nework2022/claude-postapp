# 開発ガイドライン

## 撮影用ポスト画面メーカー(X版)

> **ステータス:** ドラフト v0.1
> **最終更新:** 2026-08-01

---

## 1. コーディング規約

- Dart標準の [Effective Dart](https://dart.dev/effective-dart) に準拠する
- フォーマットは `dart format` を必ず適用する(手動整形しない)
- 静的解析は `flutter_lints` を `analysis_options.yaml` に導入し、警告ゼロを維持する
- **Widgetの分割方針:**
  - 状態を持たないUIは `StatelessWidget`、Riverpodの状態を参照するUIは `ConsumerWidget` / `ConsumerStatefulWidget` を用いる
  - `StatefulWidget` は、Riverpodで管理すべきでないUIローカルな一時状態(アニメーション制御など)に限定して使用する
  - 1つのbuildメソッドが長大にならないよう、意味のある単位でprivateなWidgetクラス・メソッドに分割する(`_XxxSection` など)
- **状態管理(Riverpod):**
  - 画面をまたいで共有する状態(Project一覧、編集中のScene等)は `Notifier` / `AsyncNotifier` で管理する
  - UIから直接Hiveを操作せず、必ず `data/` 層のRepositoryを経由する(`repository-structure.md` 4節参照)
- **モデルクラス(Hive):**
  - `models/` のクラスにはロジックを持たせず、データ構造とHiveアノテーションのみを定義する
  - 表示用の変換処理(例:数値ラベルの整形)はモデルではなく `utils/` または表示側Widgetに置く
- **不要な抽象化を避ける:** 現時点でフェーズ1にしか存在しない処理を、将来のフェーズ2・3を見越して過度に抽象化しない。必要になった時点で拡張する

---

## 2. 命名規則

| 対象 | 規則 | 例 |
|---|---|---|
| ファイル名 | snake_case | `post_detail_editor_page.dart` |
| クラス名(Widget/モデル等) | UpperCamelCase | `PostDetailEditorPage`, `Account` |
| 変数・メソッド名 | lowerCamelCase | `likeCountLabel`, `exportImage()` |
| 定数 | lowerCamelCase(`Effective Dart`準拠。`SCREAMING_CASE`は使わない) | `defaultIconSize` |
| Enum | UpperCamelCase(型名)/ lowerCamelCase(値) | `enum SceneType { timeline, postDetail }` |
| Riverpod Provider | 対象名 + `Provider` | `projectListProvider`, `sceneNotifierProvider` |
| Riverpod Notifier | 対象名 + `Notifier` | `ProjectListNotifier` |
| Repository | 対象名 + `Repository` | `ProjectRepository` |
| ボトムシート/ダイアログ | 対象名 + `Sheet` / `Dialog` | `AccountEditorSheet` |
| Hive Box名 | 複数形のスネークケース文字列 | `'projects'`, `'scenes'` |
| ドメイン用語(日本語⇔英語) | `docs/glossary.md` の対応表に従う | — |

---

## 3. スタイリング規約

> **補足:** `CLAUDE.md` はTailwind CSSでの統一を標準ルールとして挙げているが、Tailwind CSSはWeb(CSS)向けのフレームワークであり、本プロジェクトはFlutter(Dart)によるモバイルアプリであるため技術的に採用できない。同じ目的(共通のデザインシステムによる統一感の担保)を、Flutter標準の `ThemeData` とデザイントークン定数で実現する。

- アプリ全体の配色・タイポグラフィは `ThemeData` に集約し、Widget側で色や文字サイズを直接ハードコードしない
- 色・余白・角丸などのデザイントークンは `lib/constants/` (例:`app_colors.dart`, `app_spacing.dart`, `app_text_styles.dart`)に定義し、Widgetからはそれらを参照する
- **X風UIの再現性:** フォント・アイコン・レイアウト比率は実物のXアプリに近づけるが、公式ロゴ・商標そのものは使用しない(`architecture.md` 3.3節の制約に従う)
- **iPhone風/Android風の出し分け:** ステータスバーなどOS依存の見た目は `FakeStatusBar` 内で分岐させ、他のWidgetにOS分岐ロジックを漏らさない
- ダークモード対応は現時点では必須要件としない(フェーズ1リリース後、必要性を見て検討する)

---

## 4. テスト規約

- **単体テスト(`test/models/`, `test/data/`):**
  - モデルクラスのHiveシリアライズ/デシリアライズ
  - Repository層のCRUD操作(Hiveボックスに対する読み書き)
- **Widgetテスト(`test/features/`):**
  - 各エディタ画面の主要な入力・保存フローが動作すること
  - `FakeStatusBar` / `PostCard` など共通Widgetの表示崩れがないこと
- **手動確認:** フルスクリーン表示・画像書き出し・実機のシステムUI非表示挙動は自動テストで担保しづらいため、各実装ステップで実機またはシミュレータでの目視確認を必須とする(`architecture.md` 2節の実装順序に対応)
- テストファイルは対象ファイルと同名+`_test.dart`とする(例:`project_repository.dart` → `project_repository_test.dart`)
- ひとり開発のため、カバレッジ数値の目標は設けない。ただし「データが消える」「フルスクリーン表示が崩れる」など撮影本番に直結する不具合につながる箇所は優先的にテストを書く

---

## 5. Git規約

- **ブランチ運用:** `main` を安定ブランチとし、`.steering/[YYYYMMDD]-[開発タイトル]/` のタイトルに対応する作業ブランチ(例:`feature/20250115-add-tag-feature`)を作成して作業する
- **コミット単位:** タスクリスト(`tasklist.md`)の1タスク相当を目安に、意味のある単位でコミットする
- **コミットメッセージ:** 「何を」ではなく「なぜ」を意識した日本語の簡潔なメッセージとする(例:`投稿詳細のいいね数を自由文字列にし、"1.2万"等の省略表記に対応`)
- **破壊的操作の禁止:** `git push --force`・`git reset --hard` 等は明示的な指示がない限り使用しない
- **秘密情報:** APIキー等の秘密情報は本アプリの性質上発生しない想定だが、万一導入する場合は `.gitignore` で除外し、コミットしない

---

## 6. 今後の検討事項

- ダークモード対応の要否
- CI導入時のLint/テスト自動実行フローの整備
