require "#{File.dirname(__FILE__)}/spec_helper"

describe 'Project' do
  before(:each) do
    @project = Project.new(valid_attributes)
  end

  it 'should be valid' do
    @project.should be_valid
  end

  describe 'validations' do
    it 'should require a name' do
      @project.name = nil
      @project.should_not be_valid
      @project.errors[:name].should include("Name must not be blank")
    end

    it 'should require an owner' do
      @project.owner = nil
      @project.should_not be_valid
      @project.errors[:owner].should include("Owner must not be blank")
    end

    it 'should require a url' do
      @project.url = nil
      @project.should_not be_valid
      @project.errors[:url].should include("Url must not be blank")
    end

    it 'should require a unique url' do
      @project.save
      @project = Project.new(valid_attributes)
      @project.should_not be_valid
      @project.errors[:url].should include("Url is already taken")
    end
  end

  private

  def valid_attributes
    { :name  => 'simplepay',
      :owner => 'zapnap',
      :url   => 'http://github.com/zapnap/simplepay' }
  end
end
