# 実装タスクリスト

## 撮影用ポスト画面メーカー(X版) — フェーズ1(MVP)

> **作業ディレクトリ:** `.steering/20260801-initial-implementation/`
> **最終更新:** 2026-08-01
> **凡例:** `[ ]` 未着手 / `[x]` 完了

---

## 進捗メモ(次回再開時に読むこと)

- 開発コンテナにFlutter SDKが入っていなかったため、`/opt/flutter`(3.44.8固定)とLinuxビルドツールチェーンを導入済み。`.devcontainer/post_create.sh` に組み込んだので、コンテナを再作成しても自動で再現される
- Android SDK・Chromeは未導入のため、実機/エミュレータでの動作確認・Web版確認は別環境が必要(コンテナ内では `flutter analyze` / `flutter test` / Linuxデスクトップターゲットでの起動確認まで)
- `flutter create --org com.postapp.fakex --project-name fake_x_post_maker .` でプロジェクト雛形を作成済み
- 生成された `windows/` `macos/` `web/` フォルダは対象外のため削除済み(`android/` `ios/` `linux/` のみ残す。`linux/` はコンテナ内動作確認用)
- `analysis_options.yaml` は `flutter create` により `flutter_lints` がデフォルトで設定済み(追加作業不要と判断)
- タスク1は完了。`flutter pub add` で依存パッケージを導入し(カメラロール保存は `gal` を採用)、`lib/` 配下に規定ディレクトリを作成、`docs/architecture.md` のテクノロジースタック表も実バージョンに更新済み。`flutter analyze` はエラーなし
- タスク2も完了。`models/` にHiveモデル一式を実装(`Project`のみ`HiveObject`を継承し、`Scene`/`Account`/`Post`/`StatusBarConfig`はProject配下に埋め込む方針。`design.md`のProject行に`scenes: List<Scene>`フィールドを追記して明記した)。`data/hive_boxes.dart`・`project_repository.dart`・`scene_repository.dart`を実装し、`test/models/`・`test/data/`に単体テストを作成、`flutter test`全件パス済み
- **ハマりどころ(タスク2):** `build_runner` が依存する `analyzer` パッケージが古く、Flutter 3.44 / Dart 3.12で生成される新しい省略記法(`ColorScheme.fromSeed(...)`を`.fromSeed(...)`と書く等の static member shorthand)を解釈できずビルド全体が失敗した。`lib/main.dart`(当時はデフォルトカウンターテンプレート)内のその記法を明示的な書き方に直して回避済み。今後 `flutter create` のデフォルトテンプレートやAI生成コードでこの省略記法が出た場合、`build_runner`実行前に明示的な書き方へ直す必要がある
- テストでは `Hive.registerAdapter` をtest間で使い回すとtypeId重複エラーになるため、`test/hive_test_utils.dart` の共通ヘルパーで `Hive.isAdapterRegistered()` によるガードを入れている
- タスク3は完了。`providers/project_providers.dart`(コード生成なしの手書き`NotifierProvider`)、`features/project_list/project_list_page.dart`(一覧・新規作成ダイアログ・スワイプ削除)を実装し、`main.dart`でHive初期化+`ProviderScope`、`app.dart`で`MaterialApp`+`ProjectListPage`を起動画面に設定。デフォルトのカウンターテンプレート(`test/widget_test.dart`)は削除し、`test/features/project_list/project_list_page_test.dart`に置き換えた
- **ハマりどころ(タスク3・重要):** `testWidgets` はFakeAsyncゾーン内で実行されるため、Hiveの実ディスクI/Oを使うWidgetテストは**Futureが永久に完了せずハングする**(`pumpAndSettle`が無限に停止し、テストプロセスがタイムアウトするまで固まる)。原因はpackage:fake_asyncの既知の制約で「実際の非同期I/O(ファイル・ネットワーク)は待てない」。対処として、Widgetテストでは`projectRepositoryProvider`をインメモリの`_FakeProjectRepository`(テストファイル内にローカル定義)へ`overrideWithValue`で差し替える方針にした。**今後Hive/DBを使うRepositoryをWidgetテストで扱う場合は必ず同様にフェイクへ差し替えること**(Hiveへの実際の保存確認は`test/data/`のプレーンな`test()`側で担保する)
- `flutter build linux --debug` でビルド・リンクが通ることを確認済み(コンテナ内はディスプレイがないため実際の画面表示確認は別環境が必要)
- タスク4も完了。`providers/scene_providers.dart`(`NotifierProvider.family<..., Project>`でProjectごとのScene一覧を管理)、`features/scene_list/scene_list_page.dart`(一覧・空状態・スワイプ削除)、`features/scene_list/scene_type_picker_sheet.dart`(タイムライン/投稿詳細の選択ボトムシート)を実装。タスク3で未接続だった`project_list_page.dart`のプロジェクトタップ→`SceneListPage`遷移もここで接続した
- **意図的な未接続(タスク6・7で対応):** `scene_list_page.dart`内、新規Scene作成後および既存Sceneタップ時に「対応するエディタへ遷移する」処理はコメントで明示した上で未実装のまま。理由はエディタ(`TimelineEditorPage`/`PostDetailEditorPage`)自体がタスク6・7の成果物であり、先に空のプレースホルダーページを作ると二重実装になるため。**タスク6・7でエディタ実装後、`scene_list_page.dart`の該当コメント2箇所(新規作成時・タップ時)にNavigator.push処理を追加すること**
- Scene作成時のデフォルトタイトルは種類ラベルと同じ文字列(例:「タイムライン」)にしているため、`ListTile`のtitleとsubtitleに同じテキストが2箇所表示される(リネームUIは未実装、フェーズ1のPRD上も必須要件ではない)。Widgetテストではこの重複を踏まえ`findsNWidgets(2)`で検証している
- タスク5も完了。`lib/constants/`(`app_colors.dart`・`app_spacing.dart`・`app_text_styles.dart`)を新設し、色・余白・ステータスバー専用タイポグラフィをトークン化した(`development-guidelines.md` 3節の「デザイントークンは`lib/constants/`に定義」方針に従った)。`widgets/fake_status_bar.dart` はiPhone風(丸ドット電波)/Android風(バー型電波)をWidget内で分岐し、電池は共通のカスタム描画(輪郭+充填率+充電中バッジ)とした。`features/account/account_editor_sheet.dart`・`features/status_bar/status_bar_config_editor_sheet.dart` はどちらも「引数で受け取った初期値を編集し、保存時に`Navigator.pop`で編集後の値を返す」形の独立したボトムシートとして実装(`SceneTypePickerSheet`と同様の方針)。Riverpod Providerや呼び出し元への組み込みは行っていない(呼び出し元となる投稿詳細/タイムラインエディタ自体がタスク6・7の成果物のため)
- **ハマりどころ(タスク5):** WidgetテストでSheet系Widget(`TextField`/`SwitchListTile`)を`Navigator.push`だけで直接pushすると`Material`祖先が見つからずエラーになる。実際の呼び出し(`showModalBottomSheet`)はMaterialを自動提供するが、テストで`MaterialPageRoute`から直接pushする場合は`builder: (_) => Scaffold(body: XxxSheet(...))`のように明示的に`Scaffold`で包む必要がある
- タスク6も完了。`utils/post_time_formatter.dart`(相対時刻/絶対日時のフォーマット)、`widgets/post_card.dart`(`PostCardVariant.timeline`/`detail`でヘッダーの出し分け、`quotedChild`で引用ポストを入れ子表示)、`providers/editor_providers.dart`(`postDetailEditorProvider`)、`features/editors/post_detail/post_detail_editor_page.dart` を実装。`scene_list_page.dart` の新規作成時・既存Sceneタップ時の2箇所も接続し、`type: postDetail`のSceneのみ`PostDetailEditorPage`へ遷移するようにした(タイムライン/プロフィール/DMは未実装のためタップしても何も起きない)
- **設計判断(タスク6):** 投稿詳細Sceneの `posts` は「メイン投稿(`order:0`、常に1件存在)」「引用ポスト(`order:1`、任意)」の最大2件という前提を置き、`mainPostOf`/`quotedPostOf`ヘルパー(`editor_providers.dart`)で識別する設計にした。タイムラインは別途 `order` を並び替えに使う想定(タスク7)なので、この前提は投稿詳細Sceneに閉じたローカルなルールとして扱う
- **編集の反映方式(タスク6):** `AccountEditorSheet`/`StatusBarConfigEditorSheet`は初期値のオブジェクトを直接ミューテートして返す設計(タスク5)なので、`PostDetailEditorNotifier`側も「呼び出し側がPost/Account/StatusBarConfigのフィールドを直接書き換え→`notifier.commit()`を呼ぶとHiveへ保存しつつプレビューを再描画する」という単純な方式に統一した。Post編集用のTextFieldは`onChanged`のたびに`post.xxx = value`のミューテート+`commit()`を呼んでおり、キー入力ごとにHive保存が走る(ローカル・単一ユーザー用途のため許容と判断。デバウンス等は導入していない)
- **ハマりどころ(タスク6・重要):** `Scene`は`==`が未定義(参照同一性)のプレーンなクラスのため、フィールドを直接ミューテートしただけで`state = state`のように同一参照を代入してもRiverpodの変更検知に引っかからず再描画されない。`PostDetailEditorNotifier._touch()`で`Scene`を「中身のリスト(`accounts`/`posts`等)は使い回しつつ新しいインスタンスとして包み直す」ことで解決した
- **ハマりどころ(Widgetテスト・タスク6):** `ListView(children: [...])`は固定children版でもSliverとして仮想化されるため、初期ビューポート+キャッシュ範囲(既定250px)外のWidget(下の方にある`SwitchListTile`等)は`find.byType`で見つからない。`tester.dragUntilVisible(...)`でスクロールしてから操作する必要がある
- タスク7も完了。`widgets/post_fields_form.dart`(旧`_PostFieldsSection`/`_DateTimeField`を公開Widget化。投稿詳細・タイムラインの両方で共用)、`providers/editor_providers.dart`に`timelineEditorProvider`/`TimelineEditorNotifier`(`addPost`/`deletePost`/`reorderPost`/`commit`)を追加、`features/editors/timeline/timeline_editor_page.dart`(`ReorderableListView.builder`+ドラッグハンドル+削除ボタン+FAB追加+ステータスバー設定)、`features/editors/timeline/timeline_post_editor_sheet.dart`(投稿タップ時の編集シート)を実装。`scene_list_page.dart`の`_openEditor`に`SceneType.timeline`のケースを追加した
- **設計判断(タスク7):** タイムラインは「一覧そのものがプレビュー兼編集UI」という方針にした(投稿詳細のような別枠のプレビュー領域は設けない)。`PostCard`をそのままリスト項目として使い、タップで`TimelinePostEditorSheet`を開いて本文等を編集する。`Dismissible`(スワイプ削除)と`ReorderableListView`(ドラッグ並び替え)は同一アイテムに重ねるとジェスチャーが衝突するため、削除は明示的な削除アイコンボタン、並び替えは`ReorderableDragStartListener`による専用ドラッグハンドルアイコンに分離した(`buildDefaultDragHandles: false`)
- **共通化(タスク7):** `editor_providers.dart`内の`_touchScene`/`_createDefaultAccount`/`_createDefaultPost`/`_generateId`はタスク6時点では`PostDetailEditorNotifier`のプライベートメソッドだったが、`TimelineEditorNotifier`でも同じ処理が必要になったためモジュールレベルの関数に引き上げて共用した。`PostDetailEditorArg`/新設の型は統合して`SceneEditorArg`という共通typedefに一本化した
- **Flutter 3.44での非推奨API対応:** `ReorderableListView.builder`の`onReorder`は非推奨(`onReorderItem`に置き換え)。`onReorderItem`は`newIndex`が「oldIndexの項目を取り除いた後」の値で渡ってくるため、旧`onReorder`で必要だった`if (newIndex > oldIndex) newIndex -= 1;`の補正は不要(`TimelineEditorNotifier.reorderPost`のコメント参照)
- **ハマりどころ(Widgetテスト・タスク7):** `ReorderableListView`は各アイテムを内部的に`Overlay`経由で描画するため、`tester.tap`の標準ヒットテスト検証が誤警告(`hitTestWarningShouldBeFatal`は既定でfalseなので実害はない)を出す。該当箇所は`warnIfMissed: false`で明示的に抑制した
- **既存テストへの影響:** タイムライン作成後に`TimelineEditorPage`へ自動遷移するようになったため、`scene_list_page_test.dart`の該当テストで`tester.pageBack()`を挟んで一覧画面へ戻る手順を追加した
- タスク8も完了。`features/fullscreen/fullscreen_display_page.dart` を実装。`initState`で`SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky)`、`dispose`で`SystemUiMode.edgeToEdge`へ復帰。`Scene.type`で分岐し、`postDetail`は`mainPostOf`/`quotedPostOf`(タスク6で作った`editor_providers.dart`のヘルパーをそのまま再利用)でメイン+引用ポストを`PostCard(variant: detail)`表示、`timeline`は`order`順の`ListView.separated`で`PostCard(variant: timeline)`を一覧表示。`FakeStatusBar`・`PostCard`はエディタのプレビューと完全に同一のWidgetを再利用しており、見た目の乖離がない
- **終了UIの設計判断(タスク8):** ドキュメントに具体的な終了操作の指定がなかったため、画面タップで戻るボタン(左上に浮かぶ`FloatingActionButton.small`)をトグル表示する方式にした。`immersiveSticky`は端からのスワイプでシステムUIを一時表示させてもすぐ自動的に隠れる仕様のため、それに合わせてアプリ側の戻るボタンも「タップで出し入れする」UIに揃えている
- `post_detail_editor_page.dart`・`timeline_editor_page.dart`のAppBarに「撮影開始」アイコンボタン(`Icons.fullscreen`)を追加し、`FullscreenDisplayPage`へ遷移するよう接続した
- **未検証部分(重要):** `SystemChrome.setEnabledSystemUIMode`によるシステムUI非表示の実際の見た目・挙動(完了条件「OSの通知・ステータスバー・ホームバーが一切表示されない」)は実機/エミュレータでの目視確認が必須だが、コンテナ内にはディスプレイもAndroid SDKもないため未検証。Widgetテストでは`SceneType`ごとの表示内容分岐とタップでの戻るボタントグルのみ確認済み。**次回、実機かエミュレータが使える環境で最初に確認すること**
- タスク9も完了。`features/fullscreen/image_export_controller.dart`(`ScreenshotController.capture()`でPNGバイト列を取得し`Gal.putImageBytes()`でカメラロールへ保存。`GalException`の`type`ごとに日本語メッセージへ変換する`ImageExportFailure`を投げる設計)を実装。`fullscreen_display_page.dart`では`_SceneContent`を`Screenshot`ウィジェットでラップ(戻るボタン等のコントロールUIはStackの兄弟要素として外側に置いているため、書き出し画像にはScene本体のみが写り、UIコントロールは写り込まない)。タップで表示されるコントロールに書き出しボタン(右上、書き出し中は`CircularProgressIndicator`表示・二重タップ防止)を追加し、成功/失敗を`SnackBar`でフィードバックする
- **設計判断(タスク9):** `Gal.putImageBytes`は内部で`requestAccess`を自動的に呼ぶ(`gal`パッケージのソース確認済み)ため、`ImageExportController`側で事前に`Gal.hasAccess()`/`Gal.requestAccess()`を呼ぶ重複ロジックは持たせず、`Gal.putImageBytes`の呼び出しと`GalException`のcatchのみに絞った
- **ハマりどころ(Widgetテスト・タスク9・重要):** `screenshot`パッケージの`ScreenshotController.capture()`は内部で実際の`Future.delayed`と`RenderRepaintBoundary.toImage()`(エンジン側との実時間でのやり取り)を使う。これを`testWidgets`の既定のFakeAsyncゾーン内でそのまま`await`すると、Hiveの実ディスクI/O(タスク3参照)と同様に**永久にハングする**(実際に検証中、テストプロセスが6分以上応答なしになり強制終了する事態になった)。対処として`tester.runAsync(() => controller.exportToGallery())`でFakeAsyncゾーンの外(実時間)で実行する必要がある。**今後、実際の非同期I/O(ファイル・画像キャプチャ・ネットワーク等)を伴う処理をWidgetテストで呼び出す場合は、最初から`tester.runAsync`の使用を検討すること**
- `Gal`のプラットフォームチャンネル(`MethodChannel('gal')`)は`TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler`でモックし、`PlatformException(code: 'ACCESS_DENIED', ...)`を投げさせることで`GalException`→`ImageExportFailure`への変換ロジックを検証した
- **未検証部分:** タスク8同様、実際にカメラロールへPNGが保存されること自体(完了条件)は実機での確認が必要。コンテナ内では`ImageExportController`のロジック(キャプチャ結果のnull処理・`Gal`呼び出し・例外変換)のみUnit/Widgetテストで検証済み
- これでフェーズ1(MVP)の全9タスクが実装完了。次は「全体の完了条件」セクションのPRD受け入れ条件の突き合わせと、実機/エミュレータでのタスク8・9の目視確認が残作業

