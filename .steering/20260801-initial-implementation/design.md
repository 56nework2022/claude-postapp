# 実装設計

## 撮影用ポスト画面メーカー(X版) — フェーズ1(MVP)

> **作業ディレクトリ:** `.steering/20260801-initial-implementation/`
> **最終更新:** 2026-08-01
> **前提:** `docs/functional-design.md`・`docs/architecture.md`・`docs/repository-structure.md` に定義した設計をそのまま踏襲し、本ドキュメントでは初回実装における具体的な決定事項を記載する

---

## 1. 実装アプローチ

### 1.1 全体方針

`docs/functional-design.md` 2節の「共通インフラ + 種類別エディタ」構成をそのまま実装する。新規プロジェクトのため、既存コードとの整合を考慮する必要はなく、`docs/repository-structure.md` のディレクトリ構成を初期状態から適用する。

### 1.2 主要な技術的決定事項

| 項目 | 決定内容 | 理由 |
|---|---|---|
| ナビゲーション | 標準の `Navigator` + `MaterialPageRoute` を使用し、`go_router` 等は導入しない | 画面数が少なく(フェーズ1は4〜5画面程度)、ルーティングパッケージ導入のコストに見合わないため |
| Riverpod記法 | コード生成(`@riverpod`アノテーション)は使わず、`NotifierProvider` / `Provider` を手書きする | `build_runner` の実行待ちを発生させず、ひとり開発でのイテレーション速度を優先するため。将来的にコード生成へ移行してもよい |
| Hiveの型登録 | モデルクラスに `@HiveType(typeId: N)` を直接付与し、`hive_generator` + `build_runner` でアダプタを自動生成する | アダプタの手書きはミスが起きやすいため、コード生成のみHiveに限り採用する |
| フルスクリーン制御 | `SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky)` をフルスクリーン表示画面の `initState` で呼び出し、画面離脱時に `SystemUiMode.edgeToEdge` へ復帰する | `docs/architecture.md` 3.4節の撮影運用要件を満たすため |
| 画像書き出し | 表示中のScene描画Widgetを `RepaintBoundary` でラップし、`screenshot` パッケージでキャプチャしてPNG化、カメラロール保存パッケージで保存する | エディタのプレビューとフルスクリーン表示で同一Widgetツリーをキャプチャできるようにするため |
| 数値ラベル | `likeCountLabel` 等はモデル上は`String`型とし、バリデーションは行わない(自由入力を優先) | `docs/functional-design.md` 3.3節の方針に従う |

### 1.3 実装順序

`docs/architecture.md` 2節の方針に従い、以下の順で実装する(詳細は `tasklist.md` を参照)。

1. Flutterプロジェクト作成・依存パッケージ導入
2. データモデル + Hive永続化層
3. プロジェクト一覧画面
4. 画面(Scene)一覧・種類選択
5. アカウント設定・ステータスバー設定(共通シート)
6. 投稿詳細エディタ
7. タイムラインエディタ
8. 撮影用フルスクリーン表示モード
9. 画像書き出し

各ステップ完了時に実機またはシミュレータで動作確認を行う。

---

## 2. 作成するコンポーネント

新規プロジェクトのため「変更」ではなく「新規作成」となる。`docs/repository-structure.md` 2節の構成に従い、以下を作成する。

- `models/`: `project.dart`, `scene.dart`, `account.dart`, `post.dart`, `status_bar_config.dart`
- `data/`: `hive_boxes.dart`, `project_repository.dart`, `scene_repository.dart`
- `providers/`: `project_providers.dart`, `scene_providers.dart`, `editor_providers.dart`
- `features/project_list/`: `project_list_page.dart`
- `features/scene_list/`: `scene_list_page.dart`, `scene_type_picker_sheet.dart`
- `features/editors/timeline/`: `timeline_editor_page.dart`
- `features/editors/post_detail/`: `post_detail_editor_page.dart`
- `features/account/`: `account_editor_sheet.dart`
- `features/status_bar/`: `status_bar_config_editor_sheet.dart`
- `features/fullscreen/`: `fullscreen_display_page.dart`, `image_export_controller.dart`
- `widgets/`: `fake_status_bar.dart`, `post_card.dart`
- `constants/`: `app_colors.dart`, `app_spacing.dart`, `app_text_styles.dart`
- `main.dart`, `app.dart`

