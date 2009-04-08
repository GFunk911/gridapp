class NewTable
  attr_accessor :table, :app
  include FromHash
end

class AppController < ApplicationController
  def show
    @plumbing = !!params[:plumbing]
    params[:app] = params[:id]
    @app = App.get(params[:id])
    @new_table = NewTable.new(:table => "", :app => @app.app)
  end
  def scrape
    app = App.get(params[:app])
    row = app.get_table('scrapes').docs.first
    s = Scraper.new(row)
    s.run!
  end
end
