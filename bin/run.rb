#!/usr/bin/env ruby

$LOAD_PATH.unshift("#{File.dirname(__FILE__)}/../lib")
require "#{File.dirname(__FILE__)}/../lib/rdoc_info"
require 'vegas'

Vegas::Runner.new(RdocInfo::Application, 'app')
