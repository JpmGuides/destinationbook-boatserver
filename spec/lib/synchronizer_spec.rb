require 'spec_helper.rb'

describe Synchronizer do
  subject { Synchronizer.new }

  let(:config) { {
    'api_key' => 'my_api_key',
    'protocol' => 'http',
    'host' => 'test.com',
    'uri' => {
      'trips' => 'trips',
      'wallet' => 'wallet'
    }
  } }

  context '#get_trips' do
    before(:each) do
      allow(subject).to receive(:config).and_return(config)
    end

    it 'should download trip from specified url' do
      stub_request(:get, 'http://test.com/trips')
        .with(query: {api_key: config['api_key']})
        .to_return(body: 'get json!', status: 200)

      expect(subject.get_trips).to eql('get json!')
      expect(
        a_request(:get, 'http://test.com/trips')
        .with(query: {api_key: config['api_key']})
      ).to have_been_made
    end
  end

  context '#load_trips_json' do
    let(:json_trips) { File.open('spec/fixtures/files/trips.json').read }

    it 'should par json and return trips' do
      allow(subject).to receive(:get_trips).and_return(json_trips)
      trips = subject.load_trips_json

      expect(trips).to be_a(Array)
      expect(trips.count).to eql(2)

      trip = trips.first

      expect(trip).to have_key('bookings')
      expect(trip['bookings'].count).to eql(2)
    end

    it 'should return empty array if http response is invalid user' do
      allow(subject).to receive(:get_trips).and_return('{"error": "invalid user"}')

      expect {
        subject.load_trips_json
      }.to_not raise_error

      expect(subject.load_trips_json).to be_a(Array)
      expect(subject.load_trips_json).to be_empty
    end

    it 'should return empty array if http response is empty' do
      allow(subject).to receive(:get_trips).and_return('')

      expect {
        subject.load_trips_json
      }.to_not raise_error

      expect(subject.load_trips_json).to be_a(Array)
      expect(subject.load_trips_json).to be_empty
    end
  end

  context '#synchronize' do
    let(:loaded_trips) { [
      { 'name' => 'trip one', 'bookings' => [{'booking' => 'one'}, {'booking' => 'two'}, ]},
      { 'name' => 'trip two', 'bookings' => [{'booking' => 'three'}, {'booking' => 'four'}, ]}
    ] }

    it 'should call "synchronize_wallet" for each booking' do
      allow(subject).to receive(:load_trips_json).and_return(loaded_trips)
      allow(subject).to receive(:synchronize_wallet)
      subject.trips = loaded_trips

      expect(subject).to receive(:synchronize_wallet).exactly(4)
      subject.synchronize
    end
  end

  it 'should not raise error if trips is empty' do
    allow(subject).to receive(:load_trips_json).and_return([])
    allow(subject).to receive(:synchronize_wallet)
    subject.trips = []

    expect {
      subject.synchronize
    }.to_not raise_error
  end
end
