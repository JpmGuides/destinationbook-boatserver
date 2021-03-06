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
    },
    'device' => {
      'uuid' => 'boatserver'
    }
  } }

  context '#base_url' do
    before(:each) do
      allow(subject).to receive(:config).and_return(config)
    end

    it 'should return the site base url from config' do
      expect(subject.base_url).to eql("http://test.com/")
    end
  end

  context '#get_trips' do
    before(:each) do
      allow(subject).to receive(:config).and_return(config)
    end

    it 'should download trip from specified url' do
      stub_request(:get, 'http://test.com/trips')
        .with(query: {authentication_token: config['api_key'], page: 0})
        .to_return(body: '{ "trips": [{"get": "json!"}]}', status: 200)
      stub_request(:get, 'http://test.com/trips')
        .with(query: {authentication_token: config['api_key'], page: 1})
        .to_return(body: '{ "trips": []}', status: 200)

      expect(subject.get_trips).to eql([{"get" => "json!"}])
      expect(
        a_request(:get, 'http://test.com/trips')
        .with(query: {authentication_token: config['api_key'], page: 0})
      ).to have_been_made
    end
  end

  context '#load_trips_json' do
    let(:json_trips) { JSON.load(File.open('spec/fixtures/files/trips.json').read)['trips'] }

    it 'should parse json and return and set trips' do
      allow(subject).to receive(:get_trips).and_return(json_trips)

      subject.load_trips_json

      expect(subject.trips).to be_a(Array)
      expect(subject.trips.count).to eql(2)

      trip = subject.trips.first

      expect(trip).to have_key('bookings')
      expect(trip['bookings'].count).to eql(2)
    end
  end

  context '#load_guides_json' do
    let(:json_trips) { JSON.load(File.open('spec/fixtures/files/trips.json').read)['trips'] }

    it 'should parse json and return and set trips' do
      subject.trips = json_trips

      expect(subject.trips).to be_a(Array)
      expect(subject.trips.count).to eql(2)

      subject.load_guides_json

      expect(subject.guides.count).to eql(3)
    end
  end

  context '#synchronize' do
    before(:each) do
      allow(subject).to receive(:load_trips_json).and_return('some json data')
      allow_any_instance_of(Synchronizer::FileManager).to receive(:write!).and_return(true)
    end

    it 'should call synchronizations processes' do
      allow_any_instance_of(Synchronizer::FileManager).to receive(:unmodified_data?).and_return(false)

      expect(subject).to receive(:synchronize_wallets)
      expect(subject).to receive(:synchronize_guides)

      subject.synchronize
    end
  end

  context '#synchronize_wallets' do
    let(:loaded_trips) { [
      { 'name' => 'trip one', 'bookings' => [{'booking' => 'one'}, {'booking' => 'two'}, ]},
      { 'name' => 'trip two', 'bookings' => [{'booking' => 'three'}, {'booking' => 'four'}, ]}
    ] }

    it 'should call "synchronize_wallet" for each booking' do
      allow(subject).to receive(:synchronize_wallet)
      subject.trips = loaded_trips

      expect(subject).to receive(:synchronize_wallet).exactly(4)
      subject.synchronize_wallets
    end

    it 'should not raise error if trips is empty' do
      allow(subject).to receive(:synchronize_wallet)
      subject.trips = []

      expect {
        subject.synchronize_wallets
      }.to_not raise_error
    end
  end

  context '#synchronize_guides' do
    let(:loaded_trips) { [
      { 'name' => 'trip one', 'guides' => [{'booking' => 'one'}, {'booking' => 'two'}, ]},
      { 'name' => 'trip two', 'guides' => [{'booking' => 'three'}, {'booking' => 'four'}, ]}
    ] }

    it 'should call "synchronize_guide" for each booking' do
      allow(subject).to receive(:synchronize_wallet)
      subject.trips = loaded_trips
      subject.load_guides_json

      expect(subject).to receive(:synchronize_guide).exactly(4)
      expect(subject).to receive(:genereate_trip_json).exactly(4)

      subject.synchronize_guides
    end

    it 'should not raise error if trips is empty' do
      allow(subject).to receive(:synchronize_guide)
      allow(subject).to receive(:genereate_trip_json)
      subject.trips = []
      subject.load_guides_json

      expect {
        subject.synchronize_guides
      }.to_not raise_error
    end
  end

  context '#synchronize_wallet' do
    let(:booking) { {"username"=>"TEST", "authentication_token"=>"TEST", "updated_at"=>"2015-05-05T17:16:17Z"} }
    let(:trip) { {"name"=>"Noël", "start_date"=>"2018-12-18", "end_date"=>"2018-12-28", "updated_at"=>"2014-12-18T08:48:35Z", "bookings"=>[booking]} }

    it 'should call get wallet if wallet needs to be synchronized' do
      allow(subject).to receive(:update?).and_return(true)
      allow(subject).to receive(:get_wallet)

      expect(subject).to receive(:get_wallet).exactly(1)
      subject.synchronize_wallet(booking, trip)
    end

    it 'should not call get wallet if wallet don\'t needs to be synchronized' do
      allow(subject).to receive(:update?).and_return(false)
      allow(subject).to receive(:get_wallet)

      expect(subject).to_not receive(:get_wallet)
      subject.synchronize_wallet(booking, trip)
    end
  end

  context '#synchronize_guide' do
    let(:guide) { {"id" => "1831.01",
                   "url" => "https://destinationbook-staging.s3.amazonaws.com/guides/smartphone/1831.01/guide_tiled.zip?AWSAccessKeyId=AKIAIQ4NKK5EC3TSOQEA&Signature=NIi6Kqzt8dvo97QVJPV3k0fJjJQ%3D&Expires=1431095065",
                   "generated_at" => "2015-05-08T08:00:57+00:00"}
                }

    it 'should call get wallet if wallet needs to be synchronized' do
      allow(subject).to receive(:update?).and_return(true)
      allow(subject).to receive(:get_guide)

      expect(subject).to receive(:get_guide).exactly(1)
      subject.synchronize_guide(guide)
    end

    it 'should not call get wallet if wallet don\'t needs to be synchronized' do
      allow(subject).to receive(:update?).and_return(false)
      allow(subject).to receive(:get_guide)

      expect(subject).to_not receive(:get_guide)
      subject.synchronize_guide(guide)
    end
  end

  context '#newer_time' do
    it 'should return newer time it is the first argument' do
      time_a = Time.now
      time_b = time_a - 3600

      expect(subject.newer_time(time_a, time_b)).to equal(time_a)
    end

    it 'should return newer time it is the second argument' do
      time_a = Time.now
      time_b = time_a + 3600

      expect(subject.newer_time(time_a, time_b)).to equal(time_b)
    end

    it 'should return time_b if time_a is nil' do
      time_a = nil
      time_b = Time.now

      expect(subject.newer_time(time_a, time_b)).to equal(time_b)
    end

    it 'should return time_a if time_b is nil' do
      time_a = Time.now
      time_b = nil

      expect(subject.newer_time(time_a, time_b)).to equal(time_a)
    end

    it 'should raise error if nor time_a or time_b is kind of Time' do
      time_a = nil
      time_b = nil

      expect{
        subject.newer_time(time_a, time_b)
      }.to raise_error('No time given to compare')
    end
  end

  context '#update?' do
    let(:file) { Synchronizer::FileManager.new('test') }

    it 'should return true if file doesn\'t exists' do
      allow(file).to receive(:exists?).and_return(false)

      expect(subject.update?(file, Time.now)).to be_truthy
    end

    it 'should return true if file exists and mtime < compare time' do
      allow(file).to receive(:exists?).and_return(true)
      allow(file).to receive(:updated_at).and_return(Time.now - 3600)

      expect(subject.update?(file, Time.now)).to be_truthy
    end

    it 'should return false if file exists and mtime > compare time' do
      allow(file).to receive(:exists?).and_return(true)
      allow(file).to receive(:updated_at).and_return(Time.now + 3600)

      expect(subject.update?(file, Time.now)).to be_falsy
    end
  end

  context '#get_wallet' do
    let(:file) { Synchronizer::FileManager.new('tmp/test_wallet.json') }
    let(:username) { 'AUSENAME' }
    let(:token) { 'ATOKEN' }

    before(:each) do
      allow(subject).to receive(:config).and_return(config)
      allow_any_instance_of(Synchronizer::FileManager).to receive(:write!).and_return(true)
    end

    it 'should download the booking from username and token' do
      stub_request(:get, "#{subject.base_url}#{config['uri']['wallet']}")
        .with(query: {'username' => username, 'authentication_token' => token, 'device[uuid]' => 'boatserver', 'version' => '2.0.0'})
        .to_return(body: 'get json!', status: 200)

      subject.get_wallet(file, username, token, Time.now)

      expect(
        a_request(:get, "#{subject.base_url}#{config['uri']['wallet']}")
        .with(query: {'username' => username, 'authentication_token' => token, 'device[uuid]' => 'boatserver', 'version' => '2.0.0'})
      ).to have_been_made
    end

    it 'should write file with response content' do
      stub_request(:get, "#{subject.base_url}#{config['uri']['wallet']}")
        .with(query: {'username' => username, 'authentication_token' => token, 'device[uuid]' => 'boatserver', 'version' => '2.0.0'})
        .to_return(body: 'get json!', status: 200)

      expect(file).to receive(:write!)
      subject.get_wallet(file, username, token, Time.now)
    end

    it 'should set file mtime with updated_at time' do
      stub_request(:get, "#{subject.base_url}#{config['uri']['wallet']}")
        .with(query: {'username' => username, 'authentication_token' => token, 'device[uuid]' => 'boatserver', 'version' => '2.0.0'})
        .to_return(body: 'get json!', status: 200)

      expect(file).to receive(:set_mtime)
      subject.get_wallet(file, username, token, Time.now)
    end
  end


  context '#get_guide' do
    let(:file) { Synchronizer::FileManager.new('tmp/test_guide.json') }
    let(:uri) { URI('http://test.com/test_guide.zip?some_param=value&other_param=value') }

    before(:each) do
      allow_any_instance_of(Synchronizer::FileManager).to receive(:write!).and_return(true)
      allow_any_instance_of(Synchronizer::FileManager).to receive(:set_mtime).and_return(true)
    end

    it 'download file from uri' do
      stub_request(:get, uri.to_s)
        .with(query: {'some_param' => 'value', 'other_param' => 'value'})
        .to_return(body: 'get json!', status: 200)

      subject.get_guide(file, uri, Time.now)

      expect(
        a_request(:get, uri.to_s)
          .with(query: {'some_param' => 'value', 'other_param' => 'value'})
      ).to have_been_made
    end

    it 'write file to FS' do
      stub_request(:get, uri.to_s)
        .with(query: {'some_param' => 'value', 'other_param' => 'value'})
        .to_return(body: 'get json!', status: 200)

      expect(file).to receive(:write!)

      subject.get_guide(file, uri, Time.now)
    end

    it 'should set file mtime with updated_at time' do
      stub_request(:get, uri.to_s)
        .with(query: {'some_param' => 'value', 'other_param' => 'value'})
        .to_return(body: 'get json!', status: 200)

      expect(file).to receive(:set_mtime)
      subject.get_guide(file, uri, Time.now)
    end
  end
end
