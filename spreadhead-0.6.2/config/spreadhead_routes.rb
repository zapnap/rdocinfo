ActionController::Routing::Routes.draw do |map|
  map.resources :pages, :controller => 'spreadhead/pages'
  map.connect '*url', :controller => 'spreadhead/pages', :action => 'show'
end
