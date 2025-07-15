require "application_system_test_case"

class PostsTest < ApplicationSystemTestCase
  setup do
    @user = users(:one) # users.yml に定義されたユーザーを使用
    sign_in @user # Devise のヘルパーメソッドでログイン
  end

  test "visiting the new post page" do
    visit new_post_url
    assert_selector "h1", text: "新規投稿を作成"
  end

  test "creating a post with only required fields" do
    visit new_post_url

    fill_in "タイトル", with: "テスト投稿タイトル"
    fill_in "本文", with: "これはテスト投稿の本文です。"
    
    # 創作の種類を選択
    choose "イラスト・マンガ" # Post::CREATION_TYPES のキー
    
    # リクエストを選択
    choose "見て！感想ください！" # request_tag_options の値

    click_on "投稿する"

    assert_text "投稿が作成されました。"
    assert_text "テスト投稿タイトル"
  end

  test "creating a post with all text fields and tags" do
    visit new_post_url

    fill_in "タイトル", with: "全てのフィールドを含むテスト投稿"
    fill_in "本文", with: "これは全てのフィールドを含むテスト投稿の本文です。"
    
    choose "詩・小説"
    choose "困ってます！アドバイスください！"

    # タグを選択 (複数選択可能)
    check "批評ください"
    check "優しい意見ください"

    click_on "投稿する"

    assert_text "投稿が作成されました。"
    assert_text "全てのフィールドを含むテスト投稿"
  end

  test "creating a post with a valid image" do
    visit new_post_url

    fill_in "タイトル", with: "画像付きテスト投稿"
    fill_in "本文", with: "これは画像付きテスト投稿の本文です。"
    choose "音楽"
    choose "見て！感想ください！"

    attach_file "画像", Rails.root.join("tmp/test_files/valid_image.png")

    click_on "投稿する"

    assert_text "投稿が作成されました。"
    assert_text "画像付きテスト投稿"
    # assert_selector "img[src*='valid_image.png']" # 画像がアップロードされたことを確認
  end

  test "creating a post with a valid video" do
    visit new_post_url

    fill_in "タイトル", with: "動画付きテスト投稿"
    fill_in "本文", with: "これは動画付きテスト投稿の本文です。"
    choose "イラスト・マンガ"
    choose "困ってます！アドバイスください！"

    attach_file "動画", Rails.root.join("tmp/test_files/valid_video.mp4")

    click_on "投稿する"

    assert_text "投稿が作成されました。"
    assert_text "動画付きテスト投稿"
    # assert_selector "video[src*='valid_video.mp4']" # 動画がアップロードされたことを確認
  end

  test "creating a post with both valid image and video" do
    visit new_post_url

    fill_in "タイトル", with: "画像と動画付きテスト投稿"
    fill_in "本文", with: "これは画像と動画付きテスト投稿の本文です。"
    choose "詩・小説"
    choose "見て！感想ください！"

    attach_file "画像", Rails.root.join("tmp/test_files/valid_image.png")
    attach_file "動画", Rails.root.join("tmp/test_files/valid_video.mp4")

    click_on "投稿する"

    assert_text "投稿が作成されました。"
    assert_text "画像と動画付きテスト投稿"
    # assert_selector "img[src*='valid_image.png']"
    # assert_selector "video[src*='valid_video.mp4']"
  end

  test "attempting to create a post with an invalid image format" do
    visit new_post_url

    fill_in "タイトル", with: "不正な画像形式テスト"
    fill_in "本文", with: "これは不正な画像形式テストの本文です。"
    choose "イラスト・マンガ"
    choose "見て！感想ください！"

    attach_file "画像", Rails.root.join("tmp/test_files/invalid_image.txt")

    click_on "投稿する"

    assert_text "はJPEG、PNG、またはGIF形式の画像を選択してください"
    assert_no_text "投稿が作成されました。"
  end

  test "attempting to create a post with an oversized image" do
    visit new_post_url

    fill_in "タイトル", with: "大きすぎる画像テスト"
    fill_in "本文", with: "これは大きすぎる画像テストの本文です。"
    choose "イラスト・マンガ"
    choose "見て！感想ください！"

    attach_file "画像", Rails.root.join("tmp/test_files/large_image.png")

    click_on "投稿する"

    assert_text "は5MB以下のサイズにしてください"
    assert_no_text "投稿が作成されました。"
  end

  test "attempting to create a post with an invalid video format" do
    visit new_post_url

    fill_in "タイトル", with: "不正な動画形式テスト"
    fill_in "本文", with: "これは不正な動画形式テストの本文です。"
    choose "イラスト・マンガ"
    choose "見て！感想ください！"

    attach_file "動画", Rails.root.join("tmp/test_files/invalid_video.txt")

    click_on "投稿する"

    assert_text "はMP4、MOV、またはAVI形式のファイルを選択してください"
    assert_no_text "投稿が作成されました。"
  end

  test "attempting to create a post with an oversized video" do
    visit new_post_url

    fill_in "タイトル", with: "大きすぎる動画テスト"
    fill_in "本文", with: "これは大きすぎる動画テストの本文です。"
    choose "イラスト・マンガ"
    choose "見て！感想ください！"

    attach_file "動画", Rails.root.join("tmp/test_files/large_video.mp4")

    click_on "投稿する"

    assert_text "は100MB以下のサイズにしてください"
    assert_no_text "投稿が作成されました。"
  end

  test "repeatedly clicking the post button with image" do
    visit new_post_url

    fill_in "タイトル", with: "連打テスト投稿"
    fill_in "本文", with: "これは連打テスト投稿の本文です。"
    choose "イラスト・マンガ"
    choose "見て！感想ください！"

    attach_file "画像", Rails.root.join("tmp/test_files/valid_image.png")

    # 複数回クリックを試みる
    click_on "投稿する"
    click_on "投稿する" # 2回目
    click_on "投稿する" # 3回目

    # 投稿が1回だけ作成されたことを確認（リダイレクト後のページで確認）
    assert_text "投稿が作成されました。", count: 1
    assert_text "連打テスト投稿"
    # 投稿が重複していないことを確認するために、投稿一覧ページに移動して確認することも可能
    # visit posts_url
    # assert_selector "h1", text: "連打テスト投稿", count: 1
  end
end