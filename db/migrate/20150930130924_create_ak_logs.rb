class CreateAkLogs < ActiveRecord::Migration
  def change
    create_table :ak_logs do |t|
      t.text :request_body
      t.text :response_body
      t.string :response_status
      t.string :resource

      t.timestamps null: false
    end
  end
end
