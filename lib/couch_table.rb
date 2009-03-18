class CouchTable
  fattr(:db) { CouchRest.database!("http://127.0.0.1:5984/testdb") }
  fattr(:docs) do
    view_hash = {:map=>"function(doc){emit(null,doc)}"}
    view = db.temp_view(view_hash)
    view['rows'].map do |x| 
      res = CouchRest::Document.new(x['value']) 
      res.database = db
      res
    end
  end
  def keys
    docs.map { |x| x.keys }.flatten.uniq.reject { |x| x.to_s[0..0] == '_' }
  end
  def remove_column(col)
    docs.each do |doc|
      doc.delete(col)
      doc.save
    end
  end
end