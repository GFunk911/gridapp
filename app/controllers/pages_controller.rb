class PagesController < ApplicationController
  def create
    PageManager.get(self).add_page(params[:name])
    render :partial => 'pages/index'
  end
end
