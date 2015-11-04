# encoding: utf-8
# Menu Controller
require_relative '../util/HtmlUtil'
require_relative '../model/CgiUser'
require 'erb'
require 'pathname'

class MenuController
  PERSONERR = "person.err"
  ROOMERR = "room.err"

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

    personerr = session[PERSONERR]
    session[PERSONERR] = nil

    @contents = ERB.new(Pathname("view/Menu_person.html.erb").
      read(:encoding => Encoding::UTF_8)).result(binding)

    index session, args
  end

  def updateperson session,args
    # input check
    uid = session[HtmlUtil::LOGINID]
    dispnmcur = session[HtmlUtil::LOGINNAME]

    newpwdchk = args[0]["pwdcheck"][0]
    newpwd = args[0]["newpwd"][0]
    newpwdcf = args[0]["cfnewpwd"][0]

    dispnmchk = args[0]["dispnmcheck"][0]
    dispnm = args[0]["newdispnm"][0]

    curpwd = args[0]["curpwd"][0]

    checked = false # if check OK, true
    errmsg = Array.new

    ## user auth check with uid, password
    isAuth,retUid,retName,retIsAdm = CgiUser.authUser(uid, curpwd)
    errmsg.push("現在のパスワードが間違っています。") unless isAuth

    errmsg.push("更新する項目に" +
                "チェックを入れてください。") if
      newpwdchk != "on" and dispnmchk != "on"

    ## check newpwd & newpwdcf & curpwd
    if newpwdchk=="on"
      errmsg.push("新しいパスワードは現在のパスワードと" +
                  "異なるものを設定してください") if newpwd == curpwd
      errmsg.push("新パスワードと確認用パスワードが" +
                  "異なります。") if newpwd != newpwdcf
    end

    ## check dispnm duplication
    if dispnmchk == "on"
      chkDup = CgiUser.checkDuplicateName(dispnm)
      errmsg.push chkDup[:err] unless chkDup[:err].empty?
      errmsg.push "同じ表示名が既に登録されています。(" +
        dispnm + ")" unless chkDup[:isUnique]
    end

    if errmsg.count == 0
      # update database
      issucc,strerr =
        CgiUser.updateUser(uid,"",
                           (dispnmchk=="on" ? dispnm : ""),
                           (newpwdchk=="on" ? newpwd : "") )
      unless issucc
        # session[PERSONERR] = "<ul><li>" + strerr + "</li></ul>"
        session[PERSONERR] = HtmlUtil.arrToHtmlList([strerr],false)
      else
        # session[PERSONERR] = "<ul><li>正常に更新されました。</li><ul>"
        session[PERSONERR] =
          HtmlUtil.arrToHtmlList(["正常に更新されました。"],false)
        session[HtmlUtil::LOGINNAME] = dispnm if dispnmchk=="on"
      end
    else
      # redirect to person
      session[PERSONERR] = HtmlUtil.arrToHtmlList(errmsg, false)
    end
    return "",true,(HtmlUtil.getMenuUrl("person"))
  end

  def room session,args
    @viewName = "ルームの管理画面"
    mainUrl = HtmlUtil.getMainUrl
    @menuList = HtmlUtil.getMenuList(HtmlUtil.getMenuUrl("room"))

    formaction = HtmlUtil.getMenuUrl("updateroom")

    rid = args[0]["rid"][0]
    uid = session[HtmlUtil::LOGINID]
    roomSel,iserr = HtmlUtil.getRoomSel(rid,uid,true)

    retrname,iserr2 = ((!rid.nil? && !rid.empty?) ? ChatRoom.getRoomname(rid)
                      : ["",false])
    rname = (iserr2 ? "" : retrname)

    ownerSel = HtmlUtil.getUserSel(uid)

    roomerr = session[ROOMERR]
    session[ROOMERR] = nil

    @contents = ERB.new(Pathname("view/Menu_room.html.erb").
      read(:encoding => Encoding::UTF_8)).result(binding)

    index session, args
  end

  def updateroom session,args
    # return variables
    isRedirect = true
    redirectUri = HtmlUtil.getMenuUrl("room")

    # input check
    uid = session[HtmlUtil::LOGINID]

    rid = args[0]["selectroom"][0]
    isRdoUpd = args[0]["room"][0] # "update" or "delete"

    chkRoomName = args[0]["chkrname"][0]
    txtRoomName = args[0]["rname"][0]
    chkRoomOwn = args[0]["chkrown"][0]
    selRoomOwn = args[0]["selectowner"][0]
    chkNewPwd = args[0]["chknewpwd"][0]
    txtNewPwd = args[0]["newpwd"][0]
    txtConfirmNewPwd = args[0]["cfnewpwd"][0]

    chkDelLog = args[0]["chkdellog"][0]

    txtCurPwd = args[0]["curpwd"][0]

    err = Array.new

    # check login to room
    loginRetval, loginReterr = ChatRoom.loginRoom(rid, txtCurPwd)
    unless loginRetval
      err.push("ルーム認証に失敗しました。")
      err.push(loginReterr)
    else
      if isRdoUpd == "update"
        # for update
        argrname = (chkRoomName == "on" ? txtRoomName : nil)
        argrown = (chkRoomOwn == "on" ? selRoomOwn : nil)
        if chkNewPwd == "on" and txtNewPwd != txtConfirmNewPwd
          err.push("新パスワードが一致しません。")
        else
          argpwd = (chkNewPwd == "on" ? txtNewPwd : nil)
          updretval, updreterr =
            ChatRoom.updateRoom(rid, argrname, txtCurPwd,
                                argpwd, argrown)
          err.push(updreterr) unless updretval
        end
      elsif isRdoUpd == "delete"
        # for delete
        delretval, delreterr =
          ChatRoom.deleteRoom(rid, txtCurPwd, (chkDelLog=="on"))
        err.push(delreterr) unless delretval
      else
        # error case (invalid radio button value)
        err.push("ラジオボタンを選択してください。")
      end
    end

    if err.count > 0
      session[ROOMERR] = HtmlUtil.arrToHtmlList(err, false)
    else
      session[ROOMERR] =
        HtmlUtil.arrToHtmlList(["正常に" +
                                (isRdoUpd=="update" ? "更新" : "削除")+
                                "されました。"], false)
    end

    return "", isRedirect, redirectUri
  end

end
