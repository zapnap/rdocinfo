$LOAD_PATH.unshift("#{File.dirname(__FILE__)}/lib")
require "#{File.dirname(__FILE__)}/lib/rdoc_info"

RdocInfo::Application.set :run, false
RdocInfo::Application.set :environment, :production

FileUtils.mkdir_p('log') unless File.exists?('log')
log = File.new("log/sinatra.log", "a")
$stdout.reopen(log)
$stderr.reopen(log)

run RdocInfo::Application
