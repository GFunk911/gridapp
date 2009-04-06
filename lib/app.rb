class App
  attr_accessor :app
  include FromHash
  def self.get(a)
    new(:app => a)
  end
  def get_table(t)
    t = t[:table] if t.is_a?(Hash)
    table_manager.get(self,t)
    #TableManager.new.new_table(self,t)
  end
  fattr(:table_manager) { TableManager.instance }
  fattr(:db) { CouchRest.database!("http://127.0.0.1:5984/testdb_test") }
  def get_documents(view_func)
    view_hash = {:map=>view_func}
    view = db.temp_view(view_hash)
    view['rows'].map do |x| 
      CouchRest::Document.new(x['value']).tap { |x| x.database = db }
    end
  end
  def find(doc_id)
    get_documents("function(doc){if(doc['_id']=='#{doc_id}') emit(null,doc)}").first
  end
  def all
    get_documents("function(doc){ emit(null,doc)}")
  end
  def concrete_tables
    all.map { |x| x.table }.uniq
  end
  def virtual_tables
    constraints(VirtualTable).map { |x| x.child_table }
  end
  def tables
    concrete_tables + virtual_tables
  end
  def couch_tables
    tables.map { |x| get(x) }
  end
  def table_class(table)
    return VirtualCouchTable if virtual_tables.include?(table)
    ConcreteCouchTable
  end
  def constraints(cls=nil)
    if cls
      get_table('columns').docs.select { |x| x.constraint_type.camelize == cls.to_s }.map { |x| cls.new(x) }
    else
      get_table('columns').docs.map { |x| cls = eval(x.constraint_type.camelize); cls.new(x) }
    end
  end
end

class TableManager
  class << self
    fattr(:instance) { TableManager.new }
  end
  fattr(:tables) do
    Hash.new { |h,k| h[k] = new_table(App.get(k[0]),k[1].to_s) }
  end
  def new_table(app,table)
    if ['columns'].include?(table)
      ConcreteCouchTable.new(app,table)
    else
      app.table_class(table).new(app,table)
    end
  end
  def get(app,t)
    tables[[app.app,t]]
    #new_table(t.to_s)
  end
end