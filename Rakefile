# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require File.expand_path('../config/application', __FILE__)

Rails.application.load_tasks

namespace :rrc_flaring do
    task :get_lease_pages => :environment do
        get_lease_pages(ENV["COUNTY"], ENV["YEAR"], ENV["START_PAGE_NUM"] || 1)
    end

    task :process_counties do
        process_county_tots
    end



                   
end