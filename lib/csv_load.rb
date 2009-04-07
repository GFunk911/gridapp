FIXTURES_DIR = File.expand_path(File.dirname(__FILE__) + "/../spec/fixtures")

def load_from_csv!
  require 'fastercsv'
  @app = App.get('draft')
  @db = @app.db
  @db.recreate!
  
  files = Dir["#{FIXTURES_DIR}/**/*.csv"]
  files.each do |file|
    load_csv_file!(file)
  end
end

def load_csv_file!(file)
  table = File.basename(file).split(".")[0]
  app = file.split("/")[-2]
  FasterCSV.foreach(file,:headers => true) do |row| 
    @db.save_doc(row.to_hash.merge(:table => table, :app => app))
  end
end

def make_csv!
  CouchTable.couch_tables.each do |table|
    File.create("#{FIXTURES_DIR}/#{table.table}.csv",table.to_csv)
  end
end