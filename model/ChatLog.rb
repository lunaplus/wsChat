# -*- coding: utf-8 -*-
# encording: utf-8
# chatLogs model
require_relative '../util/HtmlUtil'
require_relative './ModelMaster'

class ChatLog < ModelMaster
  def self.insertLog(uid, message)
    begin
      mysqlClient = getMysqlClient
      uidEscaped = mysqlClient.escape(uid)
      msgEscaped = mysqlClient.escape(message)
      queryStr = <<-SQL
        insert into chatLogs(uid, message, sentDate)
           values( '#{uidEscaped}', '#{msgEscaped}', cast(now() as datetime) )
      SQL
      mysqlClient.query(queryStr)
      return true, ""
    rescue Mysql2::Error => e
      return false, e.message
    end
  end

  def self.getLogs(startseq, endseq)
    retval = Array.new
    begin
      if startseq.kind_of?(Integer) and endseq.kind_of?(Integer)
        if startseq <= 0 or endseq <= 0
          err = Hash.new
          err[:err] = "正の整数を入力してください。(ゼロ不可)"
          retval.unshift(err)
        else
          sseq = 0
          eseq = 0
          if startseq > endseq
            sseq = endseq
            eseq = startseq - endseq + 1
          else
            sseq = startseq
            eseq = endseq - startseq + 1
          end
          mysqlClient = getMysqlClient
          sseqEsc = sseq.to_s
          eseqEsc = eseq.to_s
          queryStr = <<-SQL
            select uid, message, sentDate
              from chatLogs
             order by sentDate desc
             limit #{sseq}, #{eseq}
          SQL
          rsltset = mysqlClient.query(queryStr)
          rsltset.each do |row|
            elm = Hash.new
            elm[:uid] = row["uid"]
            elm[:message] = row["message"]
            elm[:sentDate] = row["sentDate"]
            elm[:err] = ""
            retval.push(elm)
          end
        end
      end
    rescue Mysql2::Error => e
      err = Hash.new
      err[:err] = e.message
      retval.unshift(err)
    end
    return retval
  end
end
