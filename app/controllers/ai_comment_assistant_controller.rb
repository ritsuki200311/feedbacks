class AiCommentAssistantController < ApplicationController
  before_action :authenticate_user!
  skip_before_action :verify_authenticity_token, only: [ :analyze_post ]
  before_action :check_rate_limit, only: [ :analyze_post ]

  def analyze_post
    @post = Post.find(params[:post_id])

    # AI機能を一時的に停止し、フォールバック値を返す
    Rails.logger.info "AI analysis requested for post #{@post.id} - returning fallback values (API disabled)"

    result = {
      success: true,
      comment_examples: [
        "とても素晴らしい作品ですね。#{@post.title}の表現が印象的です。",
        "この作品から#{determine_content_type(@post)}としての魅力を感じました。",
        "#{@post.user.name}さんの創作への情熱が伝わってきます。"
      ],
      observation_points: [
        "作品の構成や全体のバランスに注目してみましょう",
        "使用されている技法や表現手法を観察してみましょう",
        "作品から受ける感情や印象を言葉にしてみましょう",
        "改善点や発展の可能性について考えてみましょう"
      ],
      vocabularies: [
        "美しい", "印象的", "繊細", "力強い",
        "調和", "表現力", "創造的", "独創的"
      ]
    }

    render json: result
  end

  private

  def check_rate_limit
    # ユーザーごとのレート制限（5分間に3回まで）
    rate_limit_key = "ai_rate_limit_user_#{current_user.id}"
    current_count = Rails.cache.read(rate_limit_key) || 0

    if current_count >= 3
      render json: {
        success: false,
        error: "AI機能の利用制限に達しました。5分後に再度お試しください。"
      }, status: 429
      return
    end

    # カウントを更新
    Rails.cache.write(rate_limit_key, current_count + 1, expires_in: 5.minutes)
  end

  def call_gemini_api(post)
    require "net/http"
    require "json"
    require "uri"
    require "base64"

    # Gemini API endpoint
    api_key = ENV["GOOGLE_GEMINI_API_KEY"] || Rails.application.credentials.dig(:google, :gemini_api_key) || "AIzaSyBPrMWaLrF2OacBXokFMTXdXyP0D5gIOx8"
    project_id = ENV["GOOGLE_PROJECT_ID"]

    if api_key.blank?
      raise "Google Gemini API key is not configured. Please set GOOGLE_GEMINI_API_KEY in your .env file."
    end

    # 画像がある場合はVision対応モデルを使用
    model = post.images.attached? ? "gemini-1.5-flash" : "gemini-1.5-flash"
    url = URI("https://generativelanguage.googleapis.com/v1/models/#{model}:generateContent?key=#{api_key}")

    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true

    request = Net::HTTP::Post.new(url)
    request["Content-Type"] = "application/json"

    # プロンプトを構築
    prompt = build_prompt(post)

    # リクエストボディにプロンプト＋画像を含める
    parts = [ { text: prompt } ]

    # 画像がある場合は画像データを追加
    if post.images.attached?
      Rails.logger.info "Processing #{post.images.count} images for AI analysis"

      post.images.each_with_index do |image, index|
        begin
          # 画像サイズをチェック（5MB制限）
          if image.byte_size > 5.megabytes
            Rails.logger.warn "Image #{index + 1} too large (#{image.byte_size} bytes), skipping"
            next
          end

          # 対応フォーマットをチェック
          unless %w[image/jpeg image/png image/gif image/webp].include?(image.content_type)
            Rails.logger.warn "Image #{index + 1} format not supported (#{image.content_type}), skipping"
            next
          end

          # 画像データを取得してBase64エンコード
          image_data = image.download
          mime_type = image.content_type
          base64_data = Base64.strict_encode64(image_data)

          parts << {
            inline_data: {
              mime_type: mime_type,
              data: base64_data
            }
          }

          Rails.logger.info "Successfully processed image #{index + 1} (#{mime_type}, #{image.byte_size} bytes)"

        rescue => e
          Rails.logger.error "Error processing image #{index + 1}: #{e.message}"
          Rails.logger.error e.backtrace.join("\n")
          # 画像処理エラーは無視して続行
        end
      end

      Rails.logger.info "Total #{parts.count - 1} images added to AI request"
    end

    request.body = {
      contents: [
        {
          parts: parts
        }
      ],
      generationConfig: {
        temperature: 0.7,
        topK: 40,
        topP: 0.95,
        maxOutputTokens: 2048
      }
    }.to_json

    response = http.request(request)

    if response.code == "200"
      result = JSON.parse(response.body)
      content = result.dig("candidates", 0, "content", "parts", 0, "text")

      Rails.logger.info "Gemini API response content: #{content}"

      if content
        parsed_result = parse_gemini_response(content)
        Rails.logger.info "Parsed result: #{parsed_result}"
        parsed_result
      else
        raise "Empty response from Gemini API"
      end
    else
      raise "Gemini API returned status #{response.code}: #{response.body}"
    end
  end

  def build_prompt(post)
    content_type = determine_content_type(post)

    base_prompt = <<~PROMPT
      あなたは投稿に対するコメントを支援するAIです。

      投稿内容:
      - タイトル: #{post.title}
      - 本文: #{post.body}
      - コンテンツタイプ: #{content_type}
      #{"- タグ: #{post.tag}" if post.tag.present?}
      #{"- リクエストタグ: #{post.request_tag}" if post.request_tag.present?}
    PROMPT

    # 画像がある場合は画像分析を含むプロンプト
    if post.images.attached?
      image_prompt = <<~IMAGE_PROMPT

        添付された画像を詳細に分析して、以下の点について具体的に言及してください：
        - 色彩、構図、技法などの視覚的要素
        - 表現されている内容やテーマ
        - 印象的な部分や特徴的な要素
        - 技術的な評価点

        以下の3つを提供してください：

        **1. コメント例（3つ）:**
        画像の内容を踏まえた具体的なコメント例を3つ生成してください。
        - 画像の具体的な要素に言及する
        - 建設的で前向きなトーン
        - 投稿者への敬意を示す
        - 技術的な観点も含める
        - 各コメントは2-3文程度

        **2. 語彙・表現（6-8個）:**
        この画像を表現するのに適した語彙やキーワードを提示してください。
        - 色彩、質感、雰囲気を表す言葉
        - 芸術的・美的表現に使える語彙
        - 感情や印象を表現する言葉
        - 単語のみ（「静謐」「透明感」「ノスタルジー」など）

        **3. 観察ポイント:**
        この画像投稿を分析する際の観察ポイントを提示してください。
        - 画像の構成要素（色彩、線、形、空間など）
        - 技法や表現手法
        - 感情や印象
        - 改善提案の観点

        **回答形式:**
        以下の形式で回答してください：

        【コメント例】
        1. [具体的な画像要素に言及したコメント例1]
        2. [具体的な画像要素に言及したコメント例2]
        3. [具体的な画像要素に言及したコメント例3]

        【語彙・表現】
        - [語彙1]
        - [語彙2]
        - [語彙3]
        - [語彙4]
        - [語彙5]
        - [語彙6]

        【観察ポイント】
        - [ポイント1]
        - [ポイント2]
        - [ポイント3]
        - [ポイント4]
        - [ポイント5]
      IMAGE_PROMPT

      base_prompt + image_prompt
    else
      # 画像がない場合は従来のプロンプト
      text_prompt = <<~TEXT_PROMPT

        以下の3つを提供してください：

        **1. コメント例（3つ）:**
        この投稿に対する適切なコメント例を3つ生成してください。
        - 建設的で前向きなトーン
        - 投稿者への敬意を示す
        - 具体的な観点を含む
        - 各コメントは2-3文程度

        **2. 語彙・表現（6-8個）:**
        この投稿の内容を表現するのに適した語彙やキーワードを提示してください。
        - 内容のテーマに関連する表現
        - 感情や印象を表現する言葉
        - 建設的なフィードバックに使える語彙
        - 単語のみ（「独創的」「丁寧」「情熱的」など）

        **3. 観察ポイント:**
        この投稿を分析する際の観察ポイントを提示してください。
        - コンテンツの種類に応じた見方
        - 注目すべき要素
        - 深い理解のためのヒント

        **回答形式:**
        以下の形式で回答してください：

        【コメント例】
        1. [コメント例1]
        2. [コメント例2]
        3. [コメント例3]

        【語彙・表現】
        - [語彙1]
        - [語彙2]
        - [語彙3]
        - [語彙4]
        - [語彙5]
        - [語彙6]

        【観察ポイント】
        - [ポイント1]
        - [ポイント2]
        - [ポイント3]
        - [ポイント4]
      TEXT_PROMPT

      base_prompt + text_prompt
    end
  end

  def determine_content_type(post)
    if post.images.attached?
      if post.videos.attached?
        "画像・動画投稿"
      else
        "画像投稿"
      end
    elsif post.videos.attached?
      "動画投稿"
    else
      "テキスト投稿"
    end
  end


  def parse_gemini_response(content)
    # レスポンスを解析してコメント例、語彙、観察ポイントを抽出
    comment_examples = []
    vocabularies = []
    observation_points = []

    current_section = nil

    content.split("\n").each do |line|
      line = line.strip
      next if line.empty?

      if line.include?("【コメント例】") || line.include?("コメント例")
        current_section = :comments
        next
      elsif line.include?("【語彙・表現】") || line.include?("語彙・表現")
        current_section = :vocabularies
        next
      elsif line.include?("【観察ポイント】") || line.include?("観察ポイント")
        current_section = :observations
        next
      end

      case current_section
      when :comments
        if match = line.match(/^\d+\.\s*(.+)$/)
          comment_examples << match[1]
        elsif line.match(/^[・-]\s*(.+)$/) && comment_examples.empty?
          comment_examples << $1
        end
      when :vocabularies
        if match = line.match(/^[・-]\s*(.+)$/)
          vocabularies << match[1]
        elsif match = line.match(/^\d+\.\s*(.+)$/)
          vocabularies << match[1]
        end
      when :observations
        if match = line.match(/^[・-]\s*(.+)$/)
          observation_points << match[1]
        elsif match = line.match(/^\d+\.\s*(.+)$/)
          observation_points << match[1]
        end
      end
    end

    # フォールバック: パースに失敗した場合のデフォルト
    if comment_examples.empty?
      comment_examples = [
        "とても興味深い投稿ですね。特に#{determine_content_type(Post.find(params[:post_id]))}として魅力的だと思います。",
        "この作品の表現力に感銘を受けました。今後の作品も楽しみにしています。",
        "素晴らしい投稿をありがとうございます。参考になりました。"
      ]
    end

    if observation_points.empty?
      observation_points = [
        "投稿の目的や意図を考えてみる",
        "使用されている技法や手法に注目する",
        "感情や印象を言葉にしてみる",
        "改善点や発展の可能性を考える"
      ]
    end

    {
      comment_examples: comment_examples,
      vocabularies: vocabularies,
      observation_points: observation_points
    }
  end
end
