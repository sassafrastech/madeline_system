# == Schema Information
#
# Table name: documentations
#
#  id                 :bigint           not null, primary key
#  calling_action     :string
#  calling_controller :string
#  html_identifier    :string
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  division_id        :bigint
#
# Indexes
#
#  index_documentations_on_division_id      (division_id)
#  index_documentations_on_html_identifier  (html_identifier) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (division_id => divisions.id)
#

require 'rails_helper'

describe Documentation, type: :model do
  let!(:doc) { create(:documentation, html_identifier: 'chocolate') }

  it_should_behave_like 'translatable', %w(summary_content page_content)

  it 'has a valid factory' do
    expect(create(:documentation)).to be_valid
  end

  describe 'uniqueness of html identifier' do
    it 'can not have duplicate html identifiers' do
      expect {
        create(:documentation, html_identifier: 'chocolate')
      }.to raise_error(ActiveRecord::RecordInvalid)
    end
  end
end
