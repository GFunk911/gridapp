class AppController < ApplicationController
  def show
    params[:app] = params[:id]
    @app = App.get(params[:id])
  end
end
