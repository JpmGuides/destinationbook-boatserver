require_relative './synchronizer/downloader'
require_relative './synchronizer/file_manager'
require_relative './synchronizer/assets'
require_relative '../app/models/guide'
require 'yaml'
require 'json'
require 'time'
require 'net/ftp'

class Synchronizer
  attr_accessor :api_key, :trips, :guides

  def self.config
    Synchronizer.new.config
  end

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
    trips = []
    url = "#{base_url}#{config['uri']['trips']}"
    page = 0

    begin
      puts(page)

      json_string = Downloader.get(url, authentication_token: config['api_key'], page: page)

      json = JSON.load(json_string) || {}
      page_trips = json['trips'] || []
      trips += page_trips

      page = page + 1
    end while page_trips.count > 0

    trips = trips.select {|t| t['reference'] =~ /^#{config['filter']}.*$/} if config['filter']
    trips
  end

  # return the trips available to download
  #
  # @return [Array] trips
  def load_trips_json
    self.trips = get_trips
    load_guides_json
    trips.reject! {|t| t['type'] == 'content'}
    trips.to_json
  end

  # extract all differents guides for trips
  #
  # @return [Array] guides
  def load_guides_json
    self.guides = []
    trips.each do |trip|
      if trip.has_key?('guides') && trip['guides'].is_a?(Array)
        trip['guides'].each do |guide|
          guides.push(guide)
        end
      end
    end

    guides.uniq! do |guide|
      guide['id']
    end
  end

  # find all the booking needed to synchronize
  #
  # @return [Boolean] true
  def synchronize
    file = FileManager.new('public/trips.json', load_trips_json)

    synchronize_wallets
    synchronize_guides

    Guide.all.each(&:unzip)

    file.data = {'trips' => trips}.to_json
    file.write!
  end

  # post connections to server
  #
  def post_connections
    path = File.expand_path('public/connections.json')
    tmp = File.expand_path('public/connections.json.tmp')
    json_string = ''

    Net::FTP.open(config['ftp_host'], config['ftp_username'], config['ftp_password']) do |ftp|
      ftp.passive = true
      ftp.puttextfile(path)
      ftp.puttextfile(tmp)
    end

    if File.exists?(tmp)
      json_string += File.read(tmp)
      system 'rm', tmp
    end
    if File.exists?(path)
      json_string += File.read(path)
      system 'rm', path
    end
  rescue
    puts 'error on posting connections'
    File.open(tmp, 'w') do |file|
      file.write json_string
    end
  end

  # loop over all trips to proceed to thier download
  #
  # @return [Array] available trips for client
  def synchronize_wallets
    trips.each_with_index do |trip, index|
      puts "synchronizing trip #{index}, on #{trips.count}"

      trip['bookings'].each do |booking|
        begin
          synchronize_wallet(booking, trip)
        rescue
          puts "unable to sychronize #{trip['username']}"
          raise
        end
      end
    end
  end

  # loop over all guides to download them
  #
  # @return [Arry] available trips for client
  def synchronize_guides
    guides.each_with_index do |guide, index|
      puts "synchronizing guides #{guide['id']}"
      synchronize_guide(guide)
      genereate_trip_json(guide)
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
    guide['url'] = guide_uri.path

    return unless update?(file, updated_at)
    get_guide(file, guide_uri, updated_at)

    guide
  rescue
    puts "unable to synchronize guide"
  end

  # download the wallet from server and wites it to a file
  #
  # @param file [Synchronizer::FileManager] the file where to write result
  # @param username [String] the username of the wallet
  # @param token [String] the authentication token for the wallet
  # @param updated_at [Time] the time of last update of the wallet
  def get_wallet(file, username, token, updated_at)
    url = "#{base_url}#{config['uri']['wallet']}"

    wallet_data = Downloader.get(url, 'username' => username, 'authentication_token' => token, 'device[uuid]' => config['device']['uuid'], 'version' => '2.0.0')
    file.data = Assets.download(wallet_data, without_guides: true)
    file.write!
    file.set_mtime(updated_at)
  end

  def get_guide(file, uri, updated_at)
    params = URI.decode_www_form(uri.query)

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

  # generate trip.json for each guide_ids
  #
  # @param guide [Hash] representing the guides data
  def genereate_trip_json(guide)
    trip_json = JSON.parse(File.read('lib/synchronizer/base_trip.json'))
    soft_id = guide['id'].gsub('.', '-')
    soft_id.upcase!

    client_reference = config['client_reference'] || 'HKLF'

    trip_json['reference'] = soft_id
    trip_json['file_count'] = trip_json['file_count'] + 1
    trip_json['files_size'] = trip_json['files_size'] + guide['size']
    trip_json['name'] = guide['name']
    trip_json['description'] = guide['description']
    trip_json['token'] = "#{client_reference}#{soft_id}"
    trip_json['styles']['background_image']['url'] = "http://#{config['local_url']}.xip.io/export_cache/backgrounds/aqua.jpg"
    trip_json['styles']['logo']['url'] = "http://#{config['local_url']}.xip.io/export_cache/logo/client/11.png"

    guide_json = {
      "size" => guide['size'],
      "generated_at" => guide['generated_at'],
      "id" => guide['id'],
      "order" => 1,
      "url" => "http://#{config['local_url']}.xip.io/guides/smartphone/#{guide['id']}/guide_tiled.zip"
    }
    trip_json['guides'].push(guide_json)

    FileManager.new("public/wallets/GUEST_#{client_reference}#{soft_id}.json", trip_json.to_json).write!

    trip = {
      'name' => guide['name'],
      'description' => guide['description'],
      'start_date' => nil,
      'end_date' => nil,
      'language' => guide['language'],
      'updated_at' => guide['generated_at'],
      'type' => 'content',
      'image' => '',
      'bookings' => [
        {
          'username' => 'GUEST',
          'authentication_token' => "#{client_reference}#{soft_id}",
          'updated_at' => guide['generated_at']
        }
      ],
      "guides" => [
        guide
      ]
    }

    trips.push(trip)

    trip
  end
end
