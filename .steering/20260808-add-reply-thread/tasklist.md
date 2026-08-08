# 実装タスクリスト

## 投稿へのリプライ(返信)表示機能

> **作業ディレクトリ:** `.steering/20260808-add-reply-thread/`
> **最終更新:** 2026-08-08
> **凡例:** `[ ]` 未着手 / `[x]` 完了

---

## タスク1: Provider層へのリプライ操作追加

- [x] `lib/providers/editor_providers.dart` に `repliesOf(Scene scene)` ヘルパーを追加する(`order >= 2` の投稿を`order`昇順で返す)
- [x] `PostDetailEditorNotifier` に `addReply()` を追加する(新規`Account`作成 → `scene.accounts`へ追加 → `order: 2 + repliesOf(state).length` で`Post`作成 → `commit()`)
- [x] `PostDetailEditorNotifier` に `removeReply(Post reply)` を追加する(該当`Post`と紐づく`Account`を削除 → 残りリプライの`order`を2始まりで振り直す → `commit()`)
- [x] `PostDetailEditorNotifier` に `reorderReply(int oldIndex, int newIndex)` を追加する(`repliesOf(state)`のみを対象に並び替え、`order`を2始まりで振り直す → `commit()`)
- [x] `flutter analyze` でエラーがないことを確認する

**完了条件:** リプライの追加・削除・並び替えがProvider層のAPIとして呼び出せ、`order`が0(メイン)・1(引用ポスト)と衝突しない

---

## タスク2: `TimelinePostEditorSheet`の汎用化・移動

- [x] `lib/features/editors/timeline/timeline_post_editor_sheet.dart` の内容を `lib/widgets/post_editor_sheet.dart` へ移動し、クラス名を `PostEditorSheet` に変更する
- [x] コンストラクタ引数を `TimelineEditorNotifier notifier` から `Future<void> Function() onCommit` に変更する(内部の`notifier.commit`呼び出しを`onCommit()`に置き換え)
- [x] 旧ファイル `lib/features/editors/timeline/timeline_post_editor_sheet.dart` を削除する
- [x] `lib/features/editors/timeline/timeline_editor_page.dart` の呼び出し箇所を `PostEditorSheet(post:, account:, onCommit: notifier.commit)` に変更し、importを更新する
- [x] `flutter analyze` でエラーがないことを確認する

**完了条件:** タイムラインエディタの投稿編集シートが従来通り動作する(挙動に変化がないことを目視/既存テストで確認)

---

## タスク3: 投稿詳細エディタへのリプライ一覧UI追加

- [x] `lib/features/editors/post_detail/post_detail_editor_page.dart` のプレビュー領域に、メイン投稿(+引用ポスト)の下へリプライの`PostCard`(`variant: timeline`)一覧を追加する
- [x] フォーム領域(`_QuotedPostSection`の下)に`_RepliesSection`を追加する
  - [x] 「リプライを追加」ボタン(`notifier.addReply()`を呼ぶ)
  - [x] リプライ一覧を`ReorderableListView.builder`(`shrinkWrap: true`, `physics: NeverScrollableScrollPhysics`, `buildDefaultDragHandles: false`)で表示し、`TimelineEditorPage`と同様にドラッグハンドル・タップで`PostEditorSheet`を開く・削除ボタンを配置する
- [x] `flutter analyze` でエラーがないことを確認する

**完了条件:** 投稿詳細エディタからリプライの追加・編集(本文/画像/数値/日時/アカウント)・並び替え・削除が行え、プレビューに即時反映される

---

## タスク4: フルスクリーン表示への反映

- [x] `lib/features/fullscreen/fullscreen_display_page.dart` の `_PostDetailContent` に、メイン投稿(+引用ポスト)の下へリプライの`PostCard`一覧表示を追加する
- [x] `flutter analyze` でエラーがないことを確認する

**完了条件:** フルスクリーン表示モードで、投稿詳細エディタのプレビューと同じ内容(リプライ含む)が表示される

---

## タスク5: テスト追加・既存テストの確認

- [x] `test/providers/editor_providers_test.dart` に `repliesOf`/`addReply`/`removeReply`/`reorderReply` のテストケースを追加する(orderの採番・振り直し、引用ポストとの共存を含む)
- [x] `test/features/editors/timeline/timeline_editor_page_test.dart` を実行し、`PostEditorSheet`への変更によるリグレッションがないことを確認する(必要ならシート名の参照箇所を更新)
- [x] `test/features/editors/post_detail/post_detail_editor_page_test.dart` にリプライの追加・編集・並び替え・削除のテストケースを追加する
- [x] `test/features/fullscreen/fullscreen_display_page_test.dart` にリプライを含むSceneの表示テストケースを追加する
- [x] `flutter test` を全件実行し、既存テストを含めてすべてパスすることを確認する

**完了条件:** `flutter test` が全件成功する(既存機能のデグレードがないことを含む)

---

## タスク6: 実機/シミュレータでの動作確認

- [x] 投稿詳細エディタでリプライを追加し、プレビューに反映されることを確認する
- [x] リプライの本文・画像・数値・日時・アカウントを編集し、正しく保存されることを確認する
- [x] 複数リプライを並び替え、順序が保持されることを確認する
- [x] リプライを削除し、一覧・プレビューから正しく消えることを確認する
- [x] 引用ポストとリプライを同時に設定し、表示が崩れないことを確認する
- [x] フルスクリーン表示モードでリプライが正しく表示されることを確認する
- [x] 画像書き出し(PNG)を実行し、書き出し画像にリプライが正しく含まれることを確認する
- [x] リプライなしの既存プロジェクトを開き、エラーなく表示できることを確認する(後方互換性)
- [x] タイムラインエディタの投稿編集(`PostEditorSheet`経由)が従来通り動作することを確認する

**完了条件:** `requirements.md` 3節の受け入れ条件をすべて実機/シミュレータで満たしていることを確認する

---

## タスク7: 永続的ドキュメント(`docs/`)の更新

- [x] `docs/product-requirements.md` 3節・7節・8.4節に「投稿詳細画面でのリプライ表示」を追記する
- [x] `docs/functional-design.md` 3.3節(補足)に、投稿詳細Scene内の`Post.order`の役割拡張(0=メイン/1=引用ポスト/2以上=リプライ)を追記する
- [x] `docs/functional-design.md` 7.1節(投稿詳細ワイヤフレーム)にリプライ表示の一例を追記する(任意)

**完了条件:** `docs/`の記載が実装内容と一致している

---

## 全体の完了条件

- `requirements.md` 3節の受け入れ条件をすべて満たす
- `flutter analyze` / `flutter test` がエラー・失敗なく通る
- 既存機能(タイムライン画面・引用ポストなしの投稿詳細)にデグレードがない
- `docs/product-requirements.md`・`docs/functional-design.md`が更新済み
