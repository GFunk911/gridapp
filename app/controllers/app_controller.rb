class NewTable
  attr_accessor :table, :app
  include FromHash
end

class AppController < ApplicationController
  def show_setup
    puts params.inspect
    @plumbing = !!params[:plumbing]
    params[:app] ||= params[:id]
    @app = App.get(params[:app])
    @new_table = NewTable.new(:table => "", :app => @app.app)
  end
  def show
    show_setup
  end
  def scrape
    app = App.get(params[:app])
    row = app.get_table('scrapes').docs.first
    s = Scraper.new(row)
    s.create_rows!
    show_setup
    redirect_to :controller => 'app', :action => 'show', :app => params[:app]
  end
end
