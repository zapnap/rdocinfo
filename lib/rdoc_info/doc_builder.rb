module RdocInfo
  class DocBuilder
    attr_reader :project, :output

    def initialize(project)
      @project = project
    end

    # Generate RDocs for the project
    def generate(asynch = true)
      FileUtils.rm_rf(rdoc_dir) if File.exists?(rdoc_dir) # clean first
      (!asynch || (Sinatra::Base.environment == :test)) ? run_yardoc : run_yardoc_asynch
    end

    # Local tmp directory used for project cloning
    def clone_dir
      "#{RdocInfo.config[:tmp_dir]}/#{@project.owner}/#{@project.name}/blob/#{@project.commit_hash}"
    end
    
    # Local directory where rdocs will be generated
    def rdoc_dir(template = :default)
      "#{RdocInfo.config[:rdoc_dir]}/#{template}/#{@project.owner}/#{@project.name}/blob/#{@project.commit_hash}"
    end
    
    def rdoc_url
      "#{RdocInfo.config[:rdoc_url]}/#{@project.owner}/#{@project.name}/blob/#{@project.commit_hash}"
    end

    # Does generated documentation exist?
    def exists?
      File.exists?("#{rdoc_dir}/index.html")
    end

    # Generate RDocs for the specified project
    def self.generate(project)
      self.new(project).generate
    end

    private
     
    def run_yardoc
      clone_repo

      command = yardoc_command
      @output  = `#{command}`

      logger.info command
      logger.info @output

      check_status
      clean_repo
    end
    
    def yardoc_command
      command = []
      command << "cd" << clone_dir << ";"
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
      if File.exists?(File.join(clone_dir, '.document'))
        files = File.read(File.join(clone_dir, '.document'))
        "'#{files.split(/$\n?/).join('\' \'')}'"
      else
        ''
      end
    end

    def readme_file
      @readme_file ||= generate_readme_file
    end

    def generate_readme_file
      unless file = Dir[File.join(clone_dir, 'README*')].last
        File.open(File.join(clone_dir, 'README'), 'w') {}
        file = 'README'
      end
      file = File.basename(file)
      file
    end

    def git
      unless @git
        @git = Git.clone(@project.clone_url, clone_dir, { :log => logger })
        @git.checkout(@project.commit_hash, :new_branch => 'documentation') if @project.commit_hash
      end
      @git
    end

    def clone_repo
      git
    end

    def clean_repo
      FileUtils.rm_rf(clone_dir)
    end

    def check_status
      status = exists? ? 'created' : 'failed'
      @project.update_status!(status)
    end
  end
end
