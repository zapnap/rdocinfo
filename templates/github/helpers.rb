$github = {}
$github[:project] = ENV['GH_PROJECT']
$github[:user] = ENV['GH_USER']
$github[:branch] = ENV['GH_BRANCH']
$github[:version] = ENV['GH_VERSION']
$github[:description] = ENV['GH_DESCRIPTION']

# This is just not cool
module YARD
  module Generators
    class FullDocGenerator < Base
      def generate_index
        if format == :html && serializer
          serializer.serialize 'index.html', render(:index)
          serializer.serialize '/files/index.html', render(:all_files)
          serializer.serialize '/namespaces/index.html', render(:all_namespaces)
          serializer.serialize '/methods/index.html', render(:all_methods)
        end
        true
      end
    end
  end    
end