require 'sinatra'
require 'sinatra/reloader' if development?
require 'json'

require File.expand_path('../../config/application', __FILE__)

configure {
  set :server, :puma
}

module Application
  class Website < Sinatra::Base
    set :static, true
    set :public_folder, File.expand_path('../../public', __FILE__)

    before do
      content_type :json
      headers  'Access-Control-Allow-Origin' => '*',
              'Access-Control-Allow-Methods' => ['OPTIONS', 'GET', 'POST'],
              'Cache-Control' => 'no-cache, no-store, must-revalidate',
              'Pragma' => 'no-cache',
              'Expires' => '0'
    end

    get '/trips' do
      File.read('public/trips.json')
    end

    get '/last_update' do
      {time: File.mtime('public/trips.json')}.to_json
    end

    get '/export' do
      format_params
      save_connections

      send_file File.join('public', 'wallets', "#{params['username']}_#{params['authentication_token']}.json")
    end

    run! if app_file == $0

    protected

    def format_params
      params['mobile_app'] ||= {}
      params['device'] ||= {}
      if params['version']
        params['mobile_app']['version'] = params['version']
      end

      params.reject { |k, v| v.empty? }
      params['device'].merge(params['mobile_app'].inject({}) {|hash, values| hash["mobile_app_#{values.first}"] = values.last; hash })

      params['username']             = params['username'].to_s.gsub(/\s/, '').upcase
      params['authentication_token'] = params['authentication_token'].to_s.gsub(/\s/, '').upcase
    end

    def save_connections
      path = File.expand_path('public/connections.json')

      File.open(path, 'a') do |file|
        file.write "#{params.to_json}, "
      end
    end

    def local_ip
      orig, Socket.do_not_reverse_lookup = Socket.do_not_reverse_lookup, true  # turn off reverse DNS resolution temporarily

      UDPSocket.open do |s|
        s.connect '64.233.187.99', 1
        s.addr.last
      end
    ensure
      Socket.do_not_reverse_lookup = orig
    end
  end
end
