class CreateExchangeRates < ActiveRecord::Migration[8.0]
  def change
    create_table :exchange_rates do |t|
      t.string :currency_code, limit: 3, null: false
      t.decimal :rate_to_usd, precision: 18, scale: 8, null: false
      t.date :as_of, null: false

      t.timestamps
    end

    add_index :exchange_rates, :currency_code, unique: true
    add_check_constraint :exchange_rates, "rate_to_usd > 0", name: "exchange_rates_rate_to_usd_positive"
  end
end
