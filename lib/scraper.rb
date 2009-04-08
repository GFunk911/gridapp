require 'hpricot'
require 'open-uri'
require 'ostruct'

class Scraper
  attr_accessor :raw_url, :xpath1, :xpath2, :row_code, :app, :param_code
  def initialize(row)
    @row = row
    @param_code = row['param_code']
  end
  def params_list
    res = eval(param_code)
    res = [res] unless res.is_a?(Array)
    res
  end
  def instances
    params_list.map { |x| i = ScraperInstance.new(@row); i.params = x; i }
  end
  def create_rows!
    instances.each { |x| x.create_rows! }
  end
end

class ScraperInstance
  attr_accessor :raw_url, :xpath1, :xpath2, :row_code, :app, :params
  def initialize(row)
    @row_code = row['row_code']
    @xpath1 = row['xpath1']
    @xpath2 = row['xpath2']
    @raw_url = row['url']
    @app = row['app']
  end
  def url
    s = OpenStruct.new
    params.each { |k,v| s.send("#{k}=",v) }
    s.instance_eval("\"#{raw_url}\"")
  end
  fattr(:doc) { Hpricot(open(url)) }
  def to_innerText(arr)
    if arr.respond_to?(:each)
      arr.map { |x| to_innerText(x) }
    else
      arr.innerText
    end
  end
  def result_rows_raw
    res = doc.search(xpath1)
    res = res.map { |x| x.search(xpath2) } unless xpath2.blank?
    res
  end
  def result_rows
    result_rows_raw.reject { |x| x.empty? }.map { |x| to_innerText(x) }.map { |x| x.is_a?(Array) ? x : [x] }
  end
  fattr(:row_hashes) do
    result_rows.map { |x| ScraperRowEval.new(:row_code => row_code, :row => x, :params => params).row_hash.merge(:app => app) }
  end
  def create_rows!
    puts "Creating #{row_hashes.size} rows from #{url}"
    row_hashes.each { |h| get_app.db.save_doc(h) }
  end
  def get_app
    App.get(app)
  end
end

class ScraperRowEval
  attr_accessor :row_code, :row, :params
  include FromHash
  def param
    params
  end
  def row_hash
    instance_eval(row_code)
  end
end