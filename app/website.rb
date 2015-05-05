require 'sinatra'
require 'sinatra/reloader' if development?

require File.expand_path('../../config/application', __FILE__)

module Application
  class Website < Sinatra::Base
    set :static, true
    set :public_folder, File.expand_path('../../public', __FILE__)

    get '/' do
      'ping'
    end
  end
end
