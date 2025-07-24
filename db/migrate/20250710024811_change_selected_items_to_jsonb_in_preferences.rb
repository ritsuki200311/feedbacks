class ChangeSelectedItemsToJsonbInPreferences < ActiveRecord::Migration[8.0]
  def up
    add_column :preferences, :selected_items_jsonb, :jsonb, default: []

    Preference.find_each do |preference|
      if preference.selected_items.present?
        begin
          # 既存のカンマ区切り文字列を配列に変換し、JSONBカラムに保存
          preference.update_column(:selected_items_jsonb, preference.selected_items.split(',').map(&:strip).to_json)
        rescue JSON::GeneratorError => e
          # JSON変換エラーが発生した場合のログ出力など
          Rails.logger.error "Error converting selected_items for Preference ID #{preference.id}: #{e.message}"
          preference.update_column(:selected_items_jsonb, [].to_json) # エラー時は空の配列を保存
        end
      else
        preference.update_column(:selected_items_jsonb, [].to_json)
      end
    end

    remove_column :preferences, :selected_items
    rename_column :preferences, :selected_items_jsonb, :selected_items
  end

  def down
    add_column :preferences, :selected_items_string, :string

    Preference.find_each do |preference|
      if preference.selected_items.present?
        # JSONBカラムから文字列に変換して保存
        preference.update_column(:selected_items_string, JSON.parse(preference.selected_items.to_json).join(','))
      else
        preference.update_column(:selected_items_string, nil)
      end
    end

    remove_column :preferences, :selected_items
    rename_column :preferences, :selected_items_string, :selected_items
  end
end
