# encoding: utf-8
# Menu Controller
require_relative '../util/HtmlUtil'
require_relative '../model/CgiUser'
require_relative '../model/ChatLog'
require_relative '../model/ChatRoom'
require 'erb'
require 'pathname'

class MainController
  def index session,args
    login = session[HtmlUtil::LOGINID]
    username = session[HtmlUtil::LOGINNAME]
    showname = username + "(" + login + ")"
    userhash = CgiUser.getOnetimeHash(login)
    histUrl = HtmlUtil.getHistoryUrl

    # 過去ログ表示
    initViewLogs = 10
    histArr = ChatLog.getLogs(0, initViewLogs)
    histHtml = ""
    histArr.each do |elm|
      if elm[:err] != ""
        histHtml = HtmlUtil.esc(elm[:err])
        break
      end
      histHtml += "<li>"
      histHtml += "[" + HtmlUtil.esc(elm[:name].to_s) + "]"
      histHtml += "(" + HtmlUtil.fmtDateTime(elm[:sentDate]) + ")"
      histHtml += HtmlUtil.esc(elm[:message].to_s)
      histHtml += "</li>"
    end

    # 既存ルーム一覧
    roomSel, iserr = HtmlUtil.getRoomSel
    
    form = Pathname("view/Main.html.erb").read(:encoding => Encoding::UTF_8)
    return (ERB.new(form).result(binding)), false, ""
  end
end
