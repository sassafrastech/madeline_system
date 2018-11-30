# == Schema Information
#
# Table name: accounting_line_items
#
#  accounting_account_id     :integer          not null
#  accounting_transaction_id :integer          not null
#  amount                    :decimal(, )      not null
#  created_at                :datetime         not null
#  description               :string
#  id                        :integer          not null, primary key
#  posting_type              :string           not null
#  qb_line_id                :integer
#  updated_at                :datetime         not null
#
# Indexes
#
#  index_accounting_line_items_on_accounting_account_id      (accounting_account_id)
#  index_accounting_line_items_on_accounting_transaction_id  (accounting_transaction_id)
#
# Foreign Keys
#
#  fk_rails_...  (accounting_account_id => accounting_accounts.id)
#  fk_rails_...  (accounting_transaction_id => accounting_transactions.id)
#

FactoryBot.define do
  factory :accounting_line_item, class: 'Accounting::LineItem', aliases: [:line_item] do
    qb_line_id { 1 }
    association :parent_transaction, factory: :accounting_transaction
    association :account
    posting_type { ["credit", "debit"].sample }
    description { Faker::Hipster.sentence(4).chomp(".") }
    amount { Faker::Number.decimal(4, 2) }
  end

  factory :line_item_json, class: FactoryStruct do
    skip_create

    transient do
      account { create(:accounting_account) }
      loan { create(:loan) }
      detail_type { "JournalEntryLineDetail" }
      posting_type { ['Credit', 'Debit'].sample}
    end

    sequence(:id, 0) { |n| n }
    amount { Faker::Number.decimal(2) }

    after(:build) do |li, evaluator|
      li.detail_type = evaluator.detail_type
      li.send("#{evaluator.detail_type.underscore}=", {
        "posting_type" => evaluator.posting_type,
        "entity" => {
          "type" => "Customer",
          "entity_ref" => { "value" => rand(1..999), "name" => Faker::App.name, "type" => nil }
        },
        "account_ref" => { "value" => evaluator.account.id, "name" => evaluator.account.name, "type" => nil },
        "class_ref" => {
          "value" => (rand(1..99999) + 5000000000000000000),
          "name" => "Loan Products:Loan ID #{evaluator.loan.id}"
        },
        "department_ref" => nil
      })
    end
  end
end