# encoding: utf-8
# Menu Controller
require_relative '../util/HtmlUtil'
require_relative '../model/ChatLog'
require 'erb'
require 'pathname'
require 'uri'

class HistoryController
  def index session,args
    splitCount = 15

    fromNum = (args[0]["from"][0]).to_i
    rid = args[0]["selectroom"][0].to_s
    prevroom = args[0]["prevroom"][0].to_s
    rpwd = args[0]["roompass"][0].to_s

    rpwd = session["roompass"] if prevroom == rid
    session["roompass"] = nil

    formaction = HtmlUtil.getHistoryUrl
    roomSel,iserr = HtmlUtil.getRoomSel rid
    rprev = 0

    menuList = HtmlUtil.getMenuList(HtmlUtil.getHistoryUrl)

    strErr = ""
    if !(iserr.nil?) or rid.empty?
      # getRoomSelでエラーが発生したか、ルーム選択がされていない場合
      strErr = iserr unless iserr.nil?
    else
      islogin, iserr = ChatRoom.loginRoom(rid, rpwd)
      if !islogin
        # login failed
        strErr = "ルームの認証ができませんでした" +
          (iserr.nil? ? "" : "(" + iserr + ")")
      else
        session["roompass"] = rpwd
        rprev = rid
        logcounts,strErr = ChatLog.getLogCounts(rid)

        if strErr.nil?
          existPrev = fromNum != 0
          existNext = (fromNum + splitCount) < logcounts

          prevUrl = HtmlUtil.getHistoryUrl + "?from=" +
            (existPrev and fromNum > splitCount ?
             fromNum - splitCount : 0).to_s +
            "&selectroom=" + rid + "&prevroom=" + rid
          nextUrl = HtmlUtil.getHistoryUrl + "?from=" +
            (fromNum + splitCount).to_s +
            "&selectroom=" + rid + "&prevroom=" + rid

          logArr = ChatLog.getLogs(fromNum, splitCount, rid)
          logStr = "<ul>"
          logArr.each do |elm|
            tmpStr = "<li>"
            if elm[:err] == ""
              tmpStr += HtmlUtil.esc(elm[:rname].to_s) +
                " / " unless (elm[:rname].to_s).empty?
              tmpStr += "[" + HtmlUtil.esc(elm[:name].to_s) + "]"
              tmpStr += " (" +
                HtmlUtil.esc(HtmlUtil.fmtDateTime(elm[:sentDate])) + ") "
              tmpStr += HtmlUtil.esc(elm[:message].to_s)
            else
              tmpStr += "!!! " + elm[:err].to_s + " !!!"
            end
            tmpStr += "</li>"
            logStr += tmpStr
          end # logArr.each do
          logStr += "</ul>"
        end # strErr.nil?
      end # !islogin
    end # iserr.nil? or rid.nil?

    form = Pathname("view/History.html.erb").read(:encoding => Encoding::UTF_8)
    return (ERB.new(form).result(binding)), false, ""
  end
end
