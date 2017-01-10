# == Schema Information
#
# Table name: projects
#
#  amount                      :decimal(, )
#  created_at                  :datetime         not null
#  currency_id                 :integer
#  custom_data                 :json
#  division_id                 :integer
#  first_interest_payment_date :date
#  first_payment_date          :date
#  id                          :integer          not null, primary key
#  length_months               :integer
#  loan_type_value             :string
#  name                        :string
#  organization_id             :integer
#  primary_agent_id            :integer
#  project_type_value          :string
#  projected_return            :decimal(, )
#  public_level_value          :string
#  rate                        :decimal(, )
#  representative_id           :integer
#  secondary_agent_id          :integer
#  signing_date                :date
#  status_value                :string
#  target_end_date             :date
#  type                        :string           not null
#  updated_at                  :datetime         not null
#
# Indexes
#
#  index_projects_on_currency_id      (currency_id)
#  index_projects_on_division_id      (division_id)
#  index_projects_on_organization_id  (organization_id)
#
# Foreign Keys
#
#  fk_rails_5a4bc9458a  (division_id => divisions.id)
#  fk_rails_7a8d917bd9  (secondary_agent_id => people.id)
#  fk_rails_ade0930898  (currency_id => currencies.id)
#  fk_rails_dc1094f4ed  (organization_id => organizations.id)
#  fk_rails_ded298065b  (representative_id => people.id)
#  fk_rails_e90f6505d8  (primary_agent_id => people.id)
#

class Loan < Project
  include MediaAttachable

  QUESTION_SET_TYPES = %i(criteria post_analysis)
  DEFAULT_STEP_NAME = '[default]'
  STATUS_ACTIVE_VALUE = 'active'
  STATUS_COMPLETED_VALUE = 'completed'

  belongs_to :organization
  belongs_to :currency
  belongs_to :representative, class_name: 'Person'
  has_one :criteria, -> { where("loan_response_sets.kind" => 'criteria') }, class_name: "LoanResponseSet"
  has_one :post_analysis, -> { where("loan_response_sets.kind" => 'post_analysis') }, class_name: "LoanResponseSet"

  scope :country, ->(country) {
    joins(division: :super_division).where('super_divisions_Divisions.Country' => country) unless country == 'all'
  }
  scope :status, ->(status) { where(status: status) }
  scope :visible, -> { where.not(publicity_status: 'hidden') }

  # Beware, the methods generated by this include will fail
  # without the corresponding OptionSet records existing in the database.
  attr_option_settable :status, :loan_type, :project_type, :public_level

  validates :organization_id, presence: true

  def self.status_active_id
    status_option_set.id_for_value(STATUS_ACTIVE_VALUE)
  end

  def self.default_filter
    {status: 'active', country: 'all'}
  end

  def self.filter_by_params(params)
    params.reverse_merge! self.default_filter
    params[:country] = 'Argentina' if params[:division] == :argentina
    scoped = self.all
    scoped = scoped.country(params[:country]) if params[:country]
    scoped = scoped.status(params[:status]) if params[:status]
    scoped
  end

  def agent_names
    [primary_agent.try(:name), secondary_agent.try(:name)].compact
  end

  def default_name
    if organization
      date = signing_date || created_at.to_date
      "#{organization.name} - #{I18n.l(date)}"
    end
  end

  def status
    status_label
  end

  def loan_type
    loan_type_label
  end

  # Gets embedded urls from criteria data. Returns empty array if criteria not defined yet.
  def criteria_embedded_urls
    criteria.try(:embedded_urls) || []
  end

  def country
    # TODO: Temporary fix sets country to US when not found
    # @country ||= Country.where(name: self.division.super_division.country).first || Country.where(name: 'United States').first
    #todo: beware code that expected a country to always exist can break if US country not included in seed.data
    @country ||= organization.try(:country) || Country.where(iso_code: 'US').first
  end

  # def currency
  #   # Revisit the default currency  handling later.  Doesn't not seem to be working as desired,
  #   # and this code currently precludes being able to update the currency from the edit form.
  #   @currency ||= self.country.default_currency
  # end

  def display_currency
    currency ? currency.try(:name) : ''
  end

  def location
    if self.organization.try(:city).present?
      self.organization.city + ', ' + self.country.name
    else self.country.name end
  end

  def signing_date_long
    I18n.l self.signing_date, format: :long if self.signing_date
  end

  # def short_description
  #   self.translation('ShortDescription')
  # end
  # def description
  #   self.translation('Description')
  # end

  def coop_media(limit=100, images_only=false)
    get_media('Cooperatives', self.cooperative.try(:id), limit, images_only)
  end

  def loan_media(limit=100, images_only=false)
    get_media('Loans', self.id, limit, images_only)
  end

  def log_media(limit=100, images_only=false)
    media = []
    begin
      self.logs("Date").each do |log|
        media += log.media(limit - media.count, images_only)
        return media unless limit > media.count
      end
    rescue Mysql2::Error # some logs have invalid dates
    end
    return media
  end

  def featured_pictures(limit=1)
    pics = []
    coop_pics = get_media('Cooperatives', self.cooperative.try(:id), limit, images_only=true).to_a
    # use first coop picture first
    pics << coop_pics.shift if coop_pics.count > 0
    return pics unless limit > pics.count
    # then loan pics
    pics += get_media('Loans', self.id, limit - pics.count, images_only=true)
    return pics unless limit > pics.count
    # then log pics
    pics += self.log_media(limit - pics.count, images_only=true)
    return pics unless limit > pics.count
    # then remaining coop pics
    pics += coop_pics[0, limit - pics.count]
    return pics
  end

  def thumb_path
    if !self.featured_pictures.empty?
      self.featured_pictures.first.paths[:thumb]
    else "/assets/ww-avatar-watermark.png" end
  end

  def ensure_currency
    currency || Currency.find_by(code: 'USD')
  end

  def amount_formatted
    ensure_currency.format_amount(amount)
  end

  def project_events(order_by="Completed IS NULL OR Completed = '0000-00-00', Completed, Date")
    @project_events ||= ProjectEvent.includes(project_logs: :progress_metric).
      where("lower(ProjectTable) = 'loans' and ProjectID = ?", self.ID).order(order_by)
    @project_events.reject do |p|
      # Hide past uncompleted project events without logs (for now)
      !p.completed && p.project_logs.empty? && p.date <= Date.today
    end
  end

  def calendar_events
    CalendarEvent.build_for(self)
  end
end
