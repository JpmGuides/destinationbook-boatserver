# spec/spec_helper.rb
require 'rack/test'
require 'rspec'
require 'webmock/rspec'

require File.expand_path '../../app/website.rb', __FILE__
require File.expand_path '../../lib/synchronizer.rb', __FILE__


ENV['RACK_ENV'] = 'test'

module RSpecMixin
  include Rack::Test::Methods
  def app() Application::Website end
end

# For RSpec 2.x
RSpec.configure do |config|
  config.include RSpecMixin

  config.after(:all) do
    system 'rm -rf spec/tmp'
  end
end
