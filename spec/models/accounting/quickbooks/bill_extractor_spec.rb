require 'rails_helper'

describe Accounting::QB::BillExtractor, type: :model do
  let(:qb_id) { 1982547353 }
  let(:division) { create(:division, :with_accounts) }
  let(:prin_acct) { division.principal_account }
  let(:int_inc_acct) { division.interest_income_account }
  let(:int_rcv_acct) { division.interest_receivable_account }
  let(:txn_acct) { create(:account, name: 'Some Bank Account') }
  let(:random_acct) { create(:account, name: 'Another Bank Account') }
  let(:loan) { create(:loan, division: division) }

  let(:quickbooks_data) do
    create(:transaction_json,
      loan: loan,
      debit_accounts: [prin_acct],
      credit_accounts: [txn_acct],
      type: "Bill",
      total: 20527.35
    )
  end
  let(:txn) { Accounting::Transaction.create_or_update_from_qb_object!(qb_object_type: "Purchase", qb_object: quickbooks_data) }

  context 'extract!' do
    it 'updates correctly in Madeline' do
      Accounting::QB::BillExtractor.new(txn).extract!
      expect(txn.loan_transaction_type_value).to eq 'disbursement'
      expect(txn.managed).to be false
      expect(txn.line_items.size).to eq 2
      expect(txn.line_items.last.account).to eq txn.account
      expect(txn.line_items.last.credit?).to be true
      expect(txn.account).to eq txn_acct
      expect(txn.amount).to equal_money(20527.35)
    end
  end
end
