require 'json'

task :check do
  print 'Checking wallets existance '

  unless File.exists?('public/trips.json')
    puts 'ERROR : missing file trips.json'
    return 1
  end

  config = YAML::load(File.open('config/settings.yaml'))
  config = config['synchronizer']

  path_to_verify = []
  url_to_verify = []
  wallets_path = File.absolute_path('public/wallets')
  trips = JSON.load(File.read('public/trips.json'))

  print ": #{trips['trips'].count} trips to verifiy.... "

  trips['trips'].each do |trip|
    filename = "#{trip['bookings'][0]['username']}_#{trip['bookings'][0]['authentication_token']}.json"
    wallet_path = File.join([wallets_path,  filename])
    path_to_verify << wallet_path

    unless File.exists?(wallet_path)
      puts "done \t=> FAIL"
      puts "ERROR : missing wallet file #{wallet_path}"
      return 1
    end
  end

  puts "done \t=> OK"

  print 'checking if assets esxists '
  print ": #{path_to_verify.count} wallets to verifiy... "

  path_to_verify.each do |wallet|
    next if File.directory?(wallet)
    json = File.read(wallet)
    URI.extract(json, ['http', 'https']).each do |url|
      uri = URI.parse(url)
      url_to_verify << url

      unless File.exists?(File.join(['public', uri.path]))
        puts "done \t=> FAIL"
        puts "ERROR : missing asset file #{File.join(['public', uri.path])}"
        return 1
      end
    end
  end

  puts "done \t=> OK"

  print 'checking assets url :'
  print " #{url_to_verify.count} to verify... "

  url_to_verify.each do |url|
    uri = URI.parse(url)

    unless uri.host.include?('xip.io')
      puts "done \t\t\t=> FAIL"
      puts "ERROR : some url don't use xip.io"
      return 1
    end

    unless uri.host.include?(config['local_url'])
      puts "WARNING : some url IPs don't match config : #{url}"
    end
  end

  puts "done \t\t\t=> OK"
end