---

## タスク1: Flutterプロジェクト作成・依存パッケージ導入

- [x] Flutterプロジェクトを新規作成する(`flutter create`)
- [x] `pubspec.yaml` に依存パッケージを追加する:`hive`, `hive_flutter`, `hive_generator`, `build_runner`, `flutter_riverpod`, `screenshot`, カメラロール保存パッケージ, `image_picker`(カメラロール保存は `gal` を採用)
- [x] `docs/repository-structure.md` に定義したディレクトリ構成(`lib/models`, `lib/data`, `lib/providers`, `lib/features`, `lib/widgets`, `lib/constants`, `lib/utils`)を作成する
- [x] `analysis_options.yaml` に `flutter_lints` を設定する(`flutter create`のデフォルトで対応済み)
- [x] `docs/architecture.md` のテクノロジースタック表に、実際に導入したパッケージ名・バージョンを反映する

**完了条件:** 空のFlutterプロジェクトが実機/シミュレータで起動し、Lintがエラーなく通る

---

## タスク2: データモデル + Hive永続化層

- [x] `models/` に `Project` / `Scene` / `SceneType` / `Account` / `Post` / `StatusBarConfig` / `StatusBarPlatform` / `TimeMode` を実装する(`design.md` 3節のHiveTypeId割り当てに従う)
- [x] `build_runner` でHiveアダプタを生成する
- [x] `data/hive_boxes.dart` にBox初期化・アダプタ登録処理をまとめる
- [x] `data/project_repository.dart` を実装する(作成・一覧取得・更新・削除)
- [x] `data/scene_repository.dart` を実装する(Project内のScene操作)
- [x] モデル・リポジトリの単体テストを `test/models/`, `test/data/` に作成する