---

## 3. データ構造の変更(新規定義)

`docs/functional-design.md` 3節のER図を、Hiveの型として具体化する。

| モデル | HiveTypeId(仮) | フィールド |
|---|---|---|
| `Project` | 0 | `id: String`, `name: String`, `createdAt: DateTime`, `updatedAt: DateTime`, `scenes: List<Scene>`(Box分割をしない方針のため埋め込み) |
| `Scene` | 1 | `id: String`, `projectId: String`, `type: SceneType`, `title: String`, `order: int`, `statusBarConfig: StatusBarConfig`, `accounts: List<Account>`, `posts: List<Post>`, `createdAt: DateTime`, `updatedAt: DateTime` |
| `SceneType`(enum) | 2 | `timeline`, `postDetail`, `profile`, `dm`(フェーズ1では`timeline`/`postDetail`のみUIから選択可) |
| `Account` | 3 | `id: String`, `displayName: String`, `username: String`, `iconImagePath: String?`, `isVerified: bool` |
| `Post` | 4 | `id: String`, `accountId: String`, `body: String`, `likeCountLabel: String`, `repostCountLabel: String`, `replyCountLabel: String`, `postedAt: DateTime`, `quotedPostId: String?`, `order: int` |
| `StatusBarConfig` | 5 | `platform: StatusBarPlatform`, `timeMode: TimeMode`, `manualTime: String?`, `signalLevel: int`, `batteryLevel: int`, `isCharging: bool` |
| `StatusBarPlatform`(enum) | 6 | `ios`, `android` |
| `TimeMode`(enum) | 7 | `manual`, `current` |

- `Scene` は `Account` / `Post` / `StatusBarConfig` を**埋め込み(Hiveの `HiveObject` を持つList/オブジェクトとして直接ネスト)**で保持し、別Boxに分離しない(フェーズ1のデータ量ではオーバーヘッドが小さいため)
- Hiveの `Box` は `projects`(`Project`を保存)の1つのみとし、`Scene`以下は`Project`オブジェクトの内部データとしてシリアライズする。プロジェクト単位でしか読み書きしないため、Box分割によるメリットが薄いと判断した

---

## 4. 影響範囲の分析

新規プロジェクトの立ち上げであるため、既存コードへの影響は存在しない。ただし本作業は以降すべての機能追加の土台となるため、以下の点が後続作業に影響する。

- **データモデルのHiveTypeId割り当て:** 本作業で確定した番号は、フェーズ2・3で新しいモデル(プロフィール用フィールド、DM用メッセージモデル等)を追加する際に**既存の番号と重複しないよう**新しい番号を割り当てる必要がある
- **`Scene`埋め込み構造の前提:** フェーズ2・3で`Scene`に持たせるデータ量が大きくなった場合(例:プロフィールの投稿一覧、DMの大量メッセージ)、埋め込み構造のままで良いか再検討が必要になる可能性がある
- **共通Widget(`FakeStatusBar`, `PostCard`)の設計:** フェーズ2(プロフィール)もフィード型のため`PostCard`を再利用できる見込みだが、フェーズ3(DM/チャット型)は別のWidget設計が必要になる(`docs/functional-design.md` 9節の今後の検討事項と対応)

---

## 5. 今後の検討事項

- Riverpodのコード生成移行の要否(画面数・状態が増えた段階で再検討)
- `Scene`のデータ量がフェーズ2・3で増大した場合のBox分割設計の見直し
