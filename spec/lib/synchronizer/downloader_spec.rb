require 'spec_helper.rb'

describe Synchronizer::Downloader do
  subject {Synchronizer::Downloader.new('http://test.com')}

  context '#download' do
    it 'should call the get http method if verb is :get' do
      allow(subject).to receive(:get_http_content).and_return('get body')
      subject.verb = :get

      expect(subject).to receive(:get_http_content)
      expect(subject.download).to eql('get body')
    end

    it 'should call the get http method if verb is :get' do
      allow(subject).to receive(:post_http_content).and_return('post body')
      subject.verb = :post

      expect(subject).to receive(:post_http_content)
      expect(subject.download).to eql('post body')
    end

    it 'should return nil if verb is not supported' do
      subject.verb = :unexisting

      expect(subject.download).to be(nil)
    end
  end

  context '#get_http_content' do
    it 'should excute request with params' do
      params = {test: 'value', value: 'test'}
      subject.params = params
      stub_request(:get, 'http://test.com').with(query: params).to_return(body: 'get json!', status: 200)

      expect(subject.get_http_content).to eql('get json!')

      expect(a_request(:get, 'http://test.com').with(query: params)).to have_been_made
    end

    it 'should excute request without params' do
      params = {}
      subject.params = params
      stub_request(:get, 'http://test.com').with(query: params).to_return(body: 'get json!', status: 200)

      expect(subject.get_http_content).to eql('get json!')

      expect(a_request(:get, 'http://test.com').with(query: params)).to have_been_made
    end

    it 'should raise error if unsucessfull response' do
      params = {}
      subject.params = params
      stub_request(:get, 'http://test.com').with(query: params).to_return(body: 'get json!', status: 401)


      expect {
        subject.get_http_content
      }.to raise_error(Synchronizer::Downloader::HTTPError)

      expect(a_request(:get, 'http://test.com').with(query: params)).to have_been_made
    end
  end

  context '#post_http_content' do
    it 'should excute request with params' do
      params = {test: 'value', value: 'test'}
      subject.params = params
      stub_request(:post, 'http://test.com').with(body: params).to_return(body: 'get json!', status: 200)

      expect(subject.post_http_content).to eql('get json!')

      expect(a_request(:post, 'http://test.com').with(body: params)).to have_been_made
    end

    it 'should excute request without params' do
      params = {}
      subject.params = params
      stub_request(:post, 'http://test.com').with(body: params).to_return(body: 'get json!', status: 200)

      expect(subject.post_http_content).to eql('get json!')

      expect(a_request(:post, 'http://test.com').with(body: params)).to have_been_made
    end

    it 'raise error if unsuccessfull response' do
      params = {}
      subject.params = params
      stub_request(:post, 'http://test.com').with(body: params).to_return(body: 'get json!', status: 404)

      expect {
        subject.post_http_content
      }.to raise_error(Synchronizer::Downloader::HTTPError)

      expect(a_request(:post, 'http://test.com').with(body: params)).to have_been_made
    end
  end

  context '#uri' do
    it 'should return an URI object' do
      expect(subject.uri).to be_a(URI)
    end
  end
end
