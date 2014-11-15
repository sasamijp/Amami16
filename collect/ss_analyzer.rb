# -*- encoding: utf-8 -*-

class SSAnalyzer

  def corpus?(ss)
    sentence_length_average(ss) <= 20
  end

  def sentence_length_average(ss)
    len = ss.map{|v|v[:respond].length}
    len.inject(0.0){|r,i| r+=i }/len.size
  end

  def consecutive_talking(ss)
    conv = []
    names = ss.map{|v|v[:name]}
    start = -1
    names.each_with_index do |v, l|
      next if l < start
      c = []
      for i in 0..10000 do
        unless [names[l+i], names[l+i+1]].reverse == [names[l+i+1], names[l+i+2]]
          start = l+i
          break
        end
        c << l+i
      end
      conv << c
    end
    conv.delete_if{|v|v.empty? or v.length <= 10}.map{|v|v[3..-3]}
  end

  def extract_conv_corpus(ss)
    consecutive_talkings = consecutive_talking(ss)
    return [] if consecutive_talkings.empty?
    consecutive_talkings.flatten.map { |i| ss[i] }
  end

end
