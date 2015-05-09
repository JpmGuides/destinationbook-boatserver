require 'digest/sha1'
require 'fileutils'

class Synchronizer
  class FileManager
    attr_accessor :path, :data, :binary

    def initialize(destination, data = nil, binary = false)
      self.data = data
      self.path = path_from_destination(destination)
      self.binary = binary
    end

    # transform path to be an absolute path
    #
    # @param destination [String || Array] the path
    # @return [String] the absolute path
    def path_from_destination(destination)
      destination = File.join(destination) if destination.is_a?(Array)

      File.expand_path(destination)
    end

    # write data in file given in path
    #
    # @return [Synchronizer::FileManager] itself
    def write!
      return if data.nil?

      dir = File.dirname(path)
      FileUtils.mkdir_p(dir) unless Dir.exists?(dir)

      File.open(path, binary ? 'wb' : 'w') do |f|
        f.write data
      end
      set_mtime(Time.now.utc)

      self
    end

    # verify if path exists
    #
    # @return [Boolean] true for existence
    def exists?
      File.exists?(path)
    end

    # give the checksum of the file in path
    #
    # @return [String] SHA1 checksum
    def checksum
      Digest::SHA1.file(path).hexdigest
    end

    # check if checksum of file is different of data
    #
    # @return [Boolean] true if data is no differents from file
    def unmodified_data?
      return false unless File.exists?(path)

      Digest::SHA1.hexdigest(data) == checksum
    end

    # set the file date of modification
    #
    # @param time [Time] the time wich file modification should be setted
    # @return [Time] the modifcation time
    def set_mtime(time)
      atime = File.atime(path)

      File.utime(atime, time, path)
      time
    end

    # get the file modification time
    #
    # @return [Time] time of modification
    def updated_at
      File.mtime(path).utc
    end

    # get the file creation time
    #
    # @return [Time] time of creation
    def created_at
      File.birthtime(path).utc
    end
  end
end
