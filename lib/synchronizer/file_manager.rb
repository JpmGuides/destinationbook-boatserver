require 'digest/sha1'

class Synchronizer
  class FileManager
    attr_accessor :path, :data

    def initialize(destination, data = nil)
      self.data = data
      self.path = path_from_destination(destination)
    end

    def path_from_destination(destination)
      destination = destination.join('/') if destination.is_a?(Array)

      File.expand_path(destination)
    end

    def write!
      return if data.nil?

      File.open(path, 'w') do |f|
        f.write data
      end
    end

    def exists?
      File.exists?(path)
    end

    def checksum
      Digest::SHA1.file(path).hexdigest
    end

    def unmodified_data?
      return false unless File.exists?(path)

      Digest::SHA1.hexdigest(data) == checksum
    end

    def set_mtime(time)
      atime = File.atime(path)

      File.utime(atime, time, path)
      time
    end

    def updated_at
      File.mtime(path).utc
    end

    def created_at
      File.birthtime(path).utc
    end
  end
end
