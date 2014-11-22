# encoding: utf-8

class Session

  attr_accessor :user_id
  attr_accessor :conv_log

  def initialize(user_id)
    @user_id = user_id
    @conv_log = []
    @remark = Struct.new(:is_ai, :text)
  end

  def add_remark(is_ai, text)
    @conv_log.push @remark.new( is_ai, text )
  end



end
