#require 'couch_foo'
#CouchFoo::Base.set_database(:host => "http://localhost:5984", :database => "testdb")
#CouchFoo::Base.logger = Rails.logger

require 'couchrest'
class CouchRest::Document
  def method_missing(sym,*args,&b)
    if include?(sym.to_s)
      self[sym]
    else
      super(sym,*args,&b)
    end
  end
  def id
    self["_id"]
  end
end
