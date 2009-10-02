ENV["RAILS_ENV"] = "test"
require File.expand_path(File.dirname(__FILE__) + "/rails/config/environment")
require 'test_help'
require 'factory_girl'
require 'shoulda'

if defined?(Clearance)
  require 'clearance/../../shoulda_macros/clearance'
end

# Name the root_url for testing
ActionController::Routing::Routes.add_named_route('root', '/', :controller => 'spreadhead/pages', :action => 'show')

class ActiveSupport::TestCase
  self.use_transactional_fixtures = true
  self.use_instantiated_fixtures  = false
  fixtures :all
end