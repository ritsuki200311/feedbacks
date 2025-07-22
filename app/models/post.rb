class Post < ApplicationRecord
  attr_accessor :recipient_standing, :recipient_creation_experience, :recipient_interests,
                :recipient_age_group, :recipient_support_genres, :recipient_support_styles,
                :recipient_personality_traits

  # 動画ファイルのバリデーションを一時的に無効化
  CREATION_TYPES = { 'イラスト・マンガ': 0, '詩・小説': 1, '音楽': 2 }.freeze

  def self.creation_types
    CREATION_TYPES.keys.map(&:to_s)
  end

  def creation_type_humanize
    CREATION_TYPES.key(creation_type).to_s.humanize
  end
  has_many_attached :images
  has_many_attached :videos

  validates :title, presence: true, length: { minimum: 3, maximum: 100 }
    validates :body, presence: true, length: { maximum: 10000 }
  

  validate :validate_video_format
  validate :validate_image_format

  has_many :comments, dependent: :destroy
  has_many :votes, as: :votable, dependent: :destroy
  belongs_to :user, optional: true
    # validates :video, presence: true  # この行をコメントアウトして無効にする



    # ✅ publicメソッドとして明示的に定義
    def tag_list
      tag.to_s.split(",")
    end

    def tag_list=(value)
      self.tag = Array(value).reject(&:blank?).join(",")
    end

    private

  def validate_video_format
    return unless videos.attached?

    videos.each do |video|
      unless video.content_type.in?(%w[video/mp4 video/quicktime video/x-msvideo])
        errors.add(:videos, "はMP4、MOV、またはAVI形式のファイルを選択してください")
      end

      if video.byte_size > 500.megabytes
        errors.add(:videos, "は500MB以下のサイズにしてください")
      end
    end
  end

  def validate_image_format
    return unless images.attached?

    images.each do |image|
      unless image.content_type.in?(%w[image/jpeg image/png image/gif])
        errors.add(:images, "はJPEG、PNG、またはGIF形式の画像を選択してください")
      end

      if image.byte_size > 5.megabytes
        errors.add(:images, "は5MB以下のサイズにしてください")
      end
    end
  end
end
