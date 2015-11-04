# -*- coding: utf-8 -*-
# encording: utf-8
# chatrooms model
require_relative '../util/HtmlUtil'
require_relative './ModelMaster'
require_relative './ChatLog'

class ChatRoom < ModelMaster
  def self.getListRoom (uid = nil, getRevoked = false)
    retval = Array.new
    reterr = nil
    begin
      mysqlClient = getMysqlClient
      uidEsc = mysqlClient.escape(uid) unless uid.nil?
      queryStr = " select id, rname, isRevoked+0 as isr from chatRooms "
      if !(uid.nil?) or !getRevoked
        queryStr += " where "
        tmparr = Array.new
        tmparr.push(" uid = '#{uidEsc}' ") unless uid.nil?
        tmparr.push(" (isRevoked+0)=0 ") unless getRevoked
        queryStr += tmparr.join(",")
      end
      queryStr += " order by id asc "
      rsltset = mysqlClient.query(queryStr)
      rsltset.each do |row|
        tmp = Hash.new
        tmp[:rname] = row["rname"].to_s
        tmp[:rid] = row["id"].to_s
        tmp[:isr] = row["isr"].to_s
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

  def self.updateRoom(rid, rname, curpwd, newpwd, uid)
    retval = false
    reterr = nil
    lrid = (rid.nil? ? "" : rid)
    lrname = (rname.nil? ? "" : rname)
    lcurpwd = (curpwd.nil? ? "" : curpwd)
    luid = (uid.nil? ? "" : uid)
    if lrname.empty? and newpwd.nil? and luid.empty?
      reterr = "更新される項目がありません。"
    else
      begin
        mysqlClient = getMysqlClient
        ridEsc = (lrid.empty? ? "" : mysqlClient.escape(lrid))
        nameEsc = (lrname.empty? ? "" : mysqlClient.escape(lrname))
        npwdEsc = (newpwd.nil? or newpwd.empty? ? ""
                   : mysqlClient.escape(HtmlUtil.digestPassword newpwd))
        cpwdEsc = (lcurpwd.empty? ? ""
                   : mysqlClient.escape(HtmlUtil.digestPassword lcurpwd))
        uidEsc = (luid.empty? ? "" : mysqlClient.escape(uid))
        
        setName = (lrname=="" ? "" : " rname = '#{nameEsc}' ")
        setpwd = (newpwd.nil? ? ""
                  : (newpwd.empty? ? " password = null "
                     : " password = '#{npwdEsc}' "))
        setuid = (luid=="" ? "" : " uid = '#{uidEsc}' ")
        setValues =
          [setName, setpwd, setuid].compact.reject(&:empty?).join(',')
        queryStr = <<-SQL
          update chatRooms
             set #{setValues}
           where id = '#{ridEsc}'
        SQL
        queryStr += " and password = '#{cpwdEsc}' " unless cpwdEsc.empty?
        mysqlClient.query(queryStr)
        retval = true
      rescue Mysql2::Error => e
        retval = false
        reterr = e.message
      ensure
        mysqlClient.close
      end
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

  def self.getRoomname(rid)
    retval = ""
    iserr = false
    if rid.nil? or rid.empty?
      iserr = true
      retval = "ridを指定してください。"
    else
      begin
        mysqlClient = getMysqlClient
        ridEsc = mysqlClient.escape(rid)
        queryStr = <<-SQL
          select rname from chatRooms
           where id = '#{ridEsc}'
        SQL
        rsltSet = mysqlClient.query(queryStr)
        rsltSet.each do |row|
          retval = row["rname"].to_s
        end
      rescue Mysql2::Error => e
        iserr = true
        retval = e.message
      ensure
        mysqlClient.close
      end
    end
    return retval, iserr
  end

  def self.deleteRoom(rid,pwd,flg=false)
    retval = false
    reterr = nil
    if rid.nil? or rid.empty?
      reterr = "ridを指定してください。"
    else
      isAuth,tmperr = loginRoom(rid,pwd)
      if !isAuth
        reterr = "ルームの認証に失敗しました。"
        reterr += "(" + tmperr + ")" unless tmperr.nil?
      else
        begin
          mysqlClient = getMysqlClient
          ridEsc = mysqlClient.escape(rid)
          pwdEsc = (pwd.nil? ? "" : pwd)
          pwdEsc =
            mysqlClient.escape(HtmlUtil.digestPassword pwdEsc) unless pwd==""
          queryStr = <<-SQL
            update chatRooms set isRevoked = b'1'
             where id = '#{ridEsc}'
          SQL
          queryStr += " and password " +
            (pwdEsc=="" ? "is null" : "= '#{pwdEsc}'")
          mysqlClient.query(queryStr)
          if flg
            retval,tmperr = ChatLog.removeLogs(rid)
            reterr += "/" + tmperr unless tmperr.nil?
          else
            retval = true
          end
        rescue Mysql2::Error => e
          reterr = e.message
        ensure
          mysqlClient.close
        end # begin
      end # !isAuth
    end # rid.nil? or rid.empty?
    return retval, reterr
  end
end
