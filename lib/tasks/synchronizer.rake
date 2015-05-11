task :synchronize do
  puts 'synchronizing wallets...'
  Synchronizer.new.synchronize
end

task :post_connections do
  puts 'posting connections'
  Synchronizer.new.post_connections
end
