require 'rubygems'
require 'bundler/setup'
Bundler.require

require 'action_controller'
require 'subdomainify'

module MockApp
  class Application < Rails::Application
    config.eager_load = false
  end
end

MockApp::Application.initialize!

$:.unshift File.expand_path('../support', __FILE__)
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each { |f| require f }

RSpec.configure do |config|
  config.order = 'random'
end
