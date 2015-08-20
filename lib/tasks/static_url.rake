require 'rake'
require 'optparse'
require 'uri'

namespace :static_url do |args|
  desc "change url in static file with ip given in parameter"
  task :change do

    puts File.dirname(__FILE__)
    # parse options
    options = {}
    ARGV[2..-1].each_slice(2) do |opt, value|
      if opt == '-u' || opt == '--url'
        options[:url] = value
      elsif opt == '-h' || opt == '--host'
        options[:host] = value
      end
    end

    if options[:url]
      replacement_url = options[:url]
    elsif options[:host]
      replacement_url = "http://#{options[:host]}.xip.io"
    else
      puts 'no replacement url given'
      exit 1
    end

    wallets_path = File.absolute_path('public/wallets')
    Dir.entries(wallets_path).each do |filname|
      path = File.join([wallets_path, filname])
      puts ("change in file #{path}")
      next if File.directory?(path)

      json = File.read(path)
      urls = URI.extract(json, ['http', 'https'])

      urls.each do |url|
        uri = URI.parse(url)
        json.gsub!(url, File.join([replacement_url, uri.path]))
      end

      File.open(path, 'w') do |file|
        file.write(json)
      end
    end

    path = 'public/trips.json'
    puts ("change in file #{path}")

    json = File.read(path)
    urls = URI.extract(json, ['http', 'https'])

    urls.each do |url|
      uri = URI.parse(url)
      json.gsub!(url, File.join([replacement_url, uri.path]))
    end

    File.open(path, 'w') do |file|
      file.write(json)
    end

    exit 0
  end
end