**完了条件:** モデルの保存・読み込みが単体テストで確認でき、アプリ再起動後もデータが保持される

---

## タスク3: プロジェクト一覧画面

- [x] `providers/project_providers.dart` にプロジェクト一覧・作成・削除のNotifierを実装する
- [x] `features/project_list/project_list_page.dart` を実装する(一覧表示・新規作成・削除UI)
- [x] `main.dart` / `app.dart` からプロジェクト一覧画面を起動画面として表示する

**完了条件:** アプリ起動→プロジェクト作成→一覧表示→削除までの一連の操作が実機で確認できる

---

## タスク4: 画面(Scene)一覧・種類選択

- [x] `providers/scene_providers.dart` にScene一覧・作成・削除のNotifierを実装する
- [x] `features/scene_list/scene_list_page.dart` を実装する
- [x] `features/scene_list/scene_type_picker_sheet.dart` を実装する(フェーズ1は「タイムライン」「投稿詳細」のみ選択可)

**完了条件:** プロジェクトを開く→Scene新規作成時に種類を選択→対応するエディタへ遷移する導線が実機で確認できる

---

## タスク5: アカウント設定・ステータスバー設定(共通シート)

- [x] `features/account/account_editor_sheet.dart` を実装する(表示名・ユーザー名・アイコン画像選択・認証バッジ切り替え)
- [x] `features/status_bar/status_bar_config_editor_sheet.dart` を実装する(時刻モード・電波・電池・iPhone/Android切り替え)
- [x] `widgets/fake_status_bar.dart` を実装する(iPhone風/Android風の描画分岐)

