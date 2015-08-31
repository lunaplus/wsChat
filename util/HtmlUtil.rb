# -*- coding: utf-8 -*-
# CGI Initialize class
require 'date'

class HtmlUtil
  LOGINID = "loginid"
  LOGINNAME = "loginname"
  ISADMIN = "isAdmin"

  TEMPPASS = "tempPass"
  TEMPNAME = "tempName"
  TEMPUID  = "tempUid"
  TEMPINPUTERR = "tempInputErr"
  TEMPINPUTFROM = "tempInputFrom"
  TEMPINPUTTO = "tempInputTo"

  LoginCtrlName = "login"
  MenuCtrlName = "menu"

  def self.htmlHeader
    ret = <<-HTML
<!DOCTYPE html>
<html>
  <head>
    <meta charset-='UTF-8'>
  </head>
  <body>
    HTML
    return ret
  end

  def self.initCgi
    return {"charset" => "UTF-8", "status" => "OK"}
  end

  def self.getJavascriptTags
    jquerypath = getUrlRoot + "/js/jquery-2.1.1.min.js"
    jspath = getUrlRoot + "/js/common.js"
    ret = <<-HTML
  <script type="text/javascript" src="#{jquerypath}"></script>
  <script type="text/javascript" src="#{jspath}"></script>
    HTML
    return ret
  end

  def self.htmlFooter
    ret = <<-HTML
</body></html>
    HTML
    return ret
  end

  def self.htmlRedirect cgi,url
    ret = cgi.header( { "status" => "REDIRECT", "Location" => url } )
    ret += <<-HTML
  <html>
    <head>
      <meta http-equiv="refresh" content"0;url=#{url}">
    </head>
    <body>
      wait...
    </body>
  </html>
    HTML
    return ret
  end

  def self.digestPassword s
    return Digest::SHA256.hexdigest(s)
  end

  def self.getUrlRoot
    if ENV['HTTPS'] == "on"
      urlRoot = "https://"
    else
      urlRoot = "http://"
    end

    urlRoot += ENV['HTTP_HOST'] + "/cgi"
  end

  def self.getMenuUrl
    return (createUrl MenuCtrlName,"index")
  end

  def self.createUrl ctrl,act="",arg=nil
    ret = getUrlRoot + "/" + ctrl
    ret += "/" + act unless act == ""
    ret += "/" + (arg.join("/")) unless arg == nil or arg.size < 1
    return ret
  end

  def self.createSelBox val,text
    return "<option value=\"#{val}\">#{text}</option>\n"
  end

  def self.createYearSel selname,year=0
    # year sel : 入力日とその前後1年分の年数を表示する。デフォルトは当年。
    today = Time.now
    defyear = today.year
    defyear = year if year!=0 and (defyear-1)<=year and year<=(defyear+1)
    return <<-HTML
        <select name="#{selname}">
          <option value="#{today.year-1}">#{today.year-1}</option>
          <option value="#{today.year}" selected>#{today.year}</option>
          <option value="#{today.year+1}">#{today.year+1}</option>
        </select>
    HTML
    end
  def self.createMonthSel selname,df=-1
    # month sel : 12ヶ月分全部表示する。デフォルトは当月
    today = Time.now
    defaultSel = df
    defaultSel = today.month if df < 1 or df > 12

    monthSel = "<select name=\"#{selname}\">\n"
    1.upto(12) do |i|
      monthSel += "<option value=\"#{i}\""
      monthSel += " selected" if i == defaultSel
      monthSel += ">#{i}</option>\n"
    end
    monthSel += "</select>\n"
    return monthSel
  end

  def self.createDateSel selname,df=-1
    # date sel : 31日分全部表示する。デフォルトは当日
    today = Time.now
    defaultSel = df
    defaultSel = today.day if df < 1 or df > 31

    dateSel =  "<select name=\"#{selname}\">\n"
    1.upto(31) do |i|
      dateSel += "<option value=\"#{i}\""
      dateSel += " selected" if i == defaultSel
      dateSel += ">#{i}</option>\n"
    end
    dateSel += "</select>\n"
    return dateSel
  end

  def self.createDate y,m,d
    return Date.new(y,m,d)
  end

  def self.createDateTime y,m,d,h=0,mi=0,s=0
    return DateTime.new(y,m,d,h,mi,s,Rational(9,24))
  end

  def self.getToday
    return DateTime.now
  end

  def self.fmtDateTime datetime
    #return (datetime-Rational(9,24)).strftime("%Y-%m-%d %H:%M:%S")
    return datetime.strftime("%Y-%m-%d %H:%M:%S")
  end

  def self.fmtDate date
    return date.to_s
  end

  def self.parseDateTime date
    return (date+Rational(9,24))
    # return ((DateTime.strptime(date, "%Y-%m-%d %H:%M:%S"))+Rational(9,24))
  end

  def self.parseDate str
    return Date.parse(str, "%Y-%m-%d")
  end
end

class Integer
  def to_currency()
    self.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\1,').reverse
  end
end
