# リポジトリ構造定義書

## 撮影用ポスト画面メーカー(X版)

> **ステータス:** ドラフト v0.1
> **最終更新:** 2026-08-01
> **前提:** 本ドキュメントはFlutterプロジェクト作成後の構成を定義する。実装開始時(`.steering/`の初回実装タスク)にこの構成でプロジェクトを作成する

---

## 1. フォルダ・ファイル構成(全体)

```
claude-postapp/
├── CLAUDE.md                      # 開発ルール定義(本ファイル)
├── docs/                          # 永続的ドキュメント
│   ├── product-requirements.md
│   ├── functional-design.md
│   ├── architecture.md
│   ├── repository-structure.md
│   ├── development-guidelines.md
│   ├── glossary.md
│   ├── ideas/                     # アイデア・元資料(PRDドラフト等)
│   └── images/                    # 複雑な図表・モックアップ画像(必要な場合のみ)
├── .steering/                     # 作業単位のステアリングドキュメント
│   └── [YYYYMMDD]-[開発タイトル]/
│       ├── requirements.md
│       ├── design.md
│       └── tasklist.md
├── pubspec.yaml                   # Flutterプロジェクト定義・依存パッケージ
├── analysis_options.yaml          # Lintルール定義
├── android/                       # Android用ネイティブプロジェクト
├── ios/                           # iOS用ネイティブプロジェクト
├── assets/
│   ├── fonts/                     # X風UIに使うフォント(採用する場合)
│   └── icons/                     # アプリアイコン・デフォルトアバター等
├── lib/                           # アプリ本体のDartソースコード(詳細は2節)
└── test/                          # テストコード(詳細は2節)
```

---

## 2. `lib/` 以下の構成(アプリ本体)

`functional-design.md` の「共通インフラ + 種類別エディタ」構成に対応させ、**機能(feature)単位**でディレクトリを分割する。

```
lib/
├── main.dart                      # エントリーポイント。Hive初期化・アプリ起動
├── app.dart                       # MaterialApp/ルーティング定義
│
├── models/                        # データモデル(Hive Object定義)
│   ├── project.dart
│   ├── scene.dart
│   ├── account.dart
│   ├── post.dart
│   └── status_bar_config.dart
│
├── data/                          # 永続化層
│   ├── hive_boxes.dart            # Hive Box名・初期化・アダプタ登録の一元管理
│   ├── project_repository.dart
│   └── scene_repository.dart
│
├── providers/                     # Riverpod Provider/Notifier定義
│   ├── project_providers.dart
│   ├── scene_providers.dart
│   └── editor_providers.dart      # エディタ編集中の一時状態
│
├── features/                      # 画面単位の機能実装
│   ├── project_list/              # プロジェクト一覧画面
│   │   └── project_list_page.dart
│   ├── scene_list/                # 画面(Scene)一覧・種類選択
│   │   ├── scene_list_page.dart
│   │   └── scene_type_picker_sheet.dart
│   ├── editors/                   # 種類別エディタ(フェーズごとに追加)
│   │   ├── timeline/
│   │   │   └── timeline_editor_page.dart
│   │   ├── post_detail/
│   │   │   └── post_detail_editor_page.dart
│   │   ├── profile/                # フェーズ2で追加
│   │   └── dm/                     # フェーズ3で追加
│   ├── account/                   # アカウント設定(共通シート)
│   │   └── account_editor_sheet.dart
│   ├── status_bar/                # ステータスバー設定(共通シート)
│   │   └── status_bar_config_editor_sheet.dart
│   └── fullscreen/                # 撮影用フルスクリーン表示
│       ├── fullscreen_display_page.dart
│       └── image_export_controller.dart
│
├── widgets/                       # 複数機能で共用するUIパーツ
│   ├── fake_status_bar.dart        # iPhone風/Android風ステータスバー描画
│   └── post_card.dart              # 投稿1件分のフィード型表示
│
├── constants/                     # 定数定義(色・サイズ等)
└── utils/                         # 汎用ユーティリティ(数値表記変換等)
```

---

## 3. `test/` 以下の構成

```
test/
├── models/                        # モデルクラスの単体テスト
├── data/                          # リポジトリ層の単体テスト(Hive操作含む)
└── features/                      # 主要画面・エディタのWidgetテスト
```

- テストディレクトリ構成は `lib/` の構成と対応させる(モデル→`models/`、機能→`features/`)
- 詳細なテスト方針(カバレッジ方針・命名規則など)は `development-guidelines.md` で定義する

---

## 4. ディレクトリの役割

| ディレクトリ | 役割 |
|---|---|
| `models/` | Hiveで永続化するデータ構造の定義のみを持つ。ロジックは持たせない |
| `data/` | Hiveへの読み書きを抽象化するリポジトリ層。UI層・状態管理層からは直接Hiveを触らせない |
| `providers/` | Riverpodによる状態管理定義。画面・エディタが参照する状態とビジネスロジックを持つ |
| `features/` | 画面・エディタ単位のUI実装。1画面(または関連する密結合なUI)につき1ディレクトリ |
| `widgets/` | 2つ以上の`features/`から参照される共通UIパーツ。特定機能に閉じたパーツは対応する`features/`配下に置く |
| `constants/` / `utils/` | 特定機能に属さない定数・汎用処理 |
| `docs/` | アプリ全体の恒久的な設計ドキュメント(`CLAUDE.md`参照) |
| `.steering/` | 作業単位の一時的な要求・設計・タスク管理ドキュメント(`CLAUDE.md`参照) |

---

## 5. ファイル配置ルール

- **1画面(Page) = 1ファイル**を基本とし、`features/<機能名>/<機能名>_page.dart` の形式で配置する
- モーダル・ボトムシートなど画面の一部として開くUIは `..._sheet.dart` の接尾辞を付け、それを利用する機能のディレクトリ配下に置く(例:`account_editor_sheet.dart` は複数エディタから使われるため独立ディレクトリ `features/account/` に配置)
- 2つ以上の`features/`から共有されるWidgetのみ `widgets/` に昇格させる。判断に迷う場合は、まず利用元の`features/`配下に置き、2箇所目の利用が発生した時点で`widgets/`へ移動する
- モデルクラスは `models/` に集約し、Hiveの `@HiveType` / `@HiveField` アノテーションを直接付与する(型変換用のマッパー等は作らない)
- フェーズ2・3で追加される画面(プロフィール・DM)は、既存の `features/editors/` 配下に新規ディレクトリを追加する形で拡張し、既存の`profile/`は現時点では空ディレクトリとして予約する
- 新規に依存パッケージを追加する場合は `pubspec.yaml` に追記し、`architecture.md` のテクノロジースタック表も同時に更新する

---

## 6. 今後の検討事項

- フェーズ2(プロフィール)・フェーズ3(DM)実装時の`features/editors/profile/` `features/editors/dm/` 配下の詳細構成
- テストの自動実行(CI)を導入する場合のワークフロー配置(`.github/workflows/` 等)
