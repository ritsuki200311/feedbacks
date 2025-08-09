English Summary
- Voting: Emoji icons replaced with SVG; AJAX submission keeps scroll; “one-vote-only (B)” enforced; ratio bar shows up/down split; net score displayed.
- Screenshot sharing: Say “画像見て” (or send a full path) to auto-import into `design/screenshot[-N].ext`.
- Code structure: Stimulus VoteController handles counts, ratio bar, and lock state; server returns JSON with counts and user vote.
- Next: Sign-in prompt for guests, apply same voting UI to comments, extract controller file, fine-tune colors/widths.

開発ノート（feedbacks）

目的
- セッションをまたいでもコンテキストを共有できるようにする。
- 決定事項・意図・次アクションを素早く把握できる形で一元管理する。

現在の状況（2025-08-08）
- 投票UI
  - アイコン: 絵文字（👍👎/💬）をSVGに置き換え、OS差のない表示に。
  - ページ遷移なし: AJAX化してスクロール位置を保持し、その場更新。
  - 一人一回（方針B）: 投稿への投票は一度のみ。以後は変更・取り消し不可。
  - 割合バー: グレーのベース上に賛成=青・反対=赤で割合を可視化。中央にネット値を表示。
- スクリーンショット共有
  - 既定パス: `design/screenshot[-N].ext`
  - 自動取り込み: チャットで「画像見て」（推奨）と言う、またはフルパス送付で `design/` へ連番保存。
  - 詳細手順: `CODEXCLI.md` と `script/share_screenshot.sh` を参照。

変更ファイル
- `app/views/posts/_post_card.html.erb`: 投票UI（SVG、ネット値、割合バー、Stimulusのdata属性）。
- `app/views/posts/show.html.erb`: 投票UI（同上）。
- `app/views/layouts/application.html.erb`: StimulusのVoteController追加/拡張（AJAX・集計反映・ロック表示）。
- `app/controllers/votes_controller.rb`: JSON応答を追加。B仕様（変更/取り消し不可）をサーバ側で厳格化。`up_count/down_count/net/user_vote` を返す。
- `script/share_screenshot.sh`: 最新スクショの自動検出（Desktop/TemporaryItems）、自動連番で保存。
- `CODEXCLI.md`: 共有フローと自動取り込みトリガーを整備（「画像見て」）。

設計意図 / Rationale
- 一人一回（B仕様）
  - 安定した指標: 投票の揺れ（付け外し・反転）を防ぎ、集計の信頼性を高める。
  - シンプルな状態管理: 「未投票」か「投票済み」の2状態でUI・サーバともに明快。
- AJAX＋位置保持
  - 文脈維持: フィード上で位置が変わらないため、連続閲覧の体験が途切れない。
  - 体感速度: フルリロードを避け即時反映。
- 割合バー
  - 可視性: ネット値だけでなく賛否のバランスを直感的に把握できる。
  - 規範性: よくある投票UIのパターンに準拠（灰→青/赤の塗り分け）。
- SVG採用
  - 一貫性: OSやフォント環境による崩れを回避。
  - 配色容易: アクティブ/無効の状態色をCSSで制御しやすい。
- Stimulusの暫定集約
  - 試作速度: レイアウト内に置くことで迅速に変更・検証可能。
  - 将来移行: 安定後に `app/javascript/controllers/` へ切り出し予定。

UX 詳細
- 投票後
  - 選択側（賛成=緑、反対=赤）を強調表示し、ボタンを無効化。
  - サーバー集計でネット値と割合バーを更新。
- 未ログイン
  - サーバーで弾かれる。今後はクライアント側でも事前にサインイン誘導を表示予定。

次アクション（短期）
1) 未ログイン時の投票でサインイン誘導（トースト/モーダル）。
2) コメント投票にもB仕様＋割合バーを適用（同じコントローラ/データ属性）。
3) トーストによる成功/失敗通知（例: 「投票しました」「すでに投票済みです」）。
4) VoteController を `app/javascript/controllers/vote_controller.js` へ切り出し（importmap）。
5) バーの配色/サイズの微調整（コントラスト、レスポンシブ幅）。

Backlog / 未決事項
- 初期表示での「自分の投票」の明示（現在は色付け済み。補助テキストの要否）。
- 日/週あたりの投票上限（現状: 設けない方針）。
- 高速連打対策（ローカルロック追加の検討）。
- アクセシビリティ（カウント/バー更新時の `aria-live` 追加）。

次回起動時の入り口
- まずこのノートで「何をなぜやったか」「次に何をするか」を確認。
- 投票機能を継続する場合は「次アクション」から着手。
- スクショ共有は「画像見て」または `bash script/share_screenshot.sh` を利用。

クイック操作
- 最新スクショ取り込み: `bash script/share_screenshot.sh`
- 任意ファイルを取り込み: `bash script/share_screenshot.sh "/full/path/to/file.png" optional-name.png`
- - Revertで読み直す: `Cmd-Shift-P` → `File: Revert File`で同期

