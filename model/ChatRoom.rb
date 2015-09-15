# -*- coding: utf-8 -*-
# encording: utf-8
# chatrooms model
require_relative '../util/HtmlUtil'
require_relative './ModelMaster'

class ChatRoom < ModelMaster
  def self.getListRoom
    retval = Array.new
    reterr = nil
    begin
      mysqlClient = getMysqlClient
      queryStr = <<-SQL
        select id, rname from chatRooms
         order by rname asc
      SQL
      rsltset = mysqlClient.query(queryStr)
      rsltset.each do |row|
        tmp = Hash.new
        tmp[:rname] = row["rname"].to_s
        tmp[:rid] = row["id"].to_s
        retval.push(tmp)
      end
    rescue Mysql2::Error => e
      retval = nil
      reterr = e.message
    ensure
      mysqlClient.close
    end
    return retval, reterr
  end

  def self.createRoom(name, password, uid)
    rid = nil
    retval = false
    reterr = nil
    begin
      if name == "" or uid == ""
        reterr = "ルーム名とオーナーのUIDは必須です"
      else
        pwd = (password.nil? ? "" : password)
        mysqlClient = getMysqlClient
        nameEsc = mysqlClient.escape(name)
        pwdEsc = mysqlClient.escape(HtmlUtil.digestPassword pwd)
        uidEsc = mysqlClient.escape(uid)
        queryStr = <<-SQL
          select count(*) as counts from chatRooms
           where rname = '#{nameEsc}'
        SQL
        rsltset = mysqlClient.query(queryStr)
        counts = 0
        rsltset.each do |row|
          counts = row["counts"].to_i
        end
        if counts != 0
          reterr = "同じ名前のルームが存在します。"
        else
          col = "rname, "
          col += "password, " unless pwd == ""
          col += "uid"
          val = "'#{nameEsc}', "
          val += "'#{pwdEsc}', " unless pwd == ""
          val += "'#{uidEsc}'"
          queryStr = <<-SQL
            insert into chatRooms(#{col})
                   values(#{val})
          SQL
          mysqlClient.query(queryStr)

          queryStr = " select id from chatRooms where "
          queryStr += " rname = '#{nameEsc}' "
          queryStr += " and password = '#{pwdEsc}' " unless pwd == ""
          queryStr += " and uid = '#{uidEsc}' "

          rsltset = mysqlClient.query(queryStr)
          rsltset.each do |row|
            rid = row["id"].to_s
          end
          retval = true
        end
      end
    rescue Mysql2::Error => e
      retval = false
      reterr = e.message
    ensure
      mysqlClient.close
    end
    return retval, reterr, rid
  end

  def self.updateRoom(rid, rname, password, uid)
    retval = false
    reterr = nil
    begin
      pwd = (password.nil? ? "" : password)
      mysqlClient = getMysqlClient
      ridEsc = mysqlClient.escape(rid)
      nameEsc = mysqlClient.escape(rname)
      pwdEsc = mysqlClient.escape(HtmlUtil.digestPassword pwd)
      uidEsc = mysqlClient.escape(uid)

      setName = (rname=="" ? "" : "rname = '#{nameEsc}', ")
      setpwd = (pwd=="" ? "" : "password = '#{pwdEsc}', ")
      setuid = (uid=="" ? "" : "uid = '#{uidEsc}'")

      if setName != "" and setpwd != "" and setuid != ""
        queryStr = <<-SQL
          update chatRooms
             set #{setName} #{setpwd} #{setuid}
           where id = '#{ridEsc}'
        SQL
        mysqlClient.query(queryStr)
        retval = true
      end
    rescue Mysql2::Error => e
      retval = false
      reterr = e.message
    ensure
      mysqlClient.close
    end
    return retval, reterr
  end

  def self.loginRoom(rid, password)
    retval = false
    reterr = nil
    begin
      pwd = (password.nil? ? "" : password)
      mysqlClient = getMysqlClient
      ridEsc = mysqlClient.escape(rid)
      pwdEsc = mysqlClient.escape(HtmlUtil.digestPassword pwd)
      cond = "id = '#{ridEsc}'"
      cond += "and password " + (pwd=="" ? " is null" : " = '#{pwdEsc}'")
      queryStr = <<-SQL
        select count(*) as counts from chatRooms
         where #{cond}
      SQL
      rsltset = mysqlClient.query(queryStr)
      counts = 0
      rsltset.each do |row|
        counts = row["counts"].to_i
      end
      retval = (counts != 0)
    rescue Mysql2::Error => e
      retval = false
      reterr = e.message
    ensure
      mysqlClient.close
    end
    return retval, reterr
  end

end
