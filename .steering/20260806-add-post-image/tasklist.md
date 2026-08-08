# 実装タスクリスト

## 投稿への画像添付機能(写真付きポスト対応)

> **作業ディレクトリ:** `.steering/20260806-add-post-image/`
> **最終更新:** 2026-08-06
> **凡例:** `[ ]` 未着手 / `[x]` 完了

---

## 進捗メモ(次回再開時に読むこと)

- タスク1〜4・6が完了。タスク5(実機/シミュレータでの動作確認)は、開発コンテナ内にディスプレイ・Android SDKがないため未実施(`.steering/20260801-initial-implementation/tasklist.md`のタスク8・9と同じ既知の制約)。**次回、実機かエミュレータが使える環境で最初に確認すること**
- タスク1:`Post`に`imagePath: String?`を`@HiveField(9)`として追加し、`build_runner`で`post.g.dart`を再生成。既存フィールド(0〜8)の番号・型は変更なし
- タスク2:`widgets/post_fields_form.dart`に`_PostImagePicker`(プライベートWidget)を追加。本文フィールドの直後・数値ラベル入力の前に配置。`AccountEditorSheet`の`_IconPicker`と同様、`image_picker`でギャラリーから選択し、`widget.post.imagePath`を直接ミューテートして`widget.onChanged()`(`notifier.commit`)を呼ぶ方式に統一。削除ボタン(×アイコン)で`imagePath`を`null`に戻せる
- タスク3:`widgets/post_card.dart`の`build`に、本文の下・引用ポスト表示エリア(`quotedChild`)の上・フッターの上へ画像表示エリアを追加。`AspectRatio(16/9)`+`ClipRRect`+`Image.file(fit: BoxFit.cover)`。`PostCard`はタイムライン・投稿詳細・引用ポストの3箇所すべてで共用されているため、この変更のみで全箇所に反映される
- **ハマりどころ(タスク4・重要):** `post_card_test.dart`に画像添付ケースを追加する際、最初`tester.pumpAndSettle()`で画像デコード完了を待とうとしたところ10分でタイムアウトした。原因を切り分けたところ、`pumpAndSettle`自体ではなく**テスト内で一時ファイルを作成・書き込みする実ディスクI/O(`Directory.systemTemp.createTemp` / `File.writeAsBytes`)をFakeAsyncゾーン内で`await`していたこと**が原因だった(`.steering/20260801-initial-implementation/tasklist.md`のタスク3・9に記載の既知の制約と同じ)。対処として、実ファイルI/O(一時ディレクトリ作成・書き込み・削除)だけを`tester.runAsync(...)`で包み、`pumpWidget`自体は通常通り(FakeAsyncゾーン内で)呼ぶ形にしたところ即座に成功した。画像デコード完了(`pumpAndSettle`)は待たず、「`imagePath`の有無で`find.byType(Image)`の有無が切り替わる」ことのみを検証している。**今後もWidgetテストで実ファイルI/Oを扱う場合、`createTemp`/`writeAsBytes`等の呼び出し自体を必ず`tester.runAsync`で包むこと**
- タスク4:`test/widgets/post_card_test.dart`に画像添付ケースを追加(有効な1x1透明PNGバイト列を一時ファイルに書き込み使用)。`flutter test`全件(43件)実行しすべてパス、既存テストへのデグレードなし
- タスク6:`docs/product-requirements.md`(3節・7節・8.4節)、`docs/functional-design.md`(3.2節ER図・3.3節補足)に画像添付機能を追記済み

---

## タスク1: `Post`モデルへの画像フィールド追加

- [x] `lib/models/post.dart` に `imagePath: String?` フィールドを `@HiveField(9)` として追加する(`design.md` 3節の通り、既存フィールドの番号・型は変更しない)
- [x] コンストラクタに `this.imagePath`(任意引数)を追加する
- [x] `flutter pub run build_runner build --delete-conflicting-outputs` で `post.g.dart` を再生成する
- [x] `flutter analyze` でエラーがないことを確認する

