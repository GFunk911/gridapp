class Scraper
  attr_accessor :code, :target_table, :url, :app
  def initialize(row)
    @code = row['code']
    @target_table = row['target_table']
    @url = row['url']
    @app = row['app']
  end
  def run!
    require 'hpricot'
    require 'open-uri'
    doc = Hpricot(open(url))
    res = eval(code)
    res.each do |h|
      hash = h.merge(:app => app, :table => target_table)
      get_app.db.save_doc(hash)
    end
  end
  def get_app
    App.get(app)
  end
end