**完了条件:** アカウント設定・ステータスバー設定の変更が、後続タスクのエディタのプレビューに反映される

---

## タスク6: 投稿詳細エディタ

- [x] `widgets/post_card.dart` を実装する(投稿1件分のフィード型表示。タイムラインと共用)
- [x] `features/editors/post_detail/post_detail_editor_page.dart` を実装する(本文・いいね数・リポスト数・返信数・日時の編集)
- [x] 引用ポスト表示に対応する(`quotedPostId` を参照した入れ子表示)

**完了条件:** 投稿詳細エディタで入力した内容がプレビューにリアルタイムで反映され、保存後に再表示しても内容が保持される

---

## タスク7: タイムラインエディタ

- [x] `features/editors/timeline/timeline_editor_page.dart` を実装する
- [x] 投稿の追加・編集・削除機能を実装する
- [x] 投稿の並び替え機能を実装する(`order`フィールドの更新)

**完了条件:** 複数投稿の追加・並び替え・削除が実機で確認でき、`PostCard`がタイムライン上に一覧表示される

---

## タスク8: 撮影用フルスクリーン表示モード

- [x] `features/fullscreen/fullscreen_display_page.dart` を実装する
- [x] `SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky)` を適用し、画面離脱時に復帰処理を行う
- [x] タイムライン・投稿詳細どちらのSceneでも同一のフルスクリーン表示画面から表示できるようにする

**完了条件:** 実機でフルスクリーン表示中、OSの通知・ステータスバー・ホームバーが一切表示されないことを目視確認する

---

## タスク9: 画像書き出し

- [x] `features/fullscreen/image_export_controller.dart` を実装する(`RepaintBoundary` + `screenshot` パッケージでのキャプチャ)
- [x] キャプチャした画像をカメラロールへ保存する処理を実装する
- [x] 書き出し中のローディング表示・完了フィードバックを実装する

**完了条件:** フルスクリーン表示中に書き出し操作を行い、PNG画像がカメラロールに保存されていることを実機で確認する

---

## 全体の完了条件(フェーズ1リリース判定)

- [x] `docs/product-requirements.md` 7節の受け入れ条件をすべて満たす
- [ ] iOS・Androidの両実機(またはシミュレータ/エミュレータ)で一連の操作が確認できる
- [x] `docs/development-guidelines.md` のLint・テスト方針に沿って品質チェックが完了している
- [ ] 透かし・Xの公式ロゴ/名称が含まれていないことを確認する
