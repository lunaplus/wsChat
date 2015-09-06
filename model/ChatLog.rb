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

  def self.getLogCounts
    retval = 0
    retErr = ""
    begin
      mysqlClient = getMysqlClient
      queryStr = <<-SQL
        select count(*) as counts
          from chatLogs
      SQL
      rsltset = mysqlClient.query(queryStr)
      rsltset.each do |row|
        retval = row["counts"].to_i
      end
    rescue Mysql2::Error => e
      retErr = e.message
    end
    return retval, retErr
  end

  def self.getLogs(startseq, counts)
    retval = Array.new
    begin
      if startseq.kind_of?(Integer) and counts.kind_of?(Integer)
        if startseq < 0 or counts <= 0
          err = Hash.new
          err[:err] = "正の整数を入力してください。(ゼロ不可)"
          retval.unshift(err)
        else
          mysqlClient = getMysqlClient
          sseqEsc = startseq.to_s
          countsEsc = counts.to_s
          queryStr = <<-SQL
            select cu.name, cl.message, cl.sentDate
              from chatLogs cl
              join cgiUsers cu on cl.uid = cu.uid
             order by sentDate desc
             limit #{sseqEsc}, #{countsEsc}
          SQL
          rsltset = mysqlClient.query(queryStr)
          rsltset.each do |row|
            elm = Hash.new
            elm[:name] = row["name"]
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
