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
        return false
      end
      mysqlClient = getMysqlClient
      curuidEscaped = mysqlClient.escape(curuid)
      upuidEscaped = mysqlClient.escape(upuid) unless upuid == ""
      upnameEscaped = mysqlClient.escape(upname) unless upname == ""
      uppassEscaped = mysqlClient.escape(HtmlUtil.digestPassword uppass) unless uppass == ""

      queryStr = "update cgiusers set"
      tmpArr = []
      tmpArr.push(" uid = '#{upuidEscaped}' ") unless upuid == ""
      tmpArr.push(" name = '#{upnameEscaped}' ") unless upname == ""
      tmpArr.push(" password = '#{uppassEscaped}' ") unless uppass == ""
      queryStr += tmpArr.join(",")
      queryStr += " where uid = '#{curuidEscaped}' "

      mysqlClient.query(queryStr)
      return true
    rescue Mysql2::Error => e
      return false
    end
  end

  def self.getUser(uid)
    begin
      mysqlClient = getMysqlClient
      uidEscaped = mysqlClient.escape(uid)
      queryStr = <<-QUERY
        select uid, name, isadmin
        from cgiusers
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
    end
  end

  def self.authUser(uid, pass)
    begin
      mysqlClient = getMysqlClient
      uidEscaped = mysqlClient.escape(uid)
      passEscaped = mysqlClient.escape(HtmlUtil.digestPassword pass)
      queryStr = <<-QUERY
        select uid, password, name, isadmin
        from cgiusers
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
    end
  end

end
