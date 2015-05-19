require 'spec_helper.rb'

describe "Boat serve" do
  it "should respond from /trips" do
    get '/trips'
    expect(last_response).to be_ok
  end
end
