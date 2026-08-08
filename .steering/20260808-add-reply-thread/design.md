# 実装設計

## 投稿へのリプライ(返信)表示機能

> **作業ディレクトリ:** `.steering/20260808-add-reply-thread/`
> **最終更新:** 2026-08-08
> **前提:** `requirements.md` のスコープ(投稿詳細画面限定・1階層のみ・複数リプライの追加/編集/並び替え/削除)に基づく。既存の「共通インフラ + 種類別エディタ」構成(`docs/functional-design.md` 2節)・共通Widget再利用方針(`PostCard`/`PostFieldsForm`の共用)はそのまま踏襲する

---

## 1. 実装アプローチ

### 1.1 全体方針

**`Post`・`Scene`のHiveスキーマは一切変更しない。** 投稿詳細エディタ(`PostDetailEditorNotifier`)がすでに使っている「`Post.order`の値でメイン投稿(`order:0`)・引用ポスト(`order:1`)を区別する」という既存の規約(`lib/providers/editor_providers.dart`の`mainPostOf`/`quotedPostOf`)を、そのままリプライにも拡張する。

- `order: 0` → メイン投稿(常に1件)
- `order: 1` → 引用ポスト(0〜1件、任意)
- `order: 2以上` → リプライ投稿(0件以上、`order`の値がそのまま表示順を兼ねる)

この方式により、新規`HiveField`の追加(=`build_runner`再生成・後方互換性の検証)が不要になり、`.steering/20260806-add-post-image/`で発生したような`post.g.dart`再生成コストやHiveマイグレーションリスクを避けられる。`requirements.md`受け入れ条件の「既存プロジェクトを開いてもエラーなく読み込める」も、スキーマ変更がないため自動的に満たされる。

リプライは`TimelineEditorNotifier`の投稿リストと同様「複数件・追加/削除/並び替え可能」という性質を持つため、UI操作(ドラッグ並び替え・削除ボタン)は`TimelineEditorPage`の一覧UIパターンを踏襲する。

### 1.2 主要な技術的決定事項

| 項目 | 決定内容 | 理由 |
|---|---|---|
| リプライの識別方法 | 新規フィールドを追加せず、`Post.order >= 2`をリプライとみなす(`repliesOf(scene)`ヘルパーを追加) | Hiveスキーマ変更を避け、後方互換性の検証コストをゼロにする。`mainPostOf`/`quotedPostOf`と同じ「orderで役割を表す」規約に自然に乗る |
| リプライごとのアカウント | 引用ポストと同様、リプライ追加時に新規`Account`を1件作成し`scene.accounts`に追加する。1リプライ=1アカウント | 既存の`addQuotedPost()`と同じパターン。複数リプライで同一アカウントを使い回すケースは今回のスコープ外(`requirements.md`に記載なし、必要になれば別途対応) |
| 追加時のorder採番 | `order = 2 + repliesOf(scene).length`(末尾に追加) | `TimelineEditorNotifier.addPost`と同じ「末尾追加」方式に揃える |
| 並び替え | リプライのみを対象にした`reorderReply(oldIndex, newIndex)`を`PostDetailEditorNotifier`に追加し、対象リプライの`order`を2始まりで振り直す | `TimelineEditorNotifier.reorderPost`とほぼ同じロジックだが、対象を`repliesOf(scene)`のみに絞り、`order`のベースを0ではなく2にする点のみ異なる |
| 削除 | `removeReply(Post reply)`で該当`Post`と紐づく`Account`を削除し、残りリプライの`order`を2始まりで振り直す | `TimelineEditorNotifier.deletePost`と同じ「Post+Account削除→order再採番」パターン |
| 編集シートの共通化 | `TimelinePostEditorSheet`(`features/editors/timeline/timeline_post_editor_sheet.dart`)を`lib/widgets/post_editor_sheet.dart`の`PostEditorSheet`へ移動・汎用化する。コンストラクタ引数を`TimelineEditorNotifier notifier`から`Future<void> Function() onCommit`に変更し、タイムライン・投稿詳細どちらからも使えるようにする | 現状の`TimelinePostEditorSheet`は`notifier.commit`しか使っておらず、実質「Post編集フォーム+アカウント設定+閉じるボタン」の汎用シートである。リプライ編集にもほぼ同じUIが必要なため、型を限定した実装をそのまま複製すると重複実装になる(`docs/functional-design.md` 4.3節の「重複実装を避ける」方針に反する)。コールバック型に変えるだけで両方から使え、`PostCard`/`PostFieldsForm`と同じ「エディタ間で共通Widgetを再利用する」設計方針に揃う |
| プレビュー表示(編集画面) | `PostDetailEditorPage`のプレビュー領域で、メイン投稿の`PostCard`(+引用ポスト)の下に、リプライを`PostCardVariant.timeline`の`PostCard`として縦に並べる。`PostCard`自体の変更は不要(呼び出し側で複数並べるだけ) | `PostCard`は既存のまま再利用でき、`post_card_test.dart`など既存テストへの影響がない |
| プレビュー表示(フルスクリーン) | `fullscreen_display_page.dart`の`_PostDetailContent`も同様に、メイン投稿(+引用ポスト)の下へリプライの`PostCard`一覧を追加する | エディタのプレビューと表示ロジックを揃え、見た目の乖離を防ぐ(`docs/functional-design.md` 4.3節方針) |
| リプライ一覧の並び替えUI | `PostDetailEditorPage`のフォーム領域に`ReorderableListView.builder(shrinkWrap: true, physics: NeverScrollableScrollPhysics, buildDefaultDragHandles: false, ...)`を追加し、`TimelineEditorPage`と同じドラッグハンドル+タップ編集+削除ボタンの行UIを使う | 外側の`ListView`(投稿詳細フォーム全体)の中に入れ子で配置するため`shrinkWrap`+`NeverScrollableScrollPhysics`が必要。UI/操作感を`TimelineEditorPage`の一覧と統一する |

