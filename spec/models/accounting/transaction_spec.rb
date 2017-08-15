require 'rails_helper'

RSpec.describe Accounting::Transaction, type: :model do
  let(:loan) { create(:loan, division: create(:division, :with_accounts)) }
  let(:transaction) { create(:accounting_transaction, project: loan) }
  let(:quickbooks_data) do
    { 'line_items' =>
     [{ 'id' => '0',
        'description' => 'Nate desc',
        'amount' => '15.09',
        'detail_type' => 'JournalEntryLineDetail',
        'journal_entry_line_detail' => {
          'posting_type' => 'Debit',
          'entity' => {
            'type' => 'Customer',
            'entity_ref' => { 'value' => '1', 'name' => "Amy's Bird Sanctuary", 'type' => nil } },
          'account_ref' => { 'value' => '84', 'name' => 'Accounts Receivable (A/R)', 'type' => nil },
          'class_ref' => { 'value' => '5000000000000026437', 'name' => loan.id, 'type' => nil },
          'department_ref' => nil } },
      { 'id' => '1',
        'description' => 'Nate desc',
        'amount' => '15.09',
        'detail_type' => 'JournalEntryLineDetail',
        'journal_entry_line_detail' => {
          'posting_type' => 'Credit',
          'entity' => {
            'type' => 'Customer',
            'entity_ref' => { 'value' => '1', 'name' => "Amy's Bird Sanctuary", 'type' => nil } },
          'account_ref' => { 'value' => '35', 'name' => 'Checking', 'type' => nil },
          'class_ref' => { 'value' => '5000000000000026437', 'name' => loan.id, 'type' => nil },
          'department_ref' => nil } }],
      'id' => '167',
      'sync_token' => 0,
      'meta_data' => {
        'create_time' => '2017-04-18T10:14:30.000-07:00',
        'last_updated_time' => '2017-04-18T10:14:30.000-07:00' },
      'txn_date' => '2017-04-18',
      'total' => '19.99',
      'private_note' => 'Nate now testing' }
  end

  context 'when quickbooks_data is updated' do
    subject do
      transaction.tap { transaction.update(quickbooks_data: quickbooks_data) }
    end

    it 'updates correctly' do
      expect(subject.amount).to eq 15.09
      expect(subject.total).to eq 19.99
      expect(subject.txn_date).to eq Date.parse('2017-04-18')
      expect(subject.private_note).to eq 'Nate now testing'
      expect(subject.description).to eq 'Nate desc'
      expect(subject.project_id).to eq loan.id
    end
  end

  context 'when quickbooks_data is nil' do
    subject do
      create(:accounting_transaction,
        amount: 404.02,
        total: 42,
        txn_date: '2017-10-31',
        private_note: 'a memo',
        description: 'desc',
        project_id: loan.id,
      )
    end

    it 'should not overwrite calculated quickbooks fields' do
      expect(subject.amount).to eq 404.02
      expect(subject.total).to eq 42
      expect(subject.txn_date).to eq Date.parse('2017-10-31')
      expect(subject.private_note).to eq 'a memo'
      expect(subject.description).to eq 'desc'
      expect(subject.project_id).to eq loan.id
    end
  end

  describe '.standard_order' do
    let!(:txn_1) do
      create(:accounting_transaction,
        txn_date: Date.today,
        loan_transaction_type_value: 'repayment',
        created_at: Time.now - 1.minutes
      )
    end
    let!(:txn_2) do
      create(:accounting_transaction,
        txn_date: Date.today,
        loan_transaction_type_value: 'disbursement',
        created_at: Time.now - 2.minutes
      )
    end
    let!(:txn_3) do
      create(:accounting_transaction,
        txn_date: Date.today - 3,
        loan_transaction_type_value: 'disbursement',
        created_at: Time.now - 3.minutes
      )
    end
    let!(:txn_4) do
      create(:accounting_transaction,
        txn_date: Date.today - 3,
        loan_transaction_type_value: 'interest',
        created_at: Time.now - 10.minutes
      )
    end
    let!(:txn_5) do
      create(:accounting_transaction,
        txn_date: Date.today - 3,
        loan_transaction_type_value: 'interest',
        created_at: Time.now - 5.minutes
      )
    end

    before do
      OptionSetCreator.new.create_loan_transaction_type
    end

    it 'returns in the right order' do
      expect(Accounting::Transaction.standard_order).to eq([txn_4, txn_5, txn_3, txn_2, txn_1])
    end
  end
end
