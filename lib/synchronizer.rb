require_relative './synchronizer/downloader'
require 'yaml'
require 'json'
require 'time'

class Synchronizer
  attr_accessor :api_key, :trips

  # return config for synchronizer from settings.yaml
  #
  # @return [Hash] the config
  def config
    @config ||= begin
      config = YAML::load(File.open('config/settings.yaml'))
      config['synchronizer']
    end
  end

  # get the trips from destinationbook server
  #
  # @return [String] data retrieved from destinationbook
  def get_trips
    url = "#{config['protocol']}://#{config['host']}/#{config['uri']['trips']}"

    Downloader.get(url, api_key: config['api_key'])
  end

  # return the trips available to download
  #
  # @return [Array] trips
  def load_trips_json
    json = JSON.load(get_trips) || {}

    self.trips = json['trips'] || []
    trips
  end

  # find all the booking needed to synchronize
  #
  # @return [Array] trips
  def synchronize
    load_trips_json

    trips.each do |trip|
      trip['bookings'].each do |booking|
        synchronize_wallet(booking, trip)
      end
    end
  end

  def synchronize_wallet(booking, trip)
    url = "#{config['protocol']}://#{config['host']}/#{config['uri']['wallet']}"

    Downloader.get(url, 'username' => username, 'authentication_token' => token, 'device[uuid]' => 'boatserver', 'version' => '2.0.0')
  end
end
