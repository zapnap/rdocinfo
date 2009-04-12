require "#{File.dirname(__FILE__)}/spec_helper"

describe 'Application' do
  include Rack::Test::Methods

  def app
    Sinatra::Application.new
  end

  it 'should show the default index page' do
    get '/'
    last_response.should be_ok
  end

  it 'should have more specs' do
    pending
  end
end
