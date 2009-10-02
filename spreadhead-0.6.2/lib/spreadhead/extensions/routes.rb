if defined?(ActionController::Routing::RouteSet)
  class ActionController::Routing::RouteSet
    def load_routes_with_spreadhead!
      lib_path = File.dirname(__FILE__)
      spreadhead_routes = File.join(lib_path, *%w[.. .. .. config spreadhead_routes.rb])
      unless configuration_files.include?(spreadhead_routes)
        add_configuration_file(spreadhead_routes)
      end
      load_routes_without_spreadhead!
    end

    alias_method_chain :load_routes!, :spreadhead
  end
end