module Spreadhead
  module Page

    # Hook for all Spreadhead::Page modules.
    #
    # If you need to override parts of Spreadhead::Page,
    # extend and include à la carte.
    #
    # @example
    #   extend ClassMethods
    #   include InstanceMethods
    #   include AttrAccessor
    #   include Callbacks
    #
    # @see ClassMethods
    # @see InstanceMethods
    # @see Validations
    # @see Scopes
    # @see Callbacks
    def self.included(model)
      model.extend(ClassMethods)
      model.send(:include, InstanceMethods)
      model.send(:include, Validations)
      model.send(:include, Scopes)
      model.send(:include, Callbacks)
    end

    module Validations
      # Hook for validations.
      #
      # :title must be present and unique
      # :text must be present
      # :url must be unique
      def self.included(model)
        model.class_eval do
          validates_presence_of :text
          validates_presence_of :title
          validates_uniqueness_of :title
          validates_uniqueness_of :url  
          validates_presence_of :url  
        end
      end
    end

    module Scopes
      # Hook for scopes.
      #
      # :published should have its own scope
      def self.included(model)
        model.class_eval do
          named_scope :published, :conditions => ['published = ?', true]
        end
      end
    end

    module Callbacks
      # Hook for callbacks.
      #
      # :title should act like a url.
      def self.included(model)
        model.class_eval do
          acts_as_url :title, :sync_url => true, :only_when_blank => true
        end
      end
    end

    module InstanceMethods
    end  

    module ClassMethods
      def to_fixtures(path=nil)
        path ||= File.expand_path("db/data/#{table_name}.yml", RAILS_ROOT)
        path = File.join(path, "#{table_name}.yml") if File.directory?(path)
        file = File.open(path, "w")
        file.puts(self.find(:all).inject({}) { |hash, record| 
          hash.merge("\"#{record.title}\"" => record.attributes) 
        }.to_yaml(:SortKeys => true))
        file.close
      end
    end
  end
end
