class CreateActions < ActiveRecord::Migration
  def change
    create_table :actions do |t|
      t.references :campaign_page, index: true, foreign_key: true
      t.references :action_user, index: true, foreign_key: true
      t.string :link
      t.boolean :created_user
      t.boolean :subscribed_user

      t.timestamps null: false
    end
  end
end
