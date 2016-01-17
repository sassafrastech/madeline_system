namespace :tww do

  desc "populate db with static migrated data like Currency's and Country's"
  task :populate_static_data => :environment do
    Legacy::StaticData.populate
  end


  # useful when updating and rerunning the populate_static_data task
  desc "remove populated static data"
  task :purge_static_data => :environment do
    Legacy::StaticData.purge
  end

  desc "migrate TWW data from legacy mysql to new postgres db"
  task :migrate_all => :environment do
    Legacy::Migration.migrate_all
  end

  desc "migrate the core TWW data (divisions, coops, members, loans) from legacy mysql to new postgres db (much quicker than the full migration)"
  task :migrate_core => :environment do
    Legacy::Migration.migrate_core
  end

  # note, this task isn't really needed.  generally better to just drop the db,
  # but has been useful when retesting partial migrations during development
  desc "purge target (postgres) data"
  task :purge_migrated => :environment do
    Legacy::Migration.purge_migrated
  end


end
