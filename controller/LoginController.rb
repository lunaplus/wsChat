# encoding: utf-8
# Login Controller
require_relative '../model/CgiUser'
require_relative '../util/HtmlUtil'
require 'erb'

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
      redirectLocation += "/menu"
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
    form = <<-HTML
  <p>
    <h2>ログイン画面</h2>
    <form action="<%= actionUrl %>" method="post" accept-charset="UTF-8"
          autocomplete="off" name="login">
      <input type="text" name="uid" size="10" maxlength="8" required><br>
      <input type="password" name="password" size="10" autocomplete="off" required>
      <br>
      <input type="submit">
    </form>
  </p>
  <% if errMsg %>
  <p style='color: red'><%= errMsg %></p>
  <% end %>
HTML
    return (ERB.new(form).result(binding)), false, ""
  end

  def initSession session
    session[HtmlUtil::LOGINID] = ""
    session[HtmlUtil::LOGINNAME] = ""
    session[HtmlUtil::ISADMIN] = false
  end
end
