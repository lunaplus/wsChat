# encoding: utf-8
# Login Controller
require_relative '../model/CgiUser'
require_relative '../util/HtmlUtil'
require 'erb'
require 'pathname'

class LoginController
  def index session,args
    initSession session
    return getLoginForm ""
  end

  def auth session,args
    initSession session
    form = ""
    isRedirect = false
    redirectLocation = HtmlUtil.getUrlRoot
    
    isAuth,uid,name,isAdm = CgiUser::authUser(args[0]["uid"][0],
                                              args[0]["password"][0])
    if (isAuth)
      form = ""
      isRedirect = true
      redirectLocation += "/main"
      session[HtmlUtil::LOGINID] = uid
      session[HtmlUtil::LOGINNAME] = name
      session[HtmlUtil::ISADMIN] = isAdm
    else
      form, isRedirect, redirectLocation =
        getLoginForm "IDまたはパスワードが不正です。"
    end
    return form,isRedirect,redirectLocation
  end

  def getLoginForm errMsg
    actionUrl = HtmlUtil.createUrl "login","auth"
    form = Pathname("view/Login.html.erb").read(:encoding => Encoding::UTF_8)
    return (ERB.new(form).result(binding)), false, ""
  end

  def initSession session
    session[HtmlUtil::LOGINID] = ""
    session[HtmlUtil::LOGINNAME] = ""
    session[HtmlUtil::ISADMIN] = false
  end
end
