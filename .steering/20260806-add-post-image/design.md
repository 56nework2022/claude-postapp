# 実装設計

## 投稿への画像添付機能(写真付きポスト対応)

> **作業ディレクトリ:** `.steering/20260806-add-post-image/`
> **最終更新:** 2026-08-06
> **前提:** `requirements.md` のスコープ(投稿1件につき画像1枚、既存`image_picker`を利用)に基づく。既存の「共通インフラ + 種類別エディタ」構成(`docs/functional-design.md` 2節)・共通Widget再利用方針(`PostCard`/`PostFieldsForm`をタイムライン・投稿詳細・引用ポストで共用)はそのまま踏襲する

---

## 1. 実装アプローチ

### 1.1 全体方針

新規の画面やProviderは作らず、既存の3レイヤー(`Post`モデル → `PostFieldsForm`/`PostCard`共通Widget → 各エディタページ)に画像フィールドを差し込む形で実装する。`PostFieldsForm`・`PostCard`はタイムライン/投稿詳細/引用ポストの3箇所すべてで共用されているため、この2つのWidgetを変更するだけで要件(3節「受け入れ条件」)を全箇所で満たせる。

エディタページ(`PostDetailEditorPage` / `TimelineEditorPage` / `TimelinePostEditorSheet`)は `PostFieldsForm` を呼び出すだけの構造のため、変更不要。

### 1.2 主要な技術的決定事項

| 項目 | 決定内容 | 理由 |
|---|---|---|
| 画像選択方法 | `AccountEditorSheet`の`_IconPicker`と同じ`image_picker`(`ImagePicker().pickImage(source: ImageSource.gallery)`)を使う | 新規パッケージを追加しない(`requirements.md`制約)。既存パターンを踏襲し実装・レビューコストを下げる |
| 画像の保持方法 | `Account.iconImagePath`と同様、選択したファイルの絶対パスを`String?`としてそのままモデルに保持する(アプリ内ストレージへのコピーは行わない) | 既存のアイコン画像実装と同じ方針に揃える。コピー処理を追加するとスコープが広がるため今回は見送る |
| UI配置(編集側) | `PostFieldsForm`内に本文フィールドの直後、数値ラベル入力の前に画像プレビュー+選択/削除ボタンを追加する | 本文に紐づく要素として自然な位置。数値ラベルより先に置き、Xの投稿作成画面の一般的な並び(本文→添付→数値)に近づける |
| UI配置(表示側) | `PostCard`内、本文の下・引用ポスト表示エリアの上・フッター(いいね等)の上に画像を表示する | `requirements.md`受け入れ条件の並び順。引用ポストは`quotedChild`として別枠表示のため画像と重ならない |
| 画像の表示比率 | `AspectRatio`(16:9)+`ClipRRect`+`BoxFit.cover`で固定表示する | Xの投稿画像は元のアスペクト比を保たないトリミング表示が一般的。フェーズ1の簡易実装として固定比率とし、可変比率対応は今回のスコープ外とする |
| 状態管理・保存経路 | `PostFieldsForm`が`widget.post.imagePath`を直接ミューテートし、既存の`onChanged`(`notifier.commit`)を呼ぶ。新しいProvider/Notifierメソッドは追加しない | 既存の本文・数値ラベル編集と全く同じ「Widget側で直接ミューテート→`onChanged`」パターンに合わせる。`ProjectNotifier`/`SceneNotifier`側の変更は不要 |
| Hiveスキーマ変更 | `Post`に`@HiveField(9)`として`imagePath: String?`を追加。既存の`HiveField(0)`〜`(8)`は番号・意味とも変更しない | `requirements.md`制約(後方互換性)を満たす。Hiveは未知の新規フィールドを持たない旧データを読む際、新フィールドを`null`として扱えるため、既存プロジェクトの読み込みが壊れない |
| コード生成 | `post.g.dart`は手で編集せず、`flutter pub run build_runner build --delete-conflicting-outputs`で再生成する | `docs/architecture.md`・初回実装時の方針(Hiveアダプタはコード生成のみで運用)を踏襲する |

### 1.3 実装順序

1. `Post`モデルに`imagePath`フィールドを追加し、`build_runner`で`post.g.dart`を再生成
2. `PostFieldsForm`に画像選択UI(`_PostImagePicker`相当のプライベートWidget)を追加
3. `PostCard`に画像表示エリアを追加
4. 既存テスト(`post_card_test.dart`, `post_detail_editor_page_test.dart`)を画像なしケースで実行し、表示崩れがないことを確認(退行防止)
5. 画像添付ありのケースを対象にウィジェットテストを追加
6. 実機/シミュレータでタイムライン・投稿詳細・引用ポスト・フルスクリーン表示・画像書き出しの一連の流れを目視確認

各ステップ完了時に `flutter analyze` を実行する。

---

## 2. 変更するコンポーネント

