# -*- coding: utf-8 -*-
# encording: utf-8
# chatLogs model
require_relative '../util/HtmlUtil'
require_relative './ModelMaster'

class ChatLog < ModelMaster
  def self.insertLog(uid, message, rid)
    begin
      mysqlClient = getMysqlClient
      uidEscaped = mysqlClient.escape(uid)
      msgEscaped = mysqlClient.escape(message)
      ridEscaped = mysqlClient.escape(rid)
      queryStr = <<-SQL
        insert into chatLogs(uid, message, sentDate, rid)
           values( '#{uidEscaped}', '#{msgEscaped}', cast(now() as datetime),
                   '#{ridEscaped}' )
      SQL
      mysqlClient.query(queryStr)
      return true, nil
    rescue Mysql2::Error => e
      return false, e.message
    ensure
      mysqlClient.close
    end
  end

  def self.getLogCounts(rid = nil)
    retval = 0
    retErr = nil
    begin
      mysqlClient = getMysqlClient
      ridEsc = mysqlClient.escape(rid) unless rid.nil?
      queryStr = <<-SQL
        select count(*) as counts
          from chatLogs
      SQL
      queryStr += "where rid = '#{ridEsc}'" unless rid.nil?
      rsltset = mysqlClient.query(queryStr)
      rsltset.each do |row|
        retval = row["counts"].to_i
      end
    rescue Mysql2::Error => e
      retErr = e.message
    ensure
      mysqlClient.close
    end
    return retval, retErr
  end

  def self.getLogs(startseq, counts, rid = nil)
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
          ridEsc = " is null"
          ridEsc = " = '" + mysqlClient.escape(rid) + "' " unless rid.nil?
          queryStr = <<-SQL
            select cu.name, cl.message, cl.sentDate, cr.rname
              from chatLogs cl
              join cgiUsers cu on cl.uid = cu.uid
              left join chatRooms cr on cl.rid = cr.id
             where cl.rid #{ridEsc}
             order by sentDate desc
             limit #{sseqEsc}, #{countsEsc}
          SQL
          rsltset = mysqlClient.query(queryStr)
          rsltset.each do |row|
            elm = Hash.new
            elm[:name] = row["name"]
            elm[:message] = row["message"]
            elm[:sentDate] = row["sentDate"]
            elm[:rname] = row["rname"]
            elm[:err] = ""
            retval.push(elm)
          end
        end
      end
    rescue Mysql2::Error => e
      err = Hash.new
      err[:err] = e.message
      retval.unshift(err)
    ensure
      mysqlClient.close
    end
    return retval
  end

  def self.removeLogs(rid)
    retval = false
    reterr = nil
    if rid.nil? || rid.empty?
      reterr = "ルームIDを指定してください。"
    else
      begin
        mysqlClient = getMysqlClient
        ridEsc = mysqlClient.escape(rid)
        queryStr = <<-SQL
        delete from chatLogs where rid = '#{ridEsc}'
      SQL
        mysqlClient.query(queryStr)
        retval = true
      rescue Mysql::Error => e
        reterr = e.message
      ensure
        mysqlClient.close
      end
    end
    return retval, reterr
  end
end
