module ApplicationHelper
  # adds "http://" if no protocol present
  def urlify(url)
    # Rescue block used to safely pass through raw value if invalid url is provided
    URI(url).scheme ? url : "http://#{url}" rescue url
  end

  # Format datetime with telescoping accuracy based on how distant it is:
  #   within last day: time only
  #   within 6 months: month and day only
  #   longer: month and year only
  # Show full datetime in html `title` attribute for hover
  def fuzzy_time(datetime)
    return unless datetime
    format = case Time.now - datetime
      when 0..24.hours then :time_only
      when 24.hours..6.months then :md_only
      else :my_only
    end
    display = ldate(datetime, format: format)
    full = ldate(datetime, format: "full_tz")
    %Q{<span title="#{full}">#{display}</span>}.html_safe
  end

  def ldate(date, format: nil)
    date ? l(date, format: format) : ""
  end

  # Converts given object/value to json and runs through html_safe.
  # In Rails 4, this is necessary and sufficient to guard against XSS in JSON.
  def json(obj)
    obj.to_json.html_safe
  end

  # Using Id instead of ID is Excel compatible
  def csv_id
    t(:id).capitalize
  end

  def division_policy(record)
    DivisionPolicy.new(current_user, record)
  end

  def organization_policy(record)
    OrganizationPolicy.new(current_user, record)
  end

  def person_policy(record)
    PersonPolicy.new(current_user, record)
  end

  def render_index_grid_with_redirect_check(grid)
    if grid.all_pages_records.count == 1 && grid.filtered_by == ['id']
      # The reason this is done in the helper is that wice_grid doesn't provide any obvious way
      # to do it in the controller.
      controller.redirect_to [:admin, grid.all_pages_records.first]
    else
      render_index_grid(grid)
    end
  end

  # Returns content_tag if the given condition is true, else just whatever is given by block.
  def content_tag_if(condition, *args, &block)
    if condition
      content_tag(*args, &block)
    else
      capture(&block)
    end
  end

  # app version number
  def app_version_number
    @app_version ||= File.read(File.join(Rails.root, "VERSION"))
  end

  def division_select_options(include_root: true, include_all: false, public: false)
    divisions = public ? Division.published : current_user.accessible_divisions
    options = []
    options << [I18n.t("divisions.shared.all"), nil] if include_all
    options += options_tree(divisions.hash_tree,
      include_root: include_root)
  end

  private

  # Takes a hash of the form created by closure_tree's hash_tree method and generates options to be
  # passed into a select menu, recursively padding children with spaces to show tree structure
  def options_tree(hash_tree, depth = 0, include_root: true)
    options = []
    hash_tree.sort_by { |k,v| k.name }.to_h.each do |division, subtree|
      return options_tree(subtree) if !include_root && division.root?
      options << [("&nbsp; &nbsp; " * depth).html_safe << division.name, division.id]
      options += options_tree(subtree, depth + 1)
    end
    options
  end
end
