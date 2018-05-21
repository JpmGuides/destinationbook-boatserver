require 'yard'
require 'yard/sinatra'

namespace :api_doc do
  desc "create api doc"

  YARD::Rake::YardocTask.new do |t|
    t.files    = ['app/webiste.rb']   # optional
    t.options  = ['--title API Documentation']
    t.verifier = YARD::Verifier.new "'@api.text == \"public\"'"
  end
end
