class CreateJobTitles < ActiveRecord::Migration[8.0]
  def change
    create_table :job_titles do |t|
      t.string :name, null: false

      t.timestamps
    end

    add_index :job_titles, "lower(name)", unique: true, name: "index_job_titles_on_lower_name"
  end
end
