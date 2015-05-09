require 'uri'
require 'socket'

class Synchronizer
  class Assets
    attr_accessor :json

    # alias to avoid new declaration
    #
    # @return [String] the json width link to point to this server
    def self.download(json)
      new(json).download
    end

    # NEW
    #
    # @param json [String] the json in which assets url are to found and download
    def initialize(json)
      self.json = json
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

      FileManager.new(['public', uri.path], Downloader.get(url, URI.decode_www_form(uri.query).to_h), true).write!

      replace_url(url, uri.path)
    end

    def replace_url(url, path)
      replacement_url = File.join(["http://#{local_ip}.xip.io", path])

      json.gsub!(url, replacement_url)
    end

    # get ip address of server
    #
    #
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
