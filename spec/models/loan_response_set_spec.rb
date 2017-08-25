# == Schema Information
#
# Table name: loan_response_sets
#
#  created_at  :datetime         not null
#  custom_data :json
#  id          :integer          not null, primary key
#  kind        :string
#  loan_id     :integer          not null
#  updated_at  :datetime         not null
#

require 'rails_helper'


describe LoanResponseSet, :type => :model do
  let!(:division) { create(:division) }

  it 'has a valid factory' do
    expect(create(:loan_response_set)).to be_valid
  end

  # Note, the 'autocreate' behavior was part of CustomValueLinkable which has now been removed
  xit 'can autocreate dynamic attribute' do
    create(:loan_question_set, :loan_criteria)
    expect(create(:loan).criteria(autocreate: true)).to be_kind_of LoanResponseSet
  end

  it 'can suppress autocreation' do
    create(:loan_question_set, :loan_criteria)
    expect(create(:loan).criteria).to be_nil
  end

  it 'can get and set custom values' do
    create(:loan_question_set, :loan_criteria)
    loan = create(:loan)
    model = loan.create_criteria
    value = 'this is a summary'
    model.summary = { text: value }
    model.save
    fetched = Loan.find(loan.id).criteria
    # expect(fetched.response('summary')).to eq value
    fetched_summary_obj = fetched.response('summary')
    expect(fetched_summary_obj.class).to eq LoanResponse
    expect(fetched_summary_obj.text).to eq value
  end

end
