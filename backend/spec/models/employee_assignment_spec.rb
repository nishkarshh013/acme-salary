require "rails_helper"

RSpec.describe EmployeeAssignment, type: :model do
  subject { build(:employee_assignment) }

  describe "associations" do
    it { is_expected.to belong_to(:employee) }
    it { is_expected.to belong_to(:country) }
    it { is_expected.to belong_to(:department) }
    it { is_expected.to belong_to(:job_title) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:effective_date) }
    it { is_expected.to validate_presence_of(:reason) }
  end

  describe "effective date" do
    around { |example| travel_to(Time.zone.local(2026, 6, 15, 12)) { example.run } }

    it "can be today" do
      expect(build(:employee_assignment, effective_date: Date.new(2026, 6, 15))).to be_valid
    end

    it "can't be in the future" do
      assignment = build(:employee_assignment, effective_date: Date.new(2026, 6, 16))

      expect(assignment).not_to be_valid
      expect(assignment.errors[:effective_date]).to include("can't be in the future")
    end
  end

  describe "append-only" do
    let!(:assignment) { create(:employee_assignment, reason: "Promotion") }

    it "can't be updated once saved" do
      expect { assignment.update!(reason: "Transfer") }.to raise_error(ActiveRecord::ReadOnlyRecord)
    end

    it "can't be updated after being loaded from the database" do
      expect { described_class.find(assignment.id).update!(job_title: create(:job_title)) }
        .to raise_error(ActiveRecord::ReadOnlyRecord)
    end

    it "can't be changed with update_column, which skips validations and callbacks" do
      expect { assignment.update_column(:reason, "Transfer") }.to raise_error(ActiveRecord::ReadOnlyRecord)
    end

    it "can't be destroyed" do
      expect { assignment.destroy }.to raise_error(ActiveRecord::ReadOnlyRecord)
      expect(described_class.exists?(assignment.id)).to be(true)
    end

    it "can't be removed with delete, which skips callbacks" do
      expect { assignment.delete }.to raise_error(ActiveRecord::ReadOnlyRecord)
      expect(described_class.exists?(assignment.id)).to be(true)
    end
  end
end
