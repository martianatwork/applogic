class CreateReferrals < ActiveRecord::Migration[5.2]
  def change
    create_table :referrals do |t|
      t.column      :trade_id,      :string, null: true
      t.column      :referrer_uid,      :string,  limit: 14,   null: true
      t.column      :user_uid,      :string,  limit: 14,   null: false
      t.column      :key,      :integer,  null: false
      t.column      :aasm_state,      :string,  limit: 30,   null: false
      t.column      :currency,      :string,  limit: 30,   null: true
      t.column      :currency_type,      :string,  limit: 30,   null: true
      t.column      :kind,      :string,  limit: 30,   null: false
      t.column      :side,      :string,  limit: 14,   null: false
      t.column      :amount,      :decimal,  precision: 32, scale: 16,   null: false
      t.column      :account_dst,      :integer, null: false
      t.column      :account_src,      :integer, null: false
      t.column      :reason,      :string, null: true
      t.timestamps
      t.datetime    :completed_at, null: true
    end
  end
end
