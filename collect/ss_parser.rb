# -*- encoding: utf-8 -*-

class SSparser

  def parse(body)
    (body.count('『') > body.count('「')) ?
        body.gsub('｢', '「').gsub('『', '「').gsub('』', '」').gsub('｣', '」') :
        body.gsub('｢', '「').gsub('｣', '」')
    body = body.split("\n").delete_if{|v|v.nil?}
    ss = []
    in_reply_to = nil
    in_reply_to_char = nil
    body.delete_if{|v|(!v.include?('「') and !v.include?('」'))}.each do |str|
      n_s = split_name_respond(str)
      next if n_s.nil?
      hash = {
          name: n_s[0],
          respond: n_s[1],
          in_reply_to: in_reply_to,
          in_reply_to_char: in_reply_to_char }
      (hash[:in_reply_to_char] == hash[:name]) ? hash[:in_reply_to] = nil : in_reply_to = hash[:respond]
      in_reply_to_char = hash[:name]
      ss.push hash
    end
    ss.map!{|v|{name: v[:name], respond: v[:respond], in_reply_to: v[:in_reply_to]}}
    ss.delete_if{|hash| hash[:name].nil? or hash[:respond].nil? or hash[:in_reply_to].nil?}
  end

  def split_name_respond(str)
    begin
      name = str[0..str.rindex('「')-1].gsub(' ', '').gsub("　", '')
      [name, str.sub('「', '').reverse.sub('」', '').reverse.sub(name, '')]
    rescue
      nil
    end
  end

end
