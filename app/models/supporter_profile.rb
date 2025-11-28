class SupporterProfile < ApplicationRecord
  belongs_to :user

  # JSONB配列フィールドの初期化
  %w[standing interests support_genres support_styles personality_traits].each do |attr|
    define_method attr do
      value = read_attribute(attr)
      return [] if value.blank?

      case value
      when Array
        value.compact.reject(&:blank?)
      when String
        begin
          JSON.parse(value)
        rescue JSON::ParserError
          value.split(",").map(&:strip).reject(&:blank?)
        end
      else
        []
      end
    end

    define_method "#{attr}=" do |value|
      case value
      when Array
        # 空文字列やnilを除外してから保存
        clean_value = value.compact.reject(&:blank?)
        write_attribute(attr, clean_value)
      when String
        write_attribute(attr, value.split(",").map(&:strip).reject(&:blank?))
      else
        write_attribute(attr, [])
      end
    end
  end

  # バリデーション
  validates :creation_experience, presence: true
  validates :age_group, presence: true
end
