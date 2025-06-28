class Post < ApplicationRecord
  # 動画ファイルのバリデーションを一時的に無効化
  has_one_attached :video
  has_one_attached :thumbnail

  # 仮想属性
  attr_accessor :filter_list

  # 投稿者との関連
  belongs_to :user, optional: true

  # 関連
  has_many :comments, dependent: :destroy

  # バリデーション
  validates :title, presence: true, length: { minimum: 3, maximum: 100 }
  validates :body, presence: true, length: { minimum: 10, maximum: 10000 }

  validate :validate_video_format
  validate :validate_thumbnail_format

  # タグ
  def tag_list
    tag.to_s.split(',').map(&:strip).reject(&:blank?)
  end

  def tag_list=(value)
    self.tag = value.reject(&:blank?).join(',')
  end

  # recipient_standing getter/setter（配列⇄カンマ区切り）
  def recipient_standing
    read_attribute(:recipient_standing).to_s.split(',').map(&:strip).reject(&:blank?)
  end

  def recipient_standing=(value)
    write_attribute(:recipient_standing, value.is_a?(Array) ? value.reject(&:blank?).join(',') : value)
  end

  def recipient_support_styles
    read_attribute(:recipient_support_styles).to_s.split(',').map(&:strip).reject(&:blank?)
  end

  def recipient_support_styles=(value)
    write_attribute(:recipient_support_styles, value.is_a?(Array) ? value.reject(&:blank?).join(',') : value)
  end

  def recipient_age_group
    read_attribute(:recipient_age_group).to_s.split(',').map(&:strip).reject(&:blank?)
  end

  def recipient_age_group=(value)
    write_attribute(:recipient_age_group, value.is_a?(Array) ? value.reject(&:blank?).join(',') : value)
  end

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
