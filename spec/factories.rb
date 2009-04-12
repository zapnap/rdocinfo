require 'factory_girl'

Factory.define :project do |f|
  f.name       'simplepay'
  f.owner      'zapnap'
  f.url        'http://github.com/zapnap/simplepay'
  f.created_at Time.now
  f.updated_at Time.now
end
