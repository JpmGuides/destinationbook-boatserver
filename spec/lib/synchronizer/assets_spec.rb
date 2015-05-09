require 'spec_helper.rb'

describe Synchronizer::Downloader do
  subject(:asset) { Synchronizer::Assets.new(json_string) }

  let(:json_string) { File.read('spec/fixtures/files/wallet.json') }

  it { should respond_to(:json) }

  context '#download' do
    before(:each) do
      allow(asset).to receive(:get_asset)
    end

    it 'download each asset' do
      expect(asset).to receive(:get_asset).exactly(3)

      asset.download
    end

    it 'should not raise error if no asset to download' do
      asset.json = ''

      expect {
        asset.download
      }.to_not raise_error
    end
  end

  context '#get_asset' do
    let(:url) { 'http://test.com/test/wallet.json?param1=test&param2=test' }

    before(:each) do
      allow(Synchronizer::Downloader).to receive(:get).and_return(true)
      allow(asset).to receive(:areplace_url)
      allow_any_instance_of(Synchronizer::FileManager).to receive(:write!)
    end

    it 'dowload file' do
      expect(Synchronizer::Downloader).to receive(:get).with(
        url,
        { 'param1' => 'test', 'param2' => 'test'}
      )

      asset.get_asset(url)
    end

    it 'writes downloaded file' do
      expect_any_instance_of(Synchronizer::FileManager).to receive(:write!)

      asset.get_asset(url)
    end
  end
end
