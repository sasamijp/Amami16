# encoding: utf-8

require 'active_record'
require 'pp'
require 'natto'
require './model.rb'

class Responder

  def initialize(dbpath)
    @natto = Natto::MeCab.new
    ActiveRecord::Base.establish_connection(
        :adapter => 'sqlite3',
        :database => dbpath
    )
    @dbpath = dbpath
  end

  def wakati(str)
    array = []
    str = str[1..-1] if str.split('')[0] == ' '
    @natto.parse(str.split('').map { |v| (v == ' ') ? '　' : v }.join('')) { |n| array.push [n.surface, n.feature] }
    array[0..array.length-2]
  end

  def split_by_connect(words)
    pos = -1
    ret = []
    words[1..-2].each_with_index do |v, l|
      case v[:word_is_connector]
        when 1
          case pos
            when -1
              arr = words[pos+1..l]
            else
              arr = words[pos+2..l]
          end
          ret << arr.push(v).delete_if{|_v|_v[:word_text]=='　'}
          pos = l
        else
      end
      if l == words.size-3
        (ret.length == 0) ?
            ret << words[pos+1..l+2].delete_if { |_v| _v[:word_text]=='　' } :
            ret << words[pos+2..l+2].delete_if { |_v| _v[:word_text]=='　' }
      end
    end
    ret.delete_if{|v|(v.length == 1 and v[0][:word_is_connector] == 1) or v.length == 0}
  end

  def levenshtein_distance(str1, str2)
    col, row = str1.size + 1, str2.size + 1
    d = row.times.inject([]){|a, i| a << [0] * col }
    col.times {|i| d[0][i] = i }
    row.times {|i| d[i][0] = i }

    str1.size.times do |i1|
      str2.size.times do |i2|
        cost = str1[i1] == str2[i2] ? 0 : 1
        x, y = i1 + 1, i2 + 1
        d[y][x] = [d[y][x-1]+1, d[y-1][x]+1, d[y-1][x-1]+cost].min
      end
    end
    d[str2.size][str1.size]
  end

  def respond(str)
    ActiveRecord::Base.establish_connection(
        :adapter => 'sqlite3',
        :database => @dbpath
    )
    wstr = wakati(str)
    id = wakati(str).map{|v|v[0]}.map do |v|
      Word.select(:word_target_id).where(word_text: v, word_is_joshi: 0, word_is_connector: 0)
    end
    not_comp_diff = []
    id.flatten.map{|v|v[:word_target_id]}.each do |v|
      words = Word.where(:word_target_id => v)
      words.each do |_v|
        wstr.each do |__v|
          if _v[:word_text] == __v[0] and _v[:word_is_joshi] == 0 and __v[1].match(/^助/).nil?
            not_comp_diff << words
            break
          end
        end
      end
    end
    puts not_comp_diff.length
    distances = not_comp_diff.map do |words|
      cases = split_by_connect words
      all = cases.flatten.length
      [words, cases.map{ |v|
        (levenshtein_distance(v.map{|_v|_v[:word_text]}, wstr.map{|_v|_v[0]}) * (all/v.length.to_f))
      }.min]
    end
    distances.delete_if{|v|v[1].nil?}
    pp distances.sort_by{|v|v[1]}[0][0]
    Respond.select(:respond_sentence).where(link_id: distances.sort_by{|v|v[1]}[0][0][0][:word_target_id])[0][:respond_sentence]
  end

end

#r = Responder.new('../db/main_c.db')
#pp r.respond("誰だよ")


