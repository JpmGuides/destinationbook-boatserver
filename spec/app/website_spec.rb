require 'spec_helper.rb'

describe "Boat serve" do
  it "should respond from /" do
    get '/'
    expect(last_response).to be_ok
  end
end
