#require 'couch_foo'
#CouchFoo::Base.set_database(:host => "http://localhost:5984", :database => "testdb")
#CouchFoo::Base.logger = Rails.logger

require 'couchrest'
class CouchRest::Document
  def method_missing(sym,*args,&b)
    if self[sym]
      self[sym]
    elsif virtual_column(sym)
      virtual_column(sym).value_for(self)
    elsif calc_column(sym)
      calc_column(sym).value_for(self)
    else
      self[sym]
    end
  end
  def virtual_column(col)
    res = CouchTable.get(self[:table])
    res = res.virtual_columns
    res = res.find { |x| x.child_column == col.to_s }
  end
  def calc_column(col)
    res = CouchTable.get(self[:table])
    res = res.calc_columns
    res = res.find { |x| x.child_column == col.to_s }
  end
  def id
    self["_id"]
  end
end
