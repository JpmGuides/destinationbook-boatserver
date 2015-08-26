require 'uri'
require 'socket'

class Synchronizer
  class Assets
    attr_accessor :json, :options

    # alias to avoid new declaration
    #
    # @return [String] the json width link to point to this server
    def self.download(json, options = {})
      new(json, options).download
    end

    # NEW
    #
    # @param json [String] the json in which assets url are to found and download
    def initialize(json, options = {})
      self.json = json
      self.options = options
    end

    # Extract url from json and get files
    #
    # @return [String] the json with modified urls
    def download
      URI.extract(json, ['http', 'https']).each do |url|
        get_asset(url)
      end

      json
    end

    # download a file and writes it
    #
    # @param url [String] the url where to download the file
    def get_asset(url)
      uri = URI.parse(url)

      unless File.exists?(File.join(['public', uri.path]))
        FileManager.new(['public', uri.path], Downloader.get(url, URI.decode_www_form(uri.query).to_h), true).write!
      end

      replace_url(url, uri.path)
    end

    def replace_url(url, path)
      replacement_url = File.join(["http://#{local_ip}.xip.io#{local_port}", path])

      json.gsub!(url, replacement_url)
    end

    # get ip address of server
    #
    #
    def local_ip
      Synchronizer.config['local_url']
    end

    def local_port
      if Synchronizer.config.has_key?('local_port') && Synchronizer.config['local_port'].to_i != 80
        ":#{Synchronizer.config['local_port']}"
      else
        ''
      end
    rescue
      ''
    end
  end
end
