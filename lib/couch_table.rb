class Object
  def klass
    self.class
  end
end

class ColumnConstraint
  attr_accessor :parent_table, :parent_column, :child_table, :child_column
  def initialize(row)
    @parent_table, @parent_column = *row.parent_column.split(":")
    @child_table, @child_column = *row.child_column.split(":")
  end
  def self.all
    CouchTable.get('columns').docs.select { |x| x.constraint_type.camelize == to_s }.map { |x| new(x) }
  end
end

class ForeignKey < ColumnConstraint
  def row_for(row)
    value = row.send(child_column)
    CouchTable.get(parent_table).docs.find { |x| x.send(parent_column) == value }
  end
end

class VirtualColumn < ColumnConstraint
  def value_for(row)
    fk = row.fk_row(parent_table)
    parent = fk.row_for(row)
    parent ? parent.send(parent_column) : nil
  end
end

class CalcColumn < ColumnConstraint
  attr_accessor :code
  def initialize(row)
    @child_table, @child_column = *row.child_column.split(":")
    @code = row.value
  end
  def value_for(row)
    row.instance_eval(code)
  #rescue => exp
  #  return nil
  end
end

class CouchRest::Document
  def fk_row(other_table)
    a = ForeignKey.all
    a.find { |x| x.parent_table == other_table and x.child_table == table }
  end
  def row_in_table(other_table)
    fk = fk_row(other_table)
    return fk.row_for(self)
    value = send(fk.child_column)
    CouchTable.get(fk.parent_table).docs.find { |x| x.send(fk.parent_column) == value }
  end
end

class TableManager
  fattr(:tables) do
    Hash.new { |h,k| h[k] = CouchTable.new(k.to_s) }
  end
  def get(t)
    tables[t]
  end
end

class CouchTable
  class << self
    def get(t)
      table_manager.get(t)
    end
    fattr(:table_manager) { TableManager.new }
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
    def tables
      all.map { |x| x.table }.uniq
    end
  end
  attr_accessor :table
  def initialize(table)
    @table = table
    raise "nil table" unless table.to_s != ''
  end
  def db
    klass.db
  end
  fattr(:docs) do
    klass.get_documents("function(doc){if(doc['table']=='#{table}') emit(null,doc)}")
  end
  def virtual_columns
    res = CouchTable.get('columns').docs.select { |x| x.constraint_type == 'virtual_column' }.map { |x| VirtualColumn.new(x) }
    res.select { |x| x.child_table == table }
  end
  def calc_columns
    res = CouchTable.get('columns').docs.select { |x| x.constraint_type == 'calc_column' }.map { |x| CalcColumn.new(x) }
    res.select { |x| x.child_table == table }
  end
  def concrete_keys
    docs.map { |x| x.keys }.flatten.uniq.reject { |x| x.to_s[0..0] == '_' }
  end
  def virtual_keys
    virtual_columns.map { |x| x.child_column }.uniq
  end
  def keys
    concrete_keys + virtual_keys + calc_columns.map { |x| x.child_column }.uniq
  end
  def remove_column(col)
    docs.each do |doc|
      doc.delete(col)
      doc.save
    end
  end
  def add_column(col)
    d = docs.first
    d[col] = ""
    d.save
  end
  def possible_values(col)
    docs.map { |x| x[col] }.uniq.select { |x| x }.sort
  end
  def create!
    db.save_doc(:table => table, :fake_column => "")
  end
end