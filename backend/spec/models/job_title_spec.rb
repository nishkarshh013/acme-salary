require "rails_helper"

RSpec.describe JobTitle, type: :model do
  subject { build(:job_title) }

  describe "associations" do
    it { is_expected.to have_many(:employees).dependent(:restrict_with_error) }
    it { is_expected.to have_many(:employee_assignments).dependent(:restrict_with_error) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_uniqueness_of(:name).case_insensitive }
  end

  describe "case-insensitive name uniqueness" do
    before { create(:job_title, name: "Engineering") }

    it "rejects a name differing only in case" do
      duplicate = build(:job_title, name: "engineering")

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:name]).to include("has already been taken")
    end

    it "is enforced by the database when validations are skipped" do
      duplicate = build(:job_title, name: "engineering")

      expect { duplicate.save(validate: false) }.to raise_error(ActiveRecord::RecordNotUnique)
    end
  end

  describe "deletion" do
    it "is blocked while employees belong to it" do
      record = create(:job_title)
      create(:employee, job_title: record)

      expect(record.destroy).to be(false)
      expect(record.errors[:base]).to be_present
    end

    it "is blocked while only a past assignment refers to it" do
      job_title = create(:job_title)
      employee = create(:employee)
      create(:employee_assignment, employee: employee, job_title: job_title)

      expect(employee.job_title).not_to eq(job_title)
      expect(job_title.destroy).to be(false)
      expect(job_title.errors[:base]).to be_present
      expect(job_title.class.exists?(job_title.id)).to be(true)
    end
  end
end
