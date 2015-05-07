require 'spec_helper.rb'

describe Synchronizer::FileManager do
  subject(:file) {  Synchronizer::FileManager.new(relative_path, 'data') }

  before(:each) do
    system 'rm -rf spec/tmp'
  end

  let(:relative_path) { 'spec/tmp/test/test.file' }
  let(:path_array) { ['spec', 'tmp', 'test', 'test.file'] }

  it { should respond_to(:path) }
  it { should respond_to(:data) }

  context '#path_from_destination' do
    it 'give absolute path from string' do
      expect(
        file.path_from_destination(relative_path)
      ).to eql(File.expand_path(relative_path))
    end

    it 'give absolute path from array string' do
      expect(
        file.path_from_destination(path_array)
      ).to eql(File.expand_path(relative_path))
    end
  end

  context '#write!' do
    it 'creates dir if not exists' do
      dirname = File.dirname(File.expand_path(relative_path))
      file.data = 'test'

      expect(File.exists?(dirname)).to be_falsy

      file.write!

      expect(File.exists?(dirname)).to be_truthy
    end

    it 'creates file if not exists' do
      file.data = 'test'

      expect(File.exists?(relative_path)).to be_falsy

      file.write!

      expect(File.exists?(relative_path)).to be_truthy
    end

    it 'return the size of size created' do
      file.data = 'test'
      expect(file.write!).to be_a(Integer)
    end
  end

  context '#exists' do
    it 'check existence' do
      expect(File).to receive(:exists?).with(file.path)

      file.exists?
    end
  end

  context '#checksum' do
    it 'should give the ckecksum of a path' do
      file.data = 'test'
      file.write!

      expect(file.checksum).to be_a(String)
    end

    it 'should raise error if file dosen\'t exists' do
      expect{
        file.checksum
      }.to raise_error(Errno::ENOENT)
    end
  end

  context '#unmodified_data?' do
    it 'return true if file exists and content and data checksum are the same' do
      data = 'test data'
      file.data = data

      allow(file).to receive(:checksum).and_return(Digest::SHA1.hexdigest(data))
      allow(File).to receive(:exists?).and_return(true)

      expect(file.unmodified_data?).to be_truthy
    end

    it 'return fasle if file exists and content and data checksum are diffrent' do
      data = 'test data'
      file.data = data

      allow(file).to receive(:checksum).and_return(Digest::SHA1.hexdigest(data + '1'))
      allow(File).to receive(:exists?).and_return(true)

      expect(file.unmodified_data?).to be_falsy
    end

    it 'return flase if file does not exsists' do
      allow(File).to receive(:exists?).and_return(false)

      expect(file.unmodified_data?).to be_falsy
    end
  end

  context '#set_mtime' do
    it 'should set time modification of the file in path' do
      time = Time.now - 2700
      file.data = 'test test test'
      file.write!

      file.set_mtime(time)
      expect(File.mtime(file.path).to_i).to eql(time.to_i)
    end
  end

  context '#updated_at' do
    it 'return modification time of file' do
      allow(File).to receive(:mtime).and_return(Time.now)
      expect(File).to receive(:mtime).with(file.path)

      file.updated_at
    end
  end

  context '#created_at' do
    it 'return the file creation time' do
      allow(File).to receive(:birthtime).and_return(Time.now)
      expect(File).to receive(:birthtime).with(file.path)

      file.created_at
    end
  end
end
