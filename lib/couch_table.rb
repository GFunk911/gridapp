class Object
  def klass
    self.class
  end
end

class ColumnConstraint
  attr_accessor :parent_table, :parent_column, :child_table, :child_column, :value, :parent, :child
  def initialize(row)
    @parent = row.parent_column
    @child = row.child_column
    @parent_table, @parent_column = *row.parent_column.split(":")
    @child_table, @child_column = *row.child_column.split(":")
    @value = row['value']
  end
  def self.parent_all
    CouchTable.get('columns').docs.map { |x| cls = eval(x.constraint_type.camelize); cls.new(x) }
  end
  def self.all
    CouchTable.get('columns').docs.select { |x| x.constraint_type.camelize == to_s }.map { |x| new(x) }
  end
  def self.select_h(h)
    all.select_h(h)
  end
  def self.find_h(h)
    all.find_h(h)
  end
end

class ForeignKey < ColumnConstraint
  def row_for(row)
    value = row.send(child_column)
    CouchTable.get(parent_table).docs.find { |x| x.send(parent_column) == value }
  end
  def rows_for(row)
    value = row.send(parent_column)
    CouchTable.get(child_table).docs.select { |x| x.send(child_column) == value }
  end
  def possible_values
    res = CouchTable.get(parent_table).docs
    res = res.select { |x| x.instance_eval(value) } if value
    res = [""] + res.map { |x| x[parent_column.to_s] }
    res = res.select { |x| x }
    res.sort
  end
  def child_editable?
    true
  end
end

class VirtualColumn < ColumnConstraint
  def value_for(row)
    fk = row.fk_row(parent_table)
    parent = fk.row_for(row)
    parent ? parent.send(parent_column) : nil
  end
  def child_editable?
    false
  end
end

class SortColumn < ColumnConstraint
  def sorted_rows(rows)
    rows.sort_by { |x| x.instance_eval(value) }
  end
  def child_editable?
    true
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
  def child_editable?
    false
  end
end

class VirtualTable < ColumnConstraint
end

module Enumerable
  def mysum(*args)
    if args.empty?
      inject(0) { |s,i| s + i }
    elsif args.size == 1
      k = args.first
      res = inject(0) { |s,i| s + i.send(k).to_f }
      (res == res.to_i) ? res.to_i : res
    else
      raise "can't sum with #{args.size} args #{args.inspect}"
    end
  end
  def select_h(h)
    select do |row|
      h.all? { |k,v| row.send(k) == v }
    end
  end
  def find_h(h)
    select_h(h).first
  end
end

class Array
  def method_missing(sym,*args,&b)
    table = CouchTable.get(first.table)
    if table.keys.include?(sym.to_s)
      raise "no args #{args.insect}" unless args.size == 1
      select_h(sym => args.first)
    else
      puts "key #{sym} not in #{table.keys.inspect}"
      super(sym,*args,&b)
    end
  end
end

class CouchRest::Document
  def fk_row(other_table)
    a = ForeignKey.all
    a.find { |x| x.parent_table == other_table.to_s and x.child_table == table }
  end
  def child_fk_row(other_table)
    a = ForeignKey.all
    a.find { |x| x.parent_table == table and x.child_table == other_table.to_s }
  end
  def row_in_table(other_table)
    fk = fk_row(other_table)
    return fk.row_for(self)
    #value = send(fk.child_column)
    #CouchTable.get(fk.parent_table).docs.find { |x| x.send(fk.parent_column) == value }
  end
  def parent_rows_in_table(t)
    DocumentList.new(child_fk_row(t.to_s).rows_for(self))
  end
  def parent(t)
    row_in_table(t)
  end
  def children(t)
    parent_rows_in_table(t)
  end
end

class DocumentList < BlankSlate
  attr_accessor :list
  def initialize(list)
    @list = list
  end
  def method_missing(sym,*args,&b)
    if sym == :parent
      list.map { |x| x.parent(*args,&b) }.select { |x| x }
    else
      list.send(sym,*args,&b)
    end
  end
end

class TableManager
  fattr(:tables) do
    Hash.new { |h,k| h[k] = new_table(k.to_s) }
  end
  def new_table(table)
    if ['columns'].include?(table)
      ConcreteCouchTable.new(table)
    else
      CouchTable.table_class(table).new(table)
    end
  end
  def get(t)
    tables[t]
    #new_table(t.to_s)
  end
end

module CouchTableClassMethods
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
  def concrete_tables
    all.map { |x| x.table }.uniq
  end
  def virtual_tables
    VirtualTable.all.map { |x| x.child_table }
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
end

class CouchTable
  extend CouchTableClassMethods
end

class ConcreteCouchTable < CouchTable
  attr_accessor :table
  def initialize(table)
    @table = table
    raise "nil table" unless table.to_s != ''
  end
  def db
    CouchTable.db
  end
  fattr(:all_docs) do
    klass.get_documents("function(doc){if(doc['table']=='#{table}') emit(null,doc)}")
  end
  def sorted_docs(rows)
    col = sort_column
    if col
      col.sorted_rows(rows)
    else
      rows
    end
  end
  fattr(:docs) do
    sorted_docs(all_docs)
  end
  def sort_column
    res = CouchTable.get('columns').all_docs.select { |x| x.constraint_type == 'sort_column' }.map { |x| SortColumn.new(x) }
    res.find { |x| x.child_table == table }
  end
  def virtual_columns
    res = CouchTable.get('columns').all_docs.select { |x| x.constraint_type == 'virtual_column' }.map { |x| VirtualColumn.new(x) }
    res.select { |x| x.child_table == table }
  end
  def calc_columns
    res = CouchTable.get('columns').all_docs.select { |x| x.constraint_type == 'calc_column' }.map { |x| CalcColumn.new(x) }
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
  def to_csv
    ks = concrete_keys.reject { |x| x.to_s == 'table' }
    headers = ks.join(",")
    rows = docs.map do |row|
      ks.map { |k| row[k] }.join(",")
    end
    ([headers]+rows).join("\n")
  end
end

class VirtualCouchTable < ConcreteCouchTable
  fattr(:virtual_table_constraint) do
    VirtualTable.find_h(:child_table => table)
  end
  fattr(:base_table_name) do
    raise "no virtual table constraint for #{table}" unless virtual_table_constraint
    virtual_table_constraint.parent_table
  end
  def base_table
    CouchTable.get(base_table_name)
  end
  fattr(:all_docs) do
    base_table.all_docs
  end
  fattr(:docs) do
    value = virtual_table_constraint.value
    return all_docs unless value and value != ''
    all_docs.select { |row| row.instance_eval(value) }
  end
end