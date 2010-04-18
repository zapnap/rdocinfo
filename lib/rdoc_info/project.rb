module RdocInfo
  class Project
    include DataMapper::Resource

    is_paginated

    property :id,          Serial
    property :name,        String, :index => true
    property :owner,       String, :index => true
    property :url,         String, :length => 255
    property :status,      String
    property :error_log,   Text
    property :description, String, :length => 255
    property :commit_hash, String
    property :created_at,  DateTime
    property :updated_at,  DateTime

    validates_present :name, :owner, :url
    validates_with_method :owner, :method => :reject_non_ascii_owner_chars
    validates_with_method :name, :method => :reject_non_ascii_name_chars
    validates_with_method :name, :method => :check_remote_and_update_hash
    # validates_is_unique :url
    validates_is_unique :commit_hash

    attr_reader :skip_regeneration

    # generate updated project docs
    after :save do
      self.doc.generate unless skip_regeneration
    end

    # destroy generated docs after removal
    after :destroy do
      self.doc.destroy
    end

    # documentation builder for this project
    def doc
      DocBuilder.new(self)
    end

    # GitHub clone URL for this project
    def clone_url
      "git://github.com/#{owner}/#{name}.git"
    end

    # URL for caliper metrics
    def caliper_url
      "http://devver.net/caliper/project?repo=#{CGI.escape(clone_url)}"
    end

    # public URL where documentation for this project is viewable
    def doc_url(full = true)
      path = "/projects/#{owner}/#{name}"
      path += "/blob/#{commit_hash}" if full
      path
    end

    # truncate commit hash for display
    def truncated_hash
      (commit_hash || '').slice(0, 8) + '...'
    end

    def commit_url
      commit_hash.nil? ? url : "#{url}/commit/#{commit_hash}"
    end

    # update the status of this project
    # (initially nil, can be set to created or failed)
    def self.update_status(id, new_status, log_data = '')
      @skip_regeneration = true
      Project.get(id).update!(:status => new_status, :error_log => log_data)
    end

    # returns unique projects
    def self.unique(options = {})
      options[:fields] = [:owner, :name]
      options[:status] = 'created'
      options[:unique] = true

      Project.all(options)
    end

    # returns unique projects, paginated
    # (a hack to get around an annoying sql count bug in dm-aggregates)
    #
    # ex: Project.paginated_unique(:page => 1, :per_page => 4)
    #     => [3, [<RdocInfo::Project>, ...]]
    def self.paginated_unique(options = {})
      options[:fields] = [:owner, :name]
      options[:status] = 'created'
      options[:unique] = true

      count_options = options.dup
      count_options.delete_if { |k,v| (k == :per_page || k == :page) }

      count = (Project.all(count_options).length.to_f / options[:per_page].to_f).ceil
      records = Project.paginated(options).last

      [count, records]
    end

    private

    def reject_non_ascii_owner_chars
      return [false, "Owner contains disallowed characters"] if owner =~ /[^0-9A-Za-z\-\_]/
      true
    end

    def reject_non_ascii_name_chars
      return [false, "Name contains disallowed characters"] if name =~ /[^0-9A-Za-z\-\_]/
      true
    end

    def check_remote_and_update_hash
      return true if owner.blank? || name.blank?
      remote = RestClient.get("http://github.com/api/v1/json/#{owner}/#{name}/commits/master").body
      commits = JSON.parse(remote)
      commit = commits['commits'].first['id']
      self.commit_hash = commit if self.commit_hash.blank?
      true
    rescue RestClient::RequestFailed, RestClient::ResourceNotFound
      [false, "Name must refer to a valid GitHub repository"]
    end

    # Projects.search(**kwargs) -- When given
    #   :fields => [...] and
    #   :terms => [...]
    # returns all projects with all terms found in any of the supplied
    # fields.  Search is performed using LIKE '%term%'
    #
    # When also given
    #   :count => Fixnum (defaults to RdocInfo.config[:per_page]) and/or
    #   :page => Fixnum (default 1)
    # returns an array of the total number of pages and the projects
    # as queried above sliced [page*count-count, page*count]
    # 
    def self.search(kwargs = {})
      raise ArgumentError unless kwargs[:fields] && kwargs[:terms]

      fields = [kwargs[:fields]].flatten
      terms  = kwargs[:terms].to_a
      page   = kwargs[:page].to_i
      count  = kwargs[:count].to_i

      # construct the query predicate to pass to dm
      predicate = ['']
      terms.each do |term|
        predicate[0] += (predicate[0].empty? ? '(' : ') AND (') + 
                        fields.map {|f| "#{f.to_s} LIKE ?"}.join(' OR ')
        predicate += "%#{term}%".to_a * fields.size 
      end
      predicate[0] += ')' unless predicate[0].empty?

      if page > 0 || count > 0
        page = 1 if page == 0
        count = RdocInfo.config[:per_page] if count == 0

        pages, projects = self.paginated(:order => fields,
                                         :fields => fields,
                                         :conditions => predicate,
                                         :unique => true,
                                         :per_page => count,
                                         :page => page)
        # TODO: temporary fix for dm-aggregates bug in 0.9.11
        pages = (self.all(:fields => fields,
                          :conditions => predicate,
                          :unique => true).length.to_f / RdocInfo.config[:per_page].to_f).ceil
        [pages, projects]
      else
        self.all(:order => fields,
                 :fields => fields,
                 :conditions => predicate,
                 :unique => true)
      end
    end
  end
end
