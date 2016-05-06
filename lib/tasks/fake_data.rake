if Rails.env.development?
  namespace :dev do
    desc "Generate UI testing data"
    task fake_data: :environment do
      # Create root division
      Division.find_or_create_by(name: "Root", parent: nil)

      # Create admin user
      password = admin_password
      user = User.create(email: admin_user, password: password, password_confirmation: password)
      user.add_role :admin, Division.root
      puts "Created default admin user"
      puts "Login: #{user.email}"
      puts "Password: #{password}"

      # Create default option sets
      load_option_sets
      puts "Loaded default option sets"

      # Create some data
      FactoryGirl.create_list(:loan, 15,
        :with_translations,
        :with_foreign_translations,
        :with_log_media,
        :with_loan_media,
        :with_coop_media,
        :with_project_steps)
      puts "Generated fake data"
    end
  end
end

def admin_password
  Rails.application.secrets.admin_password || Faker::Internet.password
end

def admin_user
  Rails.application.secrets.admin_user || Faker::Internet.email
end

def load_option_sets(file: Rails.root.join("db", "option_sets.yml"))
  option_set_data = YAML.load(File.open(file))

  option_set_data.each do |model_name, model_attributes|
    model_class_name = model_name.classify

    model_attributes.each do |model_attribute_name, options|
      option_set = OptionSet.find_or_create_by(
        division: Division.root,
        model_type: model_class_name,
        model_attribute: model_attribute_name
      )

      options.each do |option_name, option_attributes|
        option_set.options.create({value: option_name}.merge(option_attributes))
      end
    end
  end
end