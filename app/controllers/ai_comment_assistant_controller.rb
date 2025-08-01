class AiCommentAssistantController < ApplicationController
  before_action :authenticate_user!

  def analyze_post
    @post = Post.find(params[:post_id])
    
    begin
      # Gemini APIにリクエストを送信
      response = call_gemini_api(@post)
      
      render json: {
        success: true,
        comment_examples: response[:comment_examples],
        observation_points: response[:observation_points]
      }
    rescue => e
      Rails.logger.error "Gemini API Error: #{e.message}"
      render json: {
        success: false,
        error: "申し訳ございませんが、AI分析中にエラーが発生しました。しばらく後にもう一度お試しください。"
      }, status: 500
    end
  end

  private

  def call_gemini_api(post)
    require 'net/http'
    require 'json'
    require 'uri'

    # Gemini API endpoint
    api_key = ENV['GOOGLE_GEMINI_API_KEY']
    project_id = ENV['GOOGLE_PROJECT_ID']
    
    if api_key.blank?
      raise "Google Gemini API key is not configured"
    end

    # プロンプトを構築
    prompt = build_prompt(post)
    
    # Gemini API URL (Generative AI API) - Updated to use latest model
    url = URI("https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=#{api_key}")
    
    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true
    
    request = Net::HTTP::Post.new(url)
    request['Content-Type'] = 'application/json'
    
    request.body = {
      contents: [
        {
          parts: [
            {
              text: prompt
            }
          ]
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
    
    if response.code == '200'
      result = JSON.parse(response.body)
      content = result.dig('candidates', 0, 'content', 'parts', 0, 'text')
      
      if content
        parse_gemini_response(content)
      else
        raise "Empty response from Gemini API"
      end
    else
      raise "Gemini API returned status #{response.code}: #{response.body}"
    end
  end

  def build_prompt(post)
    content_type = determine_content_type(post)
    
    prompt = <<~PROMPT
      あなたは投稿に対するコメントを支援するAIです。

      投稿内容:
      - タイトル: #{post.title}
      - 本文: #{post.body}
      - コンテンツタイプ: #{content_type}
      #{"- タグ: #{post.tag}" if post.tag.present?}
      #{"- リクエストタグ: #{post.request_tag}" if post.request_tag.present?}

      以下の2つを提供してください：

      **1. コメント例（3つ）:**
      この投稿に対する適切なコメント例を3つ生成してください。
      - 建設的で前向きなトーン
      - 投稿者への敬意を示す
      - 具体的な観点を含む
      - 各コメントは2-3文程度

      **2. 観察ポイント:**
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

      【観察ポイント】
      - [ポイント1]
      - [ポイント2]
      - [ポイント3]
      - [ポイント4]
    PROMPT

    prompt
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
    # レスポンスを解析してコメント例と観察ポイントを抽出
    comment_examples = []
    observation_points = []
    
    current_section = nil
    
    content.split("\n").each do |line|
      line = line.strip
      next if line.empty?
      
      if line.include?("【コメント例】") || line.include?("コメント例")
        current_section = :comments
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
      observation_points: observation_points
    }
  end
end