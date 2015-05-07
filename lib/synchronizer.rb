require_relative './synchronizer/downloader'
require_relative './synchronizer/file_manager'
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

  # extract base url from config
  #
  # @return [String] the base url
  def base_url
    "#{config['protocol']}://#{config['host']}/"
  end

  # get the trips from destinationbook server
  #
  # @return [String] data retrieved from destinationbook
  def get_trips
    url = "#{base_url}#{config['uri']['trips']}"

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

  # synchronize wallets if it's modified since last_update
  #
  # @param booking [Hash] the hash representing the booking
  # @param trip [Hash] the hash representing the trip
  # @return [Hash] the hash representing the booking
  def synchronize_wallet(booking, trip)
    file = FileManager.new("public/wallets/#{booking['username']}_#{booking['authentication_token']}.json")
    updated_at = newer_time(Time.parse(trip['updated_at']), Time.parse(booking['updated_at']))

    return unless update_wallet?(file, updated_at)
    get_wallet(file, booking['username'], booking['authentication_token'], updated_at)

    booking
  end

  # download the wallet from server and wites it to a file
  #
  # @param file [Synchronizer::FileManager] the file where to write result
  # @param username [String] the username of the wallet
  # @param token [String] the authentication token for the wallet
  # @param updated_at [Time] the time of last update of the wallet
  def get_wallet(file, username, token, updated_at)
    url = "#{base_url}#{config['uri']['wallet']}"

    file.data = Downloader.get(url, 'username' => username, 'authentication_token' => token, 'device[uuid]' => 'boatserver', 'version' => '2.0.0')
    file.write!
    file.set_mtime(updated_at)
  end

  # return the most recent time
  #
  # @param time_a [Time] first time to compare
  # @param time_b [Time] second time to compare
  # @return [Time] the most recent time
  def newer_time(time_a, time_b)
    time_a > time_b ? time_a : time_b
  rescue
    return time_a if time_a.is_a?(Time)
    return time_b if time_b.is_a?(Time)
    raise StandardError.new('No time given to compare')
  end

  # define if wallet needs to be updated or not
  #
  # @param file [Synchronizer::FileManager] the file that may need an update
  # @param compare_time [Time] the trip last update
  # @return [Boolean] true if need for update
  def update_wallet?(file, compare_time)
    return true if !file.exists?
    file.updated_at < compare_time
  end
end
