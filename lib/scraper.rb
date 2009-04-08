require 'hpricot'
require 'open-uri'
require 'ostruct'

class Scraper
  attr_accessor :raw_url, :xpath1, :xpath2, :row_code, :app, :param_code
  def initialize(row)
    @row_code = row['row_code']
    @xpath1 = row['xpath1']
    @xpath2 = row['xpath2']
    @raw_url = row['url']
    @app = row['app']
    @param_code = row['param_code']
  end
  def url
    s = OpenStruct.new
    eval(param_code).each { |k,v| puts [k,v].inspect; s.send("#{k}=",v) }
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
  def result_rows_raw_old
    [xpath1,xpath2].inject(doc) do |docs,exp| 
      if docs.is_a?(Array)
        docs.map { |x| x.search(exp) }
      else
        docs.search(exp)
      end
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
    result_rows.map { |x| ScraperRowEval.new(:row_code => row_code, :row => x).row_hash.merge(:app => app) }
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
  attr_accessor :row_code, :row
  include FromHash
  def row_hash
    instance_eval(row_code)
  end
end