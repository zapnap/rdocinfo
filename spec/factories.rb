require 'factory_girl'

Factory.define :project do |f|
  f.name        'simplepay'
  f.owner       'zapnap'
  f.url         'http://github.com/zapnap/simplepay'
  f.commit_hash '0f115cd0b8608f677b676b861d3370ef2991eb5f'
  f.created_at  Time.now
  f.updated_at  Time.now
end