### 1.3 実装順序

1. `lib/providers/editor_providers.dart`に`repliesOf(scene)`ヘルパーを追加し、`PostDetailEditorNotifier`に`addReply()`/`removeReply(Post)`/`reorderReply(int, int)`を追加する
2. `TimelinePostEditorSheet`を`lib/widgets/post_editor_sheet.dart`の`PostEditorSheet`へ移動し、コンストラクタ引数を`onCommit`コールバックに変更する。`TimelineEditorPage`側の呼び出しを新しいAPIに合わせて更新する
3. `PostDetailEditorPage`にリプライ一覧セクション(`_RepliesSection`)を追加し、プレビュー領域にもリプライの`PostCard`一覧を追加する
4. `fullscreen_display_page.dart`の`_PostDetailContent`にリプライの`PostCard`一覧表示を追加する
5. 既存テスト(`timeline_editor_page_test.dart`, `post_detail_editor_page_test.dart`, `fullscreen_display_page_test.dart`, `editor_providers_test.dart`)を実行し、リグレッションがないことを確認する(特に`TimelinePostEditorSheet`のリネーム・シグネチャ変更の影響)
6. リプライの追加・編集・並び替え・削除・フルスクリーン表示・画像書き出しを対象にテストを追加する
7. 実機/シミュレータで一連の操作を目視確認する

各ステップ完了時に`flutter analyze`を実行する。

---

## 2. 変更するコンポーネント

| コンポーネント | 変更種別 | 内容 |
|---|---|---|
| `lib/providers/editor_providers.dart` | 変更 | `repliesOf(Scene)`ヘルパー追加。`PostDetailEditorNotifier`に`addReply()`/`removeReply(Post)`/`reorderReply(int,int)`を追加 |
| `lib/features/editors/timeline/timeline_post_editor_sheet.dart` | 削除(移動) | `lib/widgets/post_editor_sheet.dart`へ移動・汎用化 |
| `lib/widgets/post_editor_sheet.dart` | 新規 | 汎用化した`PostEditorSheet`(旧`TimelinePostEditorSheet`)。`onCommit: Future<void> Function()`を受け取る |
| `lib/features/editors/timeline/timeline_editor_page.dart` | 変更 | `TimelinePostEditorSheet`呼び出しを`PostEditorSheet(post:, account:, onCommit: notifier.commit)`に変更(import先も変更) |
| `lib/features/editors/post_detail/post_detail_editor_page.dart` | 変更 | プレビュー領域にリプライの`PostCard`一覧を追加。フォーム領域に`_RepliesSection`(追加ボタン・並び替え可能な一覧・`PostEditorSheet`呼び出し)を追加 |
| `lib/features/fullscreen/fullscreen_display_page.dart` | 変更 | `_PostDetailContent`にリプライの`PostCard`一覧表示を追加 |
| `test/features/editors/timeline/timeline_editor_page_test.dart` | 確認・修正 | シート名・呼び出し変更に追従(挙動自体は変わらない想定) |
| `test/features/editors/post_detail/post_detail_editor_page_test.dart` | 変更 | リプライ追加・編集・並び替え・削除のテストケースを追加 |
| `test/features/fullscreen/fullscreen_display_page_test.dart` | 変更 | リプライを含むSceneの表示テストケースを追加 |
| `test/providers/editor_providers_test.dart` | 変更 | `repliesOf`/`addReply`/`removeReply`/`reorderReply`のテストケースを追加 |

