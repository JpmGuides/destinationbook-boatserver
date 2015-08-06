require 'net/http'
require 'uri'

class Synchronizer
  class Downloader
    attr_accessor :url, :params, :verb

    class HTTPError < StandardError; end

    #
    # CLASS METHODS
    #

    # Get file over http
    #
    # @param url [String] the url where to download
    # @param params [Hash] hash of parameters
    # @return [String] the body of the response
    def self.get(url, params = {})
      puts(url)
      self.new(url, params, :get).download
    end

    # Post file over http
    #
    # @param url [String] the url where to download
    # @param params [Hash] hash of parameters
    # @return [String] the body of the response
    def self.post(url, params = {})
      self.new(url, params, :post).download
    end

    #
    # INSTANCE METHODS
    #

    # NEW
    #
    # @param url [String] the url where to download
    # @param params [Hash] hash of parameters
    # @param verb [Symbol] verb of the request
    # @return [Downloader] downloder object
    def initialize(url, params= {}, verb = :get)
      self.url    = url
      self.params = params
      self.verb   = verb
    end

    # download the file using the right verb
    #
    # @return [String] the body of the executed request
    def download
      if verb == :get
        body = get_http_content
      elsif verb == :post
        body = post_http_content
      end

      body
    end

    # download the file via GET
    #
    # @return [String] the body of the executed request
    def get_http_content
      uri.query = URI.encode_www_form(params)
      res = Net::HTTP.get_response(uri)

      raise HTTPError.new("invalid #{res.code} response") unless res.is_a?(Net::HTTPSuccess)

      puts res.code
      res.body
    end

    # download the file via GET
    #
    # @return [String] the body of the executed request
    def post_http_content
      res = Net::HTTP.post_form(uri, params)

      raise HTTPError.new("invalid #{res.code} response") unless res.is_a?(Net::HTTPSuccess)

      res.body
    end

    # uri object from the url
    #
    # @return [Uri]
    def uri
      @uri ||= URI(url)
    end
  end
end
