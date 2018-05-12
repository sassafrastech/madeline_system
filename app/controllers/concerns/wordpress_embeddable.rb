module WordpressEmbeddable
  extend ActiveSupport::Concern

  included do
    before_action :check_template
    helper_method :layout_site
    layout "public/wordpress"
  end

  def default_site
    :us
  end

  def layout_site
    params[:site].to_sym || default_site
  end

  def update
    skip_authorization
    update_template
    redirect_to controller: "loans", action: "index", site: params[:site]
  end

  private

  def check_template
    template_path = "layouts/public/wordpress/#{Rails.env}/wordpress-#{layout_site}"
    update_template unless template_exists?(template_path)
  end

  def update_template
    base_uri = Rails.configuration.x.wordpress_template[:base_uri][layout_site]

    WordpressTemplate.update(
      division: layout_site,
      base_uri: base_uri
    )
  end
end