| コンポーネント | 変更種別 | 内容 |
|---|---|---|
| `lib/models/post.dart` | 変更 | `imagePath: String?`フィールド追加(`HiveField(9)`)、コンストラクタに`this.imagePath`(任意)を追加 |
| `lib/models/post.g.dart` | 自動再生成 | `build_runner`実行により`PostAdapter`の`read`/`write`に`imagePath`を反映 |
| `lib/widgets/post_fields_form.dart` | 変更 | 画像プレビュー・選択・削除ボタンを追加するプライベートWidgetを追加し、`_PostFieldsFormState.build`に組み込む |
| `lib/widgets/post_card.dart` | 変更 | `imagePath`が非null時に画像表示エリアを描画する処理を`PostCard.build`に追加 |
| `test/widgets/post_card_test.dart` | 変更 | 画像添付ありケースのテストケースを追加(既存の画像なしケースはそのまま通ることを確認) |
| `test/features/editors/post_detail/post_detail_editor_page_test.dart` | 確認のみ | `Post`コンストラクタに新規オプション引数が増えるが、`required`ではないため既存呼び出しは無修正で動作する見込み。念のため実行して確認する |

**変更不要なコンポーネント(理由)**

- `lib/providers/editor_providers.dart` / `scene_providers.dart` — 保存経路は既存の`commit()`のまま
- `lib/features/editors/post_detail/post_detail_editor_page.dart` / `timeline/*` — `PostFieldsForm`/`PostCard`を呼び出すだけの構造のため無変更
- `lib/features/fullscreen/fullscreen_display_page.dart` / `image_export_controller.dart` — `PostCard`をそのまま再利用してキャプチャする構造のため無変更(要件4節の通り)

---

## 3. データ構造の変更

`docs/functional-design.md` 3.2節ER図の`POST`エンティティに、以下のフィールドを追加する。

| フィールド | 型 | HiveField番号 | 説明 |
|---|---|---|---|
| `imagePath` | `String?` | 9(新規) | 添付画像の端末ローカルファイルパス。未添付時は`null` |

既存フィールド(`id`〜`order`、HiveField 0〜8)は番号・型とも変更しない。

```dart
@HiveType(typeId: 4)
class Post {
  Post({
    required this.id,
    required this.accountId,
    required this.body,
    required this.likeCountLabel,
    required this.repostCountLabel,
    required this.replyCountLabel,
    required this.postedAt,
    required this.order,
    this.quotedPostId,
    this.imagePath, // 追加
  });

  // ...既存フィールド(HiveField 0〜8)は変更なし...

  @HiveField(9)
  String? imagePath;
}
```

---

## 4. 影響範囲の分析

### 4.1 永続的ドキュメント(`docs/`)への影響

- `docs/functional-design.md` 3.2節ER図(`POST`エンティティ)に`imagePath`フィールドを追記する
- `docs/functional-design.md` 7節ワイヤフレーム(投稿詳細・タイムライン)に画像表示の一例を追記する(任意、必須ではない)
- `docs/product-requirements.md` 3節(主要な機能一覧・フェーズ1)、7節(受け入れ条件)、8.4節(主要機能フェーズ1)に「投稿への画像添付(1枚)」を追記する
- `docs/architecture.md`・`docs/repository-structure.md` — 新規パッケージ・新規ディレクトリを追加しないため変更不要

これらは実装完了後、`tasklist.md`の最終タスクとしてまとめて更新する。

### 4.2 既存機能への影響

- **後方互換性:** 既存プロジェクト(画像未添付の`Post`データ)は`imagePath`が`null`として読み込まれ、画像領域なしで表示される。挙動は現状から変化しない
- **フルスクリーン表示・画像書き出し:** `PostCard`を再利用する既存の仕組みにより、追加実装なしで画像も含めてキャプチャされる。ただし画像読み込み(`Image.file`)が非同期的にレイアウトへ反映されるタイミングによっては、キャプチャ時に画像が未描画になるリスクがある。動作確認(実装順序5)で問題が見つかった場合、`precacheImage`等での事前読み込みを追加検討する
- **タイムライン・投稿詳細・引用ポストの3箇所すべて:** `PostCard`/`PostFieldsForm`の共通化により一括で対応できるが、裏を返すと3箇所すべてで表示崩れがないか確認が必要(特に引用ポストのネスト表示との組み合わせ)

### 4.3 今後の拡張への影響

- 将来的に複数枚(2〜4枚)対応する場合、`imagePath: String?`を`imagePaths: List<String>`へ拡張する必要がある。その際もHiveField番号は新規追加とし、`imagePath`は非推奨として残すか、マイグレーション処理を別途設計する(本作業では対応しない)

---

## 5. 今後の検討事項

- 複数枚画像(グリッド表示)対応の要否・時期
- 画像をアプリ内ストレージにコピーして保持する方式への変更要否(元ファイルが端末から削除・移動された場合に画像が表示できなくなるリスクへの対応)
- フルスクリーン表示/画像書き出し時の画像読み込みタイミング問題が実際に発生するかどうかの検証
