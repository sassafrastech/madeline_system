require 'rails_helper'

describe Accounting::Quickbooks::PurchaseExtractor, type: :model do
  let(:qb_id) { 1982547353 }
  let(:division) { create(:division, :with_accounts) }
  let(:prin_acct) { division.principal_account}
  let(:int_inc_acct) { division.interest_income_account }
  let(:int_rcv_acct) { division.interest_receivable_account }
  let(:txn_acct) { create(:account, name: 'Some Bank Account') }
  let(:random_acct) { create(:account, name: 'Another Bank Account') }
  let(:loan) { create(:loan, division: division) }

  # This is example Journal entry JSON that might be returned by the QB API.
  # The data are taken from the docs/example_calculation.xlsx file, row 7.
  let(:quickbooks_data) do
    {
      "line_items": [
        {
          "id": "1",
          "line_num": nil,
          "description": '#7801128037',
          "amount": "33458.43",
          "detail_type": "AccountBasedExpenseLineDetail",
          "account_based_expense_line_detail": {
            "customer_ref": {
              "value": "4111",
              "name": "New Era Windows, LLC",
              "type": nil
            },
            "class_ref": {
              "value": "7000000000000495550",
              "name": "Loan Products:Loan ID 1344",
              "type": nil
            },
            "account_ref": {
              "value": "709",
              "name": "Other Long-Term Assets:Loans Receivable",
              "type": nil
            },
            "billable_status": "NotBillable",
            "tax_amount": nil,
            "tax_code_ref": {
              "value": "NON",
              "name": nil,
              "type": nil
            }
          },
          "item_based_expense_line_detail": nil,
          "group_line_detail": nil
        }
      ],
      "global_tax_calculation": nil,
      "id": "23531",
      "sync_token": 1,
      "meta_data": {
        "create_time": "2018-07-17T16:31:32.000-07:00",
        "last_updated_time": "2018-07-17T16:42:32.000-07:00"
      },
      "doc_number": "1397",
      "txn_date": "2018-07-09",
      "private_note": nil,
      "account_ref": {
        "value": txn_acct.id,
        "name": txn_acct.name,
        "type": nil
      },
      "txn_tax_detail": nil,
      "payment_type": "Check",
      "entity_ref": {
        "value": "3594",
        "name": "VEKA",
        "type": "Vendor"
      },
      "remit_to_address": nil,
      "total": "33458.43",
      "print_status": "NotSet",
      "department_ref": nil,
      "currency_ref": {
        "value": "USD",
        "name": "United States Dollar",
        "type": nil
      },
      "exchange_rate": nil,
      "linked_transactions": [],
      "credit": nil
    }
  end

  #let(:txn) { create(:accounting_transaction, project: loan, quickbooks_data: quickbooks_data) }
  #subject { described_class.new(txn) }

  context 'extract!' do

    it 'updates correctly in Madeline' do

      txn = create(:accounting_transaction, project: loan, quickbooks_data: quickbooks_data)
      Accounting::Quickbooks::PurchaseExtractor.new(txn).extract!
      expect(txn.loan_transaction_type_value).to eq 'disbursement'
      expect(txn.managed).to be false
      expect(txn.line_items.size).to eq 2
      expect(txn.line_items[0].description).to eq '#7801128037'
      expect(txn.line_items[1].account).to eq txn.account
      expect(txn.line_items[1].credit?).to be true
      expect(txn.account).to eq txn_acct
      # # amount
      expect(txn.amount).to equal_money(33458.43)


    end


    # def update_transaction_with_new_quickbooks_data
    #   txn.update(quickbooks_data: quickbooks_data)
    #   subject.extract!
    #   txn.save!
    #   txn.reload
    # end
    #
    # def expect_line_item_amounts(amounts)
    #   amounts.each_with_index do |amt, i|
    #     expect(txn.line_items[i].amount).to equal_money(amt)
    #   end
    # end
  end
end
