require "rails_helper"

RSpec.describe Department, type: :model do
  subject { build(:department) }

  describe "associations" do
    it { is_expected.to have_many(:employees).dependent(:restrict_with_error) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_uniqueness_of(:name).case_insensitive }
  end

  describe "case-insensitive name uniqueness" do
    before { create(:department, name: "Engineering") }

    it "rejects a name differing only in case" do
      duplicate = build(:department, name: "engineering")

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:name]).to include("has already been taken")
    end

    it "is enforced by the database when validations are skipped" do
      duplicate = build(:department, name: "engineering")

      expect { duplicate.save(validate: false) }.to raise_error(ActiveRecord::RecordNotUnique)
    end
  end

  describe "database" do
    it { is_expected.to have_db_index("lower((name)::text)").unique }
  end

  describe "deletion" do
    it "is blocked while employees belong to it" do
      record = create(:department)
      create(:employee, department: record)

      expect(record.destroy).to be(false)
      expect(record.errors[:base]).to be_present
    end
  end
end