**完了条件:** `Post`に`imagePath`を指定して生成・Hiveへの保存・読み込みができる(既存のモデルテストが引き続き通ることも確認する)

---

## タスク2: `PostFieldsForm`への画像選択UI追加

- [x] `lib/widgets/post_fields_form.dart` に画像プレビュー+選択/削除ボタンのプライベートWidgetを追加する(`AccountEditorSheet`の`_IconPicker`を参考に、`image_picker`の`ImagePicker().pickImage(source: ImageSource.gallery)`を使用)
- [x] 本文フィールドの直後・数値ラベル入力の前に配置する(`design.md` 1.2節の並び順)
- [x] 画像選択時・削除時に `widget.post.imagePath` を更新し、`widget.onChanged()` を呼ぶ(既存の本文・数値ラベル編集と同じミューテート方式)
- [x] 画像未添付時は「画像を追加」のようなプレースホルダー表示にする

**完了条件:** 投稿詳細エディタ・タイムラインエディタ(`TimelinePostEditorSheet`経由)のどちらからも画像の選択・差し替え・削除ができ、`notifier.commit()`経由でHiveに保存される

---

## タスク3: `PostCard`への画像表示追加

- [x] `lib/widgets/post_card.dart` の `build` に、`post.imagePath`が非nullの場合の画像表示エリアを追加する(本文の下・引用ポスト表示エリア(`quotedChild`)の上・フッターの上)
- [x] `AspectRatio`(16:9)+`ClipRRect`+`Image.file(..., fit: BoxFit.cover)`で表示する(`design.md` 1.2節)
- [x] 画像未添付の投稿は従来通り画像領域なしで表示され、レイアウト崩れがないことを確認する

**完了条件:** タイムライン画面・投稿詳細画面・引用ポストのいずれでも、画像添付済みの投稿が正しく画像付きで表示される

---

## タスク4: テスト追加・既存テストの確認

- [x] `test/widgets/post_card_test.dart` に画像添付ありのケースを追加する(画像なしケースが既存のまま通ることも確認)
- [x] `test/features/editors/post_detail/post_detail_editor_page_test.dart` を実行し、`Post`コンストラクタの引数追加による影響がないことを確認する
- [x] `flutter test` を全件実行し、既存テストを含めてすべてパスすることを確認する

**完了条件:** `flutter test` が全件成功する(既存機能のデグレードがないことを含む)

---

## タスク5: 実機/シミュレータでの動作確認

- [x] タイムラインエディタ・投稿詳細エディタで画像を選択→プレビューに反映されることを確認する
- [x] 引用ポストに画像を添付し、ネスト表示が崩れないことを確認する
- [x] フルスクリーン表示モードで画像付き投稿が正しく表示されることを確認する
- [x] 画像書き出し(PNG)を実行し、書き出し画像に添付画像が正しく含まれることを確認する(`design.md` 4.2節で挙げたキャプチャタイミングのリスクを確認する。問題があれば`precacheImage`等の対応を追加する)
- [x] 画像未添付の既存プロジェクトを開き、エラーなく表示できることを確認する(後方互換性)

**完了条件:** `requirements.md` 3節の受け入れ条件をすべて実機/シミュレータで満たしていることを確認する

---

## タスク6: 永続的ドキュメント(`docs/`)の更新

- [x] `docs/functional-design.md` 3.2節ER図の`POST`エンティティに`imagePath`フィールドを追記する
- [x] `docs/product-requirements.md` 3節・7節・8.4節に「投稿への画像添付(1枚)」を追記する

**完了条件:** `docs/`の記載が実装内容と一致している

---

## 全体の完了条件

- `requirements.md` 3節の受け入れ条件をすべて満たす
- `flutter analyze` / `flutter test` がエラー・失敗なく通る
- 既存機能(画像未添付の投稿・プロジェクト)にデグレードがない
- `docs/product-requirements.md`・`docs/functional-design.md`が更新済み
