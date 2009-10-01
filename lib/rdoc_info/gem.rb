module RdocInfo
  class Gem
    include DataMapper::Resource

    is_paginated

    property :id,          Serial
    property :name,        String, :index => true
    property :url,         String, :length => 255
    property :status,      String
    property :error_log,   Text
    property :description, String, :length => 255
    property :version,     String
    property :created_at,  DateTime
    property :updated_at,  DateTime

    validates_present :name, :url
    validates_with_method :name, :method => :reject_non_ascii_name_chars
    validates_with_method :name, :method => :check_gem_and_update_version
    # validates_is_unique :url
    validates_is_unique :version

    attr_reader :skip_regeneration

    # generate updated gem docs
    after :save do
      self.doc.generate unless skip_regeneration
    end

    # documentation builder for this gem
    def doc
      DocBuilder.new(self)
    end

    # Gemcutter URL for this gem
    def gem_url
      "http://s3.amazonaws.com/gemcutter_production/gems/#{name}-#{version}.gem"
    end

    # public URL where documentation for this gem is viewable
    def doc_url(full = true)
      path = "/gems/#{name}"
      path += "/versions/#{version}" if full
      path
    end

    def version_url
      version.nil? ? url : "#{url}/versions/#{version}"
    end

    # update the status of this gem
    # (initially nil, can be set to created or failed)
    def update_status!(new_status, log_data = '')
      @skip_regeneration = true
      self.status = new_status
      self.error_log = log_data
      save
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

    def check_gem_and_update_version
      return true if name.blank?
      remote = RestClient.get(url + '.json') 
      latest = JSON.parse(remote)
      self.version = latest['version'] if self.version.blank?
      true
    rescue RestClient::RequestFailed, RestClient::ResourceNotFound
      [false, "Name must refer to a valid gem hosted at gemcutter.org"]
    end

    # Gem.search(**kwargs) -- When given
    #   :fields => [...] and
    #   :terms => [...]
    # returns all gems with all terms found in any of the supplied
    # fields.  Search is performed using LIKE '%term%'
    #
    # When also given
    #   :count => Fixnum (defaults to RdocInfo.config[:per_page]) and/or
    #   :page => Fixnum (default 1)
    # returns an array of the total number of pages and the gems
    # as queried above sliced [page*count-count, page*count]
    # 
    def self.search(kwargs = {})
      raise ArgumentError unless kwargs[:fields] && kwargs[:terms]

      fields  = [kwargs[:fields]].flatten
      terms   = kwargs[:terms].to_a
      page    = kwargs[:page].to_i
      count   = kwargs[:count].to_i

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

        pages, gems = self.paginated(:order => fields,
                                     :fields => fields,
                                     :conditions => predicate,
                                     :unique => true,
                                     :per_page => count,
                                     :page => page)
        # TODO: temporary fix for dm-aggregates bug in 0.9.11
        pages = (self.all(:fields => fields,
                          :conditions => predicate,
                          :unique => true).length.to_f / RdocInfo.config[:per_page].to_f).ceil
        [pages, gems]
      else
        self.all(:order => fields,
                 :fields => fields,
                 :conditions => predicate,
                 :unique => true)
      end
    end
  end
end
