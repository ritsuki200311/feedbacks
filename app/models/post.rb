class Post < ApplicationRecord
  attr_accessor :recipient_standing, :recipient_creation_experience, :recipient_interests,
                :recipient_age_group, :recipient_support_genres, :recipient_support_styles,
                :recipient_personality_traits

  # 動画ファイルのバリデーションを一時的に無効化
  has_many_attached :images
  has_many_attached :videos

  validates :title, presence: true, length: { minimum: 3, maximum: 100 }
  validates :body, presence: true, length: { minimum: 10, maximum: 10000 }

  validate :validate_video_format
  validate :validate_thumbnail_format

  has_many :comments, dependent: :destroy
  belongs_to :user, optional: true
    # validates :video, presence: true  # この行をコメントアウトして無効にする



    # ✅ publicメソッドとして明示的に定義
    def tag_list
      tag.to_s.split(",")
    end

    def tag_list=(value)
      self.tag = value.reject(&:blank?).join(",")
    end

    private

  def validate_video_format
    return unless video.attached?

    unless video.content_type.in?(%w[video/mp4 video/quicktime video/x-msvideo])
      errors.add(:video, "はMP4、MOV、またはAVI形式のファイルを選択してください")
    end

    if video.byte_size > 100.megabytes
      errors.add(:video, "は100MB以下のサイズにしてください")
    end
  end

  def validate_thumbnail_format
    return unless thumbnail.attached?

    unless thumbnail.content_type.in?(%w[image/jpeg image/png image/gif])
      errors.add(:thumbnail, "はJPEG、PNG、またはGIF形式の画像を選択してください")
    end

    if thumbnail.byte_size > 5.megabytes
      errors.add(:thumbnail, "は5MB以下のサイズにしてください")
    end
  end
end
