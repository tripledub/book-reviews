require 'simplecov'

SimpleCov.start 'rails' do
  # Add any custom configuration here
  add_filter '/bin/'
  add_filter '/db/'
  add_filter '/spec/'
  add_filter '/vendor/'
  add_filter '/config/'

  # Exclude application base classes
  add_filter '/application_job.rb'
  add_filter '/application_mailer.rb'
  add_filter '/application_controller.rb'
  add_filter '/application_record.rb'
  add_filter '/application_helper.rb'

  # Track coverage for specific directories
  add_group 'Models', 'app/models'
  add_group 'Controllers', 'app/controllers'
  add_group 'Helpers', 'app/helpers'
  add_group 'Libraries', 'lib'

  # Set minimum coverage threshold (optional)
  # minimum_coverage 80
  # minimum_coverage_by_file 70
end
