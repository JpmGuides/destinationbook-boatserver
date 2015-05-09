require_relative './synchronizer/downloader'
require_relative './synchronizer/file_manager'
require_relative './synchronizer/assets'
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

    Downloader.get(url, authentication_token: config['api_key'])
  end

  # return the trips available to download
  #
  # @return [Array] trips
  def load_trips_json
    json_string = get_trips
    json = JSON.load(json_string) || {}

    self.trips = json['trips'] || []
    json_string
  end

  # find all the booking needed to synchronize
  #
  # @return [Boolean] true
  def synchronize
    file = FileManager.new('public/trips', load_trips_json)
    return if file.unmodified_data?

    synchronize_wallets
    synchronize_guides

    file.write!
  end

  # loop over all trips to proceed to thier download
  #
  # @return [Array] available trips for client
  def synchronize_wallets
    trips.each do |trip|
      trip['bookings'].each do |booking|
        synchronize_wallet(booking, trip)
      end
    end
  end

  # loop over all guides to download them
  #
  # @return [Arry] available trips for client
  def synchronize_guides
    trips.each do |trip|
      trip['guides'].each do |guide|
        synchronize_guide(guide)
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

    return unless update?(file, updated_at)
    get_wallet(file, booking['username'], booking['authentication_token'], updated_at)

    booking
  end

  # synchronize guide if it's modified since last_update
  #
  # @param booking [Hash] the hash representing the guide
  # @return [Hash] the hash representing the guide
  def synchronize_guide(guide)
    guide_uri = URI(guide['url'])
    file = FileManager.new("public#{guide_uri.path}")
    updated_at = Time.parse(guide['generated_at'])

    return unless update?(file, updated_at)
    get_guide(file, guide_uri, updated_at)

    guide
  end

  # download the wallet from server and wites it to a file
  #
  # @param file [Synchronizer::FileManager] the file where to write result
  # @param username [String] the username of the wallet
  # @param token [String] the authentication token for the wallet
  # @param updated_at [Time] the time of last update of the wallet
  def get_wallet(file, username, token, updated_at)
    url = "#{base_url}#{config['uri']['wallet']}"

    wallet_data = Downloader.get(url, 'username' => username, 'authentication_token' => token, 'device[uuid]' => 'boatserver', 'version' => '2.0.0')
    file.data = Assets.download(wallet_data)
    file.write!
    file.set_mtime(updated_at)
  end

  def get_guide(file, uri, updated_at)
    params = URI.decode_www_form(uri.query).to_h

    file.data = Downloader.get(uri.to_s, params)
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
  def update?(file, compare_time)
    return true if !file.exists?
    file.updated_at < compare_time
  end
end
