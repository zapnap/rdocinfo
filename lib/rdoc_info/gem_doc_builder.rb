module RdocInfo
  class GemDocBuilder
    attr_reader :gem, :output

    def initialize(gem)
      @gem = gem
    end

    # Generate RDocs for the gem
    def generate(asynch = true)
      FileUtils.rm_rf(rdoc_dir) if File.exists?(rdoc_dir) # clean first
      (!asynch || (Sinatra::Base.environment == :test)) ? run_yardoc : run_yardoc_asynch
    end

    # Local tmp directory used for gem unpacking
    def fetch_dir
      "#{RdocInfo.config[:tmp_dir]}"
    end

    def unpack_dir
      "#{RdocInfo.config[:tmp_dir]}/#{@gem.name}-#{@gem.version}"
    end
    
    # Local directory where rdocs will be generated
    def rdoc_dir(template = :default)
      "#{RdocInfo.config[:rdoc_dir]}/#{template}/#{@gem.name}/versions/#{@gem.version}"
    end
    
    def rdoc_url
      "#{RdocInfo.config[:rdoc_url]}/#{@gem.name}/versions/#{@gem.version}"
    end

    # Does generated documentation exist?
    def exists?
      File.exists?("#{rdoc_dir}/index.html")
    end

    # Generate RDocs for the specified gem
    def self.generate(gem)
      self.new(gem).generate
    end

    private
     
    def run_yardoc
      fetch_and_unpack_gem

      command = yardoc_command
      @output  = `#{command} 2>&1`

      logger.info command
      logger.info @output

      check_status
      clean_gem
    end
    
    def yardoc_command
      command = []
      command << "cd" << unpack_dir << ";"
      command << "yardoc" << "-q"
      command << "-o" << rdoc_dir
      command << "-r" << readme_file
      command << included_files
      command.join(" ")
    end

    def run_yardoc_asynch
      ::Spork.spork(:logger => logger) { run_yardoc }
    end

    def logger
      @logger ||= Logger.new(RdocInfo.config[:task_log])
    end
    
    def included_files
      if File.exists?(File.join(unpack_dir, '.document'))
        files = File.read(File.join(unpack_dir, '.document'))
        "'#{files.split(/$\n?/).join('\' \'')}'"
      else
        ''
      end
    end

    def readme_file
      @readme_file ||= generate_readme_file
    end

    def generate_readme_file
      unless file = Dir[File.join(unpack_dir, 'README*')].last
        File.open(File.join(unpack_dir, 'README'), 'w') {}
        file = 'README'
      end
      file = File.basename(file)
      file
    end

    def fetch_and_unpack_gem
      Dir.chdir(fetch_dir)
      `gem fetch #{@gem.name} -v #{@gem.version} --source http://gemcutter.org`
      `gem unpack #{@gem.name}-#{@gem.version}`
    end

    def clean_gem
      FileUtils.rm_rf(unpack_dir + ".gem")
      FileUtils.rm_rf(unpack_dir)
    end

    def check_status
      status = exists? ? 'created' : 'failed'
      @gem.update_status!(status, @output)
    end
  end
end