**変更不要なコンポーネント(理由)**

- `lib/models/post.dart` / `post.g.dart` / `lib/models/scene.dart` / `scene.g.dart` — Hiveスキーマ変更なし(1.1節の方針)
- `lib/widgets/post_card.dart` — 呼び出し側で複数並べるだけで対応でき、Widget自体の変更は不要
- `lib/widgets/post_fields_form.dart` — 本文・画像・数値・日時の編集内容はメイン投稿・引用ポスト・リプライで共通のため変更不要
- `lib/features/account/account_editor_sheet.dart` — `PostEditorSheet`からそのまま呼び出す既存の仕組みを再利用
- `lib/features/fullscreen/image_export_controller.dart` — `PostCard`をキャプチャする既存の仕組みのみで、追加実装不要

---

## 3. データ構造の変更

**変更なし。** `Post`・`Scene`のHiveスキーマ(フィールド定義)はそのまま。

`docs/functional-design.md` 3.3節「補足」に、既存の`order`の役割の説明を以下の通り拡張して追記する(ER図自体は変更なし):

> 投稿詳細Scene内の`Post.order`は、タイムラインのような単純な並び順ではなく「役割」も表す: `0`=メイン投稿、`1`=引用ポスト(任意)、`2`以上=リプライ投稿(複数可、値がそのまま表示順)

---

## 4. 影響範囲の分析

### 4.1 永続的ドキュメント(`docs/`)への影響

- `docs/product-requirements.md` 3節(フェーズ1機能一覧)・7節(受け入れ条件)・8.4節(主要機能フェーズ1)に「投稿詳細画面でのリプライ表示」を追記する
- `docs/functional-design.md` 3.3節(補足)に`order`の役割拡張を追記する。5節(ユースケース図)・6節(画面遷移図)は変更不要(新しい画面遷移は発生しない)。7.1節(投稿詳細ワイヤフレーム)にリプライ表示の一例を追記する(任意)

これらは実装完了後、`tasklist.md`の最終タスクとしてまとめて更新する。

### 4.2 既存機能への影響

- **タイムライン画面:** `Post.order`の意味は`TimelineEditorNotifier`が管理するScene(`type: timeline`)では従来通り「純粋な並び順」のまま変わらない。投稿詳細Scene(`type: postDetail`)限定の規約拡張であり、影響しない
- **`TimelinePostEditorSheet`のリネーム・汎用化:** 呼び出し元は`TimelineEditorPage`の1箇所のみ(`grep`で確認済み)。コンストラクタ引数を`notifier`から`onCommit`コールバックに変えても、渡す値は実質同じ(`notifier.commit`)であり、タイムライン側の挙動に変化はない
- **引用ポストとの共存:** リプライの`order`採番(`2 + repliesOf(scene).length`)は引用ポストの有無に関係なく常に`2`から開始するため、引用ポストの追加/削除タイミングとリプライの`order`が衝突することはない
- **既存プロジェクトの後方互換性:** Hiveスキーマ変更がないため、リプライなしの既存投稿詳細Scene(`order`が0・1のみ)はそのまま従来通り表示される

### 4.3 今後の拡張への影響

- リプライへのさらなるリプライ(2階層以上)に対応する場合、`order`だけでは階層を表現できないため、`Post`に`replyToPostId: String?`のような明示的な親子関係フィールドを追加するモデル変更が必要になる(本作業のスコープ外)
- タイムライン画面上でのリプライ表示に対応する場合、`TimelineEditorNotifier`側の`order`が純粋な並び順として使われている前提と衝突するため、別途データモデルの設計が必要(本作業のスコープ外)

---

## 5. 今後の検討事項

- リプライの複数階層化(スレッド分岐)の要否
- リプライ間でアカウントを使い回す(同一人物が複数回リプライする)ニーズの要否
- リプライ一覧が多くなった場合の折りたたみ表示(「他の返信を表示」的なUI)の要否
