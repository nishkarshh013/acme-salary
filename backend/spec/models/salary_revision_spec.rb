require "rails_helper"

RSpec.describe SalaryRevision, type: :model do
  subject { build(:salary_revision) }

  describe "associations" do
    it { is_expected.to belong_to(:employee) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:amount) }
    it { is_expected.to validate_presence_of(:currency) }
    it { is_expected.to validate_presence_of(:effective_date) }
    it { is_expected.to validate_presence_of(:reason) }

    it { is_expected.to validate_numericality_of(:amount).is_greater_than(0) }
    it { is_expected.to validate_numericality_of(:previous_amount).is_greater_than(0).allow_nil }

    it { is_expected.to allow_value("INR").for(:currency) }
    it { is_expected.not_to allow_value("RUPEE", "IN").for(:currency) }

    it "allows no previous_amount for an employee's first revision" do
      expect(build(:salary_revision, previous_amount: nil)).to be_valid
    end
  end

  describe "effective date" do
    around { |example| travel_to(Time.zone.local(2026, 6, 15, 12)) { example.run } }

    it "can be today" do
      expect(build(:salary_revision, effective_date: Date.new(2026, 6, 15))).to be_valid
    end

    it "can't be in the future" do
      revision = build(:salary_revision, effective_date: Date.new(2026, 6, 16))

      expect(revision).not_to be_valid
      expect(revision.errors[:effective_date]).to include("can't be in the future")
    end
  end

  describe "append-only" do
    let!(:revision) { create(:salary_revision, reason: "Annual review") }

    it "can't be updated once saved" do
      expect { revision.update!(reason: "Typo fix") }.to raise_error(ActiveRecord::ReadOnlyRecord)
    end

    it "can't be updated after being loaded from the database" do
      expect { described_class.find(revision.id).update!(reason: "Typo fix") }
        .to raise_error(ActiveRecord::ReadOnlyRecord)
    end

    it "can't be changed with update_column, which skips validations and callbacks" do
      expect { revision.update_column(:amount, 1) }.to raise_error(ActiveRecord::ReadOnlyRecord)
    end

    it "can't be destroyed" do
      expect { revision.destroy }.to raise_error(ActiveRecord::ReadOnlyRecord)
      expect(described_class.exists?(revision.id)).to be(true)
    end

    it "can't be removed with delete, which skips callbacks" do
      expect { revision.delete }.to raise_error(ActiveRecord::ReadOnlyRecord)
      expect(described_class.exists?(revision.id)).to be(true)
    end
  end

  describe "money" do
    it "keeps both amounts exactly, without float rounding" do
      revision = create(:salary_revision, amount: BigDecimal("1234567.89"),
                                          previous_amount: BigDecimal("1000000.01"))

      reloaded = described_class.find(revision.id)
      expect(reloaded.amount).to eq(BigDecimal("1234567.89"))
      expect(reloaded.previous_amount).to eq(BigDecimal("1000000.01"))
    end

    it "is rejected by the database when the amount is not positive" do
      revision = build(:salary_revision, amount: 0)

      expect { revision.save(validate: false) }
        .to raise_error(ActiveRecord::StatementInvalid, /salary_revisions_amount_positive/)
    end
  end
end
