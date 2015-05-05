require 'synchronizer/downloader'

class Synchronizer
  attr_accessor :api_key

  def initialize(api_key)
    self.api_key = api_key
  end
end
