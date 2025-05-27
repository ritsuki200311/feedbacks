class Post < ApplicationRecord
  # 動画ファイルのバリデーションを一時的に無効化
  has_one_attached :video
  has_one_attached :thumbnail
  
  validates :title, presence: true, length: { minimum: 3, maximum: 100 }
  validates :body, presence: true, length: { minimum: 10, maximum: 10000 }
  
  validate :validate_video_format
  validate :validate_thumbnail_format
  
  has_many :comments, dependent: :destroy
  belongs_to :user, optional: true
  # validates :video, presence: true  # この行をコメントアウトして無効にする

  private

  def validate_video_format
    return unless video.attached?
    
    unless video.content_type.in?(%w[video/mp4 video/quicktime video/x-msvideo])
      errors.add(:video, 'はMP4、MOV、またはAVI形式のファイルを選択してください')
    end
    
    if video.byte_size > 100.megabytes
      errors.add(:video, 'は100MB以下のサイズにしてください')
    end
  end

  def validate_thumbnail_format
    return unless thumbnail.attached?
    
    unless thumbnail.content_type.in?(%w[image/jpeg image/png image/gif])
      errors.add(:thumbnail, 'はJPEG、PNG、またはGIF形式の画像を選択してください')
    end
    
    if thumbnail.byte_size > 5.megabytes
      errors.add(:thumbnail, 'は5MB以下のサイズにしてください')
    end
  end
end