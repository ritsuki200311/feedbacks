class ChangeSupporterProfileAttributesToJsonb < ActiveRecord::Migration[8.0]
  def up
    # カラム定義とデータ移行のヘルパーメソッド
    def migrate_column(table_name, old_column_name, new_column_name)
      add_column table_name, new_column_name, :jsonb, default: []

      # 既存データの移行
      # `find_each` を使用してメモリ消費を抑える
      # `update_column` を使用してバリデーションとコールバックをスキップ
      # `JSON.parse` は文字列が有効なJSONであることを前提とする
      # `rescue JSON::ParserError` で無効なJSON文字列をハンドリング
      # `map(&:strip)` で空白を除去
      klass = table_name.to_s.classify.constantize
      klass.find_each do |record|
        old_value = record.read_attribute(old_column_name)
        if old_value.present?
          begin
            json_array = old_value.split(',').map(&:strip)
            record.update_column(new_column_name, json_array.to_json)
          rescue JSON::GeneratorError, JSON::ParserError => e
            Rails.logger.error "Error converting #{old_column_name} for #{klass.name} ID #{record.id}: #{e.message}"
            record.update_column(new_column_name, [].to_json) # エラー時は空の配列を保存
          end
        else
          record.update_column(new_column_name, [].to_json)
        end
      end

      remove_column table_name, old_column_name
      rename_column table_name, new_column_name, old_column_name
    end

    migrate_column :supporter_profiles, :standing, :standing_jsonb
    migrate_column :supporter_profiles, :interests, :interests_jsonb
    migrate_column :supporter_profiles, :support_genres, :support_genres_jsonb
    migrate_column :supporter_profiles, :support_styles, :support_styles_jsonb
    migrate_column :supporter_profiles, :personality_traits, :personality_traits_jsonb
  end

  def down
    # カラム定義とデータ移行のヘルパーメソッド
    def migrate_column(table_name, old_column_name, new_column_name)
      add_column table_name, new_column_name, :string

      klass = table_name.to_s.classify.constantize
      klass.find_each do |record|
        old_value = record.read_attribute(old_column_name)
        if old_value.present?
          begin
            # JSONBカラムから文字列に変換して保存
            string_value = JSON.parse(old_value.to_json).join(',')
            record.update_column(new_column_name, string_value)
          rescue JSON::ParserError => e
            Rails.logger.error "Error converting #{old_column_name} for #{klass.name} ID #{record.id}: #{e.message}"
            record.update_column(new_column_name, nil) # エラー時はnilを保存
          end
        else
          record.update_column(new_column_name, nil)
        end
      end

      remove_column table_name, old_column_name
      rename_column table_name, new_column_name, old_column_name
    end

    migrate_column :supporter_profiles, :standing, :standing_string
    migrate_column :supporter_profiles, :interests, :interests_string
    migrate_column :supporter_profiles, :support_genres, :support_genres_string
    migrate_column :supporter_profiles, :support_styles, :support_styles_string
    migrate_column :supporter_profiles, :personality_traits, :personality_traits_string
  end
end
