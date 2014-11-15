# -*- encoding: utf-8 -*-

require 'nokogiri'
require 'open-uri'
require 'Sequel'
require './ss_parser.rb'
require './ss_analyzer.rb'
require 'pp'
require 'natto'

def wakati(str)
  array = []
  if str.split('')[0] == ' '
    str = str[1..-1]
  end
  @natto.parse(str.split('').map { |v| (v == ' ') ? '　' : v }.join('')) { |n| array.push [n.surface, n.feature] }
  array[0..array.length-2]
end

def extractcontent_elp(url)
  ret = []
  charset = nil
  html = open(url) do |f|
    charset = f.charset
    f.read
  end
  doc =  Nokogiri::HTML.parse(html, nil, charset)
  doc.xpath('//div[@class="article"]/dl/dd/b').each do |v|
    v.children.each do |_v|
      ret << _v.text + "\n"
    end
  end
  if ret == []
    doc.xpath('//div[@class="article"]/dd/b').each do |v|
      v.children.each do |_v|
        ret << _v.text + "\n"
      end
    end
  end
  ret.delete_if{|v|v==""}.join('')
end

def extractcontent(url)
  charset = nil
  html = open(url) do |f|
    charset = f.charset
    f.read
  end
  doc =  Nokogiri::HTML.parse(html, nil, charset)
  re = doc.xpath('//div[@class="article-body"]')[0].children.max_by{|v|v.text.count('「')}
  return '' if re.to_s.include?("７６５アイドル出演ラジオ番組表：SS一覧")
  pp "="*1000
  doc2 =  Nokogiri::HTML.parse(re.to_s.gsub('<br>', "\n").gsub('</div>', "\n</div>"), nil, charset)
  ret =[]
  doc2.xpath('//div')[1..-1].each do |v|
    next if v.text =~ /\d+:.*\d+\/\d+\/\d+\(.\) \d+:\d+:\d+.\d+ ID:........./
    next if v.text.length < 100
    ret << v.text
  end
  ret.join('')
end

def case_pattern(str)
  ret = []
  parsed = []
  @natto.parse(str) { |n| parsed.push n }
  parsed[0..-2].each_with_index do |v, l|
    case v.feature.split(',')[1]
      when /.*(副助詞|終助詞).*/
      when /.*(係助詞|格助詞|並立助詞|連体化).*/
        ret << [parsed[l-1], v, parsed[l+1]].map{|_v|_v.surface}.compact
      when /.*(接続助詞|読点|句点).*/
        ret << [parsed[0..l-1].map{|_v|_v.surface}.join(''), parsed[l+1..-2].map{|_v|_v.surface}.join('')].flatten.compact
      else
    end
  end
  ret << parsed[0..-2].map{|v|v.surface}.compact.join('') if ret.empty?
  ret
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

def completely_different?(wstr1, wstr2)
  wstr1.each do |v|
    wstr2.each do |_v|
      return false if _v[0] == v[0] and _v[1].match(/^助/).nil? and v[1].match(/^助/).nil?
    end
  end
  true
end

def split_by_connect(wstr)
  pos = -1
  ret = []
  wstr[1..-2].each_with_index do |v, l|
    case v[1]
      when /.*(記号|終助詞).*/
        case pos
          when -1
            arr = wstr[pos+1..l]
          else
            arr = wstr[pos+2..l]
        end
        ret << arr.push(v).delete_if{|_v|_v[0]=='　'}
        pos = l
      else
    end
    if l == wstr.size-3
      (ret.length == 0) ?
          ret << wstr[pos+1..l+2].delete_if { |_v| _v[0]=='　' } :
          ret << wstr[pos+2..l+2].delete_if { |_v| _v[0]=='　' }
    end
  end
  ret.delete_if{|v|(v.length == 1 and not v[0][1].match(/.*(記号|終助詞).*/).nil?) or v.length == 0}
end

def meaning_distance(wstr1, wstr2)
  return nil if completely_different? wstr1, wstr2
  cases = split_by_connect(wstr1)
  all = cases.flatten.length
  cases.map { |v| (levenshtein_distance(v, wstr2) * (all/v.length.to_f)) }.min
end

def bool_digit(flag)
  flag ? 1 : 0
end

def insert(ss)
  ss.each do |v|
    @db[:respond].insert(link_id: @linkid, respond_sentence: v[:respond])
    @db[:target].insert(link_id: @linkid, target_sentence: v[:in_reply_to])
    wakati(v[:in_reply_to]).each do |_v|
      @db[:word].insert(
          word_id: @wordid,
          word_target_id: @linkid,
          word_text: _v[0],
          word_is_joshi: bool_digit(not(_v[1].match(/^助/).nil?)),
          word_is_connector: bool_digit(not(_v[1].match(/.*(記号|終助詞).*/).nil?))
      )
      @wordid += 1
    end
    @linkid += 1
  end
end

@linkid = 0
@wordid = 0
@db = Sequel.connect("sqlite://../db/main_c.db")
@s = SSparser.new
@sa = SSAnalyzer.new
@natto = Natto::MeCab.new

url = []
loop do
  begin
    url << gets.chomp
  rescue; break end
end

url.each do |v|
  if v.include?("ankake")
    insert @sa.extract_conv_corpus(@s.parse extractcontent v).select{|_v|_v[:name] == "千早"}
  else
    insert @sa.extract_conv_corpus(@s.parse extractcontent_elp v).select{|_v|_v[:name] == "千早"}
  end
end
