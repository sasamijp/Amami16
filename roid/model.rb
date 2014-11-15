# encoding: utf-8

class Corpus < ActiveRecord::Base
  self.abstract_class = true
  #establish_connection( adapter: 'sqlite3', database: '../db/main.db' )
end

class Respond < Corpus
  self.table_name = 'respond'
end

class Target < Corpus
  self.table_name = 'target'
end

class Word < Corpus
  self.table_name = 'word'
end
