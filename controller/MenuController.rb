# encoding: utf-8
# Menu Controller
require_relative '../util/HtmlUtil'
require_relative '../model/CgiUser'
require 'erb'
require 'pathname'

class MenuController
  def index session,args
    @viewName = "メニュー画面" if @viewName.nil?
    @menuList = HtmlUtil.getMenuList(HtmlUtil.getMenuUrl) if @menuList.nil?

    @contents = "" if @contents.nil?

    form = Pathname("view/Menu.html.erb").read(:encoding => Encoding::UTF_8)
    return (ERB.new(form).result(binding)), false, ""
  end

  def person session,args
    @viewName = "自分の管理画面"
    mainUrl = HtmlUtil.getMainUrl

    @menuList = HtmlUtil.getMenuList(HtmlUtil.getMenuUrl("person"))
    formaction = HtmlUtil.getMenuUrl("updateperson")
    uid = session[HtmlUtil::LOGINID]
    dispName = session[HtmlUtil::LOGINNAME]

    @contents = ERB.new(Pathname("view/Menu_person.html.erb").
      read(:encoding => Encoding::UTF_8)).result(binding)

    index session, args
  end

  def updateperson session,args
    # input check
    uid = session[HtmlUtil::LOGINID]
    dispnmcur = session[HtmlUtil::LOGINNAME]

    newpwdchk = args[0]["pwdchk"][0]
    newpwd = args[0]["newpwd"][0]
    newpwdcf = args[0]["cfnewpwd"][0]

    dispnmchk = args[0]["dispnmcheck"][0]
    dispnm = args[0]["newdispnm"][0]

    curpwd = args[0]["curpwd"][0]

    checked = true
    errmsg = Array.new

    ## user auth check with uid, password
    if !(CgiUser.authUser(uid, curpwd))
      checked = false
      errmsg.push("現在のパスワードが間違っています。")
    end
    ## check newpwd & newpwdcf & curpwd
    if newpwdchk=="checked"
      if newpwd == curpwd
        errmsg.push("新しいパスワードは現在のパスワードと異なるものを設定してください")
      end
      if newpwd != newpwdcf
        errmsg.push("新パスワードと確認用パスワードが異なります。")
      end
    end
    ## check dispnm duplication
    if dispnmchk == "checked"
      
    end
    # update database

    # redirect to person
    ## if something error, display error(instance variable) and call person

  end

  def room session,args
    @viewName = "ルームの管理画面"
    mainUrl = HtmlUtil.getMainUrl

    @menuList = HtmlUtil.getMenuList(HtmlUtil.getMenuUrl("room"))

    @contents = ERB.new(Pathname("view/Menu_room.html.erb").
      read(:encoding => Encoding::UTF_8)).result(binding)

    index session, args
  end

end
