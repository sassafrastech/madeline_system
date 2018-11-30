# == Schema Information
#
# Table name: accounting_transactions
#
#  accounting_account_id       :integer
#  amount                      :decimal(, )
#  created_at                  :datetime         not null
#  currency_id                 :integer
#  description                 :string
#  id                          :integer          not null, primary key
#  interest_balance            :decimal(, )      default(0.0)
#  loan_transaction_type_value :string
#  managed                     :boolean          default(FALSE), not null
#  needs_qb_push               :boolean          default(TRUE), not null
#  principal_balance           :decimal(, )      default(0.0)
#  private_note                :string
#  project_id                  :integer
#  qb_id                       :string
#  qb_object_type              :string           default("JournalEntry"), not null
#  quickbooks_data             :json
#  total                       :decimal(, )
#  txn_date                    :date
#  updated_at                  :datetime         not null
#
# Indexes
#
#  index_accounting_transactions_on_accounting_account_id     (accounting_account_id)
#  index_accounting_transactions_on_currency_id               (currency_id)
#  index_accounting_transactions_on_project_id                (project_id)
#  index_accounting_transactions_on_qb_id                     (qb_id)
#  index_accounting_transactions_on_qb_id_and_qb_object_type  (qb_id,qb_object_type) UNIQUE
#  index_accounting_transactions_on_qb_object_type            (qb_object_type)
#
# Foreign Keys
#
#  fk_rails_...  (accounting_account_id => accounting_accounts.id)
#  fk_rails_...  (currency_id => currencies.id)
#  fk_rails_...  (project_id => projects.id)
#

FactoryBot.define do
  factory :accounting_transaction, class: 'Accounting::Transaction', aliases: [:journal_entry_transaction] do
    # division is not an attribute here but we need to access the accounts associated
    # this is only for some traits below
    transient do
      division { nil }
    end

    sequence(:qb_id)
    qb_object_type { 'JournalEntry' }
    quickbooks_data { {} }
    loan_transaction_type_value { %w(interest disbursement repayment).sample }
    txn_date { Faker::Date.between(30.days.ago, Date.today) }
    amount { Faker::Number.decimal(4, 2) }
    account
    project
    managed { true }

    trait :interest do
      loan_transaction_type_value { 'interest' }
      amount { 3.25 }
    end

    trait :disbursement do
      loan_transaction_type_value { 'disbursement' }
      amount { 100 }
    end

    trait :repayment do
      loan_transaction_type_value { 'repayment' }
      amount { 23.7 }
    end

    trait :interest_with_line_items do
      loan_transaction_type_value { 'interest' }
      amount { 3.25 }

      after(:create) do |txn, evaluator|
        create(:line_item, parent_transaction: txn, account: evaluator.division.interest_receivable_account,
          posting_type: 'Debit', amount: evaluator.amount)
        create(:line_item, parent_transaction: txn, account: evaluator.division.interest_income_account,
          posting_type: 'credit', amount: evaluator.amount)
      end
    end

    trait :disbursement_with_line_items do
      loan_transaction_type_value { 'disbursement' }
      amount { 100 }

      after(:create) do |txn, evaluator|
        create(:line_item, parent_transaction: txn, account: txn.account,
          posting_type: 'Credit', amount: evaluator.amount)
        create(:line_item, parent_transaction: txn, account: evaluator.division.principal_account,
          posting_type: 'Debit', amount: evaluator.amount)
      end
    end

    trait :repayment_with_line_items do
      loan_transaction_type_value { 'repayment' }
      amount { 23.7 }

      after(:create) do |txn, evaluator|
        create(:line_item, parent_transaction: txn, account: txn.account,
          posting_type: 'Debit', amount: evaluator.amount)
        create(:line_item, parent_transaction: txn, account: evaluator.division.interest_receivable_account,
          posting_type: 'Credit', amount: evaluator.amount.to_f / 2)
        create(:line_item, parent_transaction: txn, account: evaluator.division.principal_account,
          posting_type: 'Credit', amount: evaluator.amount.to_f / 2)
      end
    end

    trait :unmanaged do
      managed { false }
    end
  end

  factory :transaction_json, class: FactoryStruct do
    transient do
      credit_accounts { create_list(:accounting_account, 1) }
      debit_accounts { create_list(:accounting_account, 1) }
      date { Faker::Time.between(3.years.ago, 1.week.ago) }
      loan { create(:loan) }
      type { "JournalEntry" }
      total { (rand(10000..999999999) / 100.0).round(2) }
    end

    skip_create

    sequence(:id, 1000) { |n| n }
    sync_token { 0 }
    doc_number { "MS-Managed" }
    private_note { Faker::Hipster.paragraph }

    after(:build) do |txn, evaluator|
      create_time = Faker::Time.between(evaluator.date.midnight, (evaluator.date + 1).midnight)
      txn.meta_data = {
        "create_time" => create_time.strftime("%FT%H%M%S.%L%:z"),
        "last_updated_time" => Faker::Time.between(create_time, 1.hour.ago).strftime("%FT%H%M%S.%L%:z")
      }
      txn.txn_date = evaluator.date.strftime("%F")
      txn.line_items = []

      credit_accounts = evaluator.credit_accounts
      credit_totals = evaluator.total.partition(credit_accounts.count)

      credit_accounts.each_with_index do |acct, i|
        txn.line_items << build(:line_item_json,
          loan: evaluator.loan,
          account: acct,
          posting_type: "Credit",
          detail_type: "#{evaluator.type}LineDetail",
          amount: credit_totals[i]
        )
      end

      debit_accounts = evaluator.debit_accounts
      debit_totals = evaluator.total.partition(debit_accounts.count)

      debit_accounts.each_with_index do |acct, i|
        txn.line_items << build(:line_item_json,
          loan: evaluator.loan,
          account: acct,
          posting_type: "Debit",
          detail_type: "#{evaluator.type}LineDetail",
          amount: debit_totals[i]
        )
      end
      txn.total = evaluator.total
    end
  end
end