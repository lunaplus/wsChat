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

    menuList = HtmlUtil.getMenuList(HtmlUtil.getMainUrl)

    # 既存ルーム一覧
    roomSel, iserr = HtmlUtil.getRoomSel
    
    form = Pathname("view/Main.html.erb").read(:encoding => Encoding::UTF_8)
    return (ERB.new(form).result(binding)), false, ""
  end
end
