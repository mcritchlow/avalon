require "rails_helper"

RSpec.describe TimelinesController, type: :routing do
  describe "routing" do

    it "routes to #index" do
      expect(:get => "/timelines").to route_to("timelines#index")
    end

    it "routes to #new" do
      expect(:get => "/timelines/new").to route_to("timelines#new")
    end

    it "routes to #show" do
      expect(:get => "/timelines/1").to route_to("timelines#show", :id => "1")
    end

    it "routes to #edit" do
      expect(:get => "/timelines/1/edit").to route_to("timelines#edit", :id => "1")
    end

    it "routes to #create" do
      expect(:post => "/timelines").to route_to("timelines#create")
    end

    it "routes to #update via PUT" do
      expect(:put => "/timelines/1").to route_to("timelines#update", :id => "1")
    end

    it "routes to #update via PATCH" do
      expect(:patch => "/timelines/1").to route_to("timelines#update", :id => "1")
    end

    it "routes to #destroy" do
      expect(:delete => "/timelines/1").to route_to("timelines#destroy", :id => "1")
    end

    it "routes to #regenerate_access_token" do
      expect(:patch => "/timelines/1/regenerate_access_token").to route_to("timelines#regenerate_access_token", :id => "1")
    end

    it "routes to #duplicate" do
      expect(:post => "/timelines/duplicate").to route_to("timelines#duplicate")
    end

    it "routes to #paged_index" do
      expect(:post => "/timelines/paged_index").to route_to("timelines#paged_index")
    end

    xit "routes to #import_variations_timeline" do
      Settings.variations = 'enabled'
      expect(:post => "/timelines/import_variations_timeline").to route_to("timelines#import_variations_timeline")
    end

  end
end
