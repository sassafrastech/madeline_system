# == Schema Information
#
# Table name: documentations
#
#  calling_action     :string
#  calling_controller :string
#  created_at         :datetime         not null
#  html_identifier    :string
#  id                 :integer          not null, primary key
#  previous_url       :string
#  updated_at         :datetime         not null
#
# Indexes
#
#  index_documentations_on_html_identifier  (html_identifier) UNIQUE
#

class Documentation < ApplicationRecord
  include Translatable

  translates :summary_content, :page_content, :page_title

  validates :html_identifier, uniqueness: true
end
