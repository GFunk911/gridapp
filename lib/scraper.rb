require 'hpricot'
require 'open-uri'
require 'ostruct'
def unescape(str)
  h = { '&amp;' => '&', '&gt;' => '>', '&lt;' => '<',  '&quot;' => '"' }
  res = str
  h.each { |k,v| res = res.gsub(k,v) }
  res
end
class ParamsInstance
  attr_accessor :param_code
  include FromHash
  def params
    instance_eval(unescape(param_code))
  end
  def table(t)
    App.get('njtransit').get_table(t)
  end
end

class Scraper
  attr_accessor :raw_url, :xpath1, :xpath2, :row_code, :app, :param_code
  def initialize(row)
    @row = row
    @param_code = row['param_code']
  end
  def params_list
    res = ParamsInstance.new(:param_code => param_code).params
    res = [res] unless res.is_a?(Array)
    res
  end
  def instances
    params_list.map { |x| i = ScraperInstance.new(@row); i.params = x; i }
  end
  def create_rows!
    instances.map { |x| x.create_rows! }.flatten
    TableManager.instance!
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
    if params.is_a?(Hash)
      params.each { |k,v| s.send("#{k}=",v) }
    else
      s.param = params
    end
    res = s.instance_eval("\"#{raw_url}\"")
    #puts "URL: #{res}"
    res
  end
  fattr(:doc) { Hpricot(open(url)) }
  def self.to_innerText(arr)
    #puts arr.class
    if arr.is_a?(String)
      arr
    elsif arr.respond_to?(:each)
      arr.map { |x| to_innerText(x) }
    elsif arr.respond_to?(:innerText)
      arr.innerText
    else
      arr.to_s
    end
  end
  def result_rows_raw
    res = doc.search(xpath1)
    res = res.map { |x| x.search(xpath2) } unless xpath2.blank?
    res
  end
  def to_element_wrapper(x)
    if x.respond_to?(:get_attribute)
      ElementWrapper.new(x)
    elsif x.is_a?(Array)
      x.map { |el| to_element_wrapper(el) }
    else
      x
    end
  end
  def result_rows
    result_rows_raw.reject { |x| x.empty? }.map { |x| x.is_a?(Array) ? x : [x] }.map { |x| to_element_wrapper(x) }
  end
  fattr(:row_hashes) do
    result_rows.map { |x| ScraperRowEval.new(:row_code => row_code, :row => x, :params => params).row_hash.merge(:app => app) }
  end
  def create_rows!
    puts "Creating #{row_hashes.size} rows from #{url}"
    row_hashes.each { |h| get_app.db.save_doc(h) }
    row_hashes
  end
  def get_app
    App.get(app)
  end
end

class Hash
  def map_value
    res = {}
    each { |k,v| res[k] = yield(v) }
    res
  end
end

class ElementWrapper < BlankSlate
  attr_accessor :obj
  def initialize(obj)
    @obj = obj
  end
  def method_missing(sym,*args,&b)
    obj.respond_to?(sym) ? obj.send(sym,*args,&b) : @obj.get_attribute(sym.to_s)
  end
end

class ScraperRowEval
  attr_accessor :row_code, :row, :params
  include FromHash
  def param
    params
  end
  def row_hash
    instance_eval(unescape(row_code)).map_value { |x| ScraperInstance.to_innerText(x) }
  end
end

def run_scrape(app,table)
  row = App.get(app).get_table('scrapes').docs.first
  s = Scraper.new(row)
  s.create_rows!
  App.get(app).get_table(table).docs[0...10].each { |x| puts x.inspect }
  s
end

def run_scrapes(app)
  rows = App.get(app).get_table('scrapes').docs
  rows = rows.sort_by { |x| x.url }.reverse
  rows.each do |row|
    s = Scraper.new(row)
    res = s.create_rows!
    #puts res.inspect
    #puts res.first.inspect
    table = res.first[:table] || res.first['table']
    raise "nil table #{res.first.inspect}" unless table
    App.get(app).get_table(table).docs[0...10].each { |x| puts x.inspect }
  end
end