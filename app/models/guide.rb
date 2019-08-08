require 'zip'
require 'fileutils'

class GuideNotFound < StandardError; end

class Guide
  GUIDE_ZIP_PATH = 'public/guides/smartphone'
  GUIDE_WEB_PATH = 'public/guides/web'

  def self.all
    path = File.expand_path(GUIDE_ZIP_PATH)
    puts path
    guide_ids = Dir.entries(path).reject{|entry| entry == "." || entry == ".."}
    guide_ids.map {|id| Guide.new(id) }
  end

  def initialize(id)
    @id = id

    raise GuideNotFound unless File.exist?(zip_path)
  end

  def content
    File.read(File.join(web_path, 'guide.json'))
  end

  def updated_at
    File.mtime(zip_path)
  end

  def zip_path
    File.join(GUIDE_ZIP_PATH, @id, 'guide_tiled.zip')
  end

  def web_path
    File.join(GUIDE_WEB_PATH, @id)
  end

  def api_path
    File.join('guides', @id)
  end

  def to_json(arg = nil)
    "{
      \"id\": \"#{@id}\",
      \"path\": \"#{api_path}\",
      \"updated_at\": \"#{updated_at}\"
    }"
  end

  def unzip
    puts "unzip #{@id}"

    return if File.exist?(web_path) && (updated_at <= File.mtime(web_path))

    FileUtils.rm_rf(web_path) if File.exist?(web_path)
    FileUtils.mkdir_p(web_path)

    Zip::File.open(zip_path) do |zip_file|
      zip_file.each do |f|
        fpath = File.join(web_path, f.name)
        FileUtils.mkdir_p(File.dirname(fpath)) unless (File.exist?(File.dirname(fpath)))
        zip_file.extract(f, fpath) unless (File.exist?(fpath))
      end
    end

    FileUtils.touch(web_path)
  end
end
