# -*- coding: utf-8 -*-
# encording: utf-8
# cgiUsers model
require_relative '../util/HtmlUtil'
require_relative './ModelMaster'

class CgiUser < ModelMaster
  UIDLENGTH=8
  NAMELENGTH=20

  def self.updateUser(curuid,upuid="",upname="",uppass="")
    begin
      if (upuid == "" and upname == "" and uppass == "")
        return false, "UID, name, passいずれかに更新値を入力してください。"
      end
      mysqlClient = getMysqlClient
      curuidEscaped = mysqlClient.escape(curuid)
      upuidEscaped = mysqlClient.escape(upuid) unless upuid == ""
      upnameEscaped = mysqlClient.escape(upname) unless upname == ""
      uppassEscaped = mysqlClient.escape(HtmlUtil.digestPassword uppass) unless uppass == ""

      queryStr = "update cgiUsers set"
      tmpArr = []
      tmpArr.push(" uid = '#{upuidEscaped}' ") unless upuid == ""
      tmpArr.push(" name = '#{upnameEscaped}' ") unless upname == ""
      tmpArr.push(" password = '#{uppassEscaped}' ") unless uppass == ""
      queryStr += tmpArr.join(",")
      queryStr += " where uid = '#{curuidEscaped}' "

      mysqlClient.query(queryStr)
      return true, ""
    rescue Mysql2::Error => e
      return false, e.message
    ensure
      mysqlClient.close unless mysqlClient.nil?
    end
  end

  def self.getUser(uid)
    begin
      mysqlClient = getMysqlClient
      uidEscaped = mysqlClient.escape(uid)
      queryStr = <<-QUERY
        select uid, name, isadmin
        from cgiUsers
        where uid = '#{uidEscaped}'
      QUERY
      rsltset = mysqlClient.query(queryStr)
      retUid = ""
      retName = ""
      retIsAdm = false
      rsltset.each do |row|
        retUid = row["uid"]
        retName = row["name"]
        retIsAdm = (row["isadmin"] == 1)
      end
      return retName,retIsAdm
    rescue Mysql2::Error => e
      return "",false
    ensure
      mysqlClient.close
    end
  end

  def self.authUser(uid, pass)
    begin
      mysqlClient = getMysqlClient
      uidEscaped = mysqlClient.escape(uid)
      passEscaped = mysqlClient.escape(HtmlUtil.digestPassword pass)
      queryStr = <<-QUERY
        select uid, password, name, isadmin
        from cgiUsers
        where uid = '#{uidEscaped}' and password = '#{passEscaped}'
      QUERY
      rsltset = mysqlClient.query(queryStr)
      isAuth = rsltset.count != 0
      retUid = ""
      retName = ""
      retIsAdm = false
      rsltset.each do |row|
        retUid = row["uid"]
        retName = row["name"]
        retIsAdm = (row["isadmin"] == 1)
      end
      return isAuth,retUid,retName,retIsAdm
    rescue Mysql2::Error => e
      return false,"","",false
    ensure
      mysqlClient.close
    end
  end

  def self.getOnetimeHash(uid)
    oth = HtmlUtil.makeRandomDigest
    begin
      mysqlClient = getMysqlClient
      uidEscaped = mysqlClient.escape(uid)
      queryStr = <<-SQL
        update cgiUsers
           set oneTimeHash = '#{oth}'
         where uid = '#{uidEscaped}'
      SQL
      mysqlClient.query(queryStr)
    rescue Mysql2::Error => e
      return ""
    ensure
      mysqlClient.close
    end
    return oth
  end

  def self.checkOnetimeHash(uid, oth)
    retval = false
    begin
      mysqlClient = getMysqlClient
      uidEscaped = mysqlClient.escape(uid)
      othEscaped = mysqlClient.escape(oth)
      queryStr = <<-SQL
        select * from cgiUsers
         where uid = '#{uidEscaped}' and oneTimeHash = '#{othEscaped}'
      SQL
      rsltSet = mysqlClient.query(queryStr)
      if rsltSet.count != 0
        upStr = <<-SQL
          update cgiUsers
             set oneTimeHash = null
           where uid = '#{uidEscaped}'
        SQL
        mysqlClient.query(upStr)
        retval =  true
      end
    rescue Mysql2::Error => e
      retval = false
    ensure
      mysqlClient.close
    end
    return retval
  end

  def self.checkDuplicateName(name)
    retval = false # if not exist duplicat name, return true
    begin
      mysqlClient = getMysqlClient
      nameEsc = mysqlClient.escape(name)
      queryStr = <<-SQL
        select count(*) as counts from cgiUsers
         where name = '#{nameEsc}'
      SQL
      rsltSet = mysqlClient.query(queryStr)
      rsltSet.each do |row|
        retval = (row["counts"] == 0)
      end
      return {:isUnique => retval, :err => ""}
    rescue Mysql2::Error => e
      return {:isUnique => retval, :err => e.message}
    ensure
      mysqlClient.close
    end
  end
end
