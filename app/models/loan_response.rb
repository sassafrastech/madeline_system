# Represents multi-value loan criteria or post analysis questionnaire response.
# Currently a wrapper around CustomFieldAddable data, but should perhaps refactor and promote
# to a its own db table

class LoanResponse
  include ProgressCalculable

  attr_accessor :loan
  attr_accessor :custom_field
  attr_accessor :loan_response_set
  attr_accessor :text
  attr_accessor :number
  attr_accessor :boolean
  attr_accessor :rating
  attr_accessor :url
  attr_accessor :start_cell
  attr_accessor :end_cell
  attr_accessor :owner

  delegate :group?, to: :custom_field

  def initialize(loan:, custom_field:, loan_response_set:, data:)
    data = (data || {}).with_indifferent_access
    @loan = loan
    @custom_field = custom_field
    @loan_response_set = loan_response_set
    @text = data[:text]
    @number = data[:number]
    @boolean = data[:boolean]
    @rating = data[:rating]
    @url = data[:url]
    @start_cell = data[:start_cell]
    @end_cell = data[:end_cell]
  end

  def model_name
    'LoanResponse'
  end

  def linked_document
    if url.present?
      LinkedDocument.new(url, start_cell: start_cell, end_cell: end_cell)
    else
      nil
    end
  end

  def field_attributes
    @field_attributes ||= custom_field.value_types
  end

  def has_text?
    field_attributes.include?(:text)
  end

  def has_number?
    field_attributes.include?(:number)
  end

  def has_rating?
    field_attributes.include?(:rating)
  end

  def has_linked_document?
    field_attributes.include?(:url)
  end

  def has_boolean?
    field_attributes.include?(:boolean)
  end

  def blank?
    text.blank? && number.blank? && rating.blank? && boolean.blank? && url.blank?
  end

  def answered?
    !blank?
  end

  # Allows for one line string field to also be presented for 'rating' typed fields
  def text_form_field_type
    custom_field.data_type == 'text' ? :text : :string
  end

  def required?
    @required ||= custom_field.required_for?(loan)
  end

  private

  # Gets child responses of this response by asking LoanResponseSet.
  # Assumes LoanResponseSet's implementation will be super fast (not hitting DB everytime), else
  # performance will be horrible in recursive methods.
  def kids
    @kids ||= loan_response_set.kids_of(self)
  end
end