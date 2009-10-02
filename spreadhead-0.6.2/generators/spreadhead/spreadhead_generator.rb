require File.expand_path(File.dirname(__FILE__) + "/lib/insert_commands.rb")
require File.expand_path(File.dirname(__FILE__) + "/lib/rake_commands.rb")

class SpreadheadGenerator < Rails::Generator::Base

  def manifest
    record do |m|
      m.insert_into "app/controllers/application_controller.rb", 
        "include Spreadhead::Render"

      page_model = "app/models/page.rb"
      if File.exists?(page_model)
        m.insert_into page_model, "include Spreadhead::Page"
      else
        m.directory File.join("app", "models")
        m.file "page.rb", page_model
      end

      m.directory File.join("test", "factories")
      m.file "factories.rb", "test/factories/spreadhead.rb"      

      m.directory File.join("config", "initializers")
      m.file "initializer.rb", "config/initializers/spreadhead.rb"      

      m.migration_template "migrations/#{migration_name}.rb", 'db/migrate',
        :migration_file_name => "spreadhead_#{migration_name}"

      m.readme "README"
    end
  end

  private

  def migration_name
    if ActiveRecord::Base.connection.table_exists?(:pages)
      'update_pages'
    else
      'create_pages'
    end
  end

end
