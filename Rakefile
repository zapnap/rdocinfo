require 'spec/rake/spectask'

task :default => :test
task :test => :spec

if !defined?(Spec)
  puts "spec targets require RSpec"
else
  desc "Run all examples"
  Spec::Rake::SpecTask.new('spec') do |t|
    t.spec_files = FileList['spec/**/*.rb']
    t.spec_opts = ['-cfs']
  end
end

namespace :db do
  desc 'Auto-migrate the database (destroys data)'
  task :migrate => :environment do
    DataMapper.auto_migrate!
  end

  desc 'Auto-upgrade the database (preserves data)'
  task :upgrade => :environment do
    DataMapper.auto_upgrade!
  end
end

namespace :rdoc do
  desc 'Regenerate all projects'
  task :regenerate => :environment do
    Project.all.each do |project|
      project.doc.generate(false)
    end
  end
end

namespace :gems do
  desc 'Install required gems'
  task :install do
    required_gems = %w{ yard dm-core dm-validations dm-aggregates dm-is-paginated 
                        merb-pagination sinatra haml rest-client json rack-test schacon-git
                        mocha rspec rspec_hpricot_matchers thoughtbot-factory_girl vegas }
    required_gems.each { |required_gem| system "sudo gem install #{required_gem}" }
  end
end

desc 'Resets the database and all project docs'
task :clean => :environment do
  Project.all.destroy!
  FileUtils.rm_rf "#{SiteConfig.tmp_dir}/*"
  FileUtils.rm_rf "#{SiteConfig.rdoc_dir}/*"
end

task :environment do
  require "#{File.expand_path(File.dirname(__FILE__))}/lib/rdoc_info"
end
