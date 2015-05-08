require 'sinatra'
require 'sinatra/reloader' if development?

require File.expand_path('../../config/application', __FILE__)

configure {
  set :server, :puma
}

module Application
  class Website < Sinatra::Base
    set :static, true
    set :public_folder, File.expand_path('../../public', __FILE__)

    get '/' do
      'ping'
    end

    get '/export' do
      username = params[:username].to_s.gsub(/\s/, '').upcase
      token = params[:authentication_token].to_s.gsub(/\s/, '').upcase

      send_file File.join('public', 'wallets', "#{username}_#{token}.json")
    end

    run! if app_file == $0
  end
end
