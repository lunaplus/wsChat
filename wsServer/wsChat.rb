# -*- coding: utf-8 -*-
require 'rubygems'
require 'em-websocket'
require 'digest/sha2'
require 'uri'
require_relative '../util/HtmlUtil'
require_relative '../model/CgiUser'
require_relative '../model/ChatLog'
require_relative '../model/ChatRoom'

Process.daemon(true, true)

# チャット用モジュール ユーザー管理を追加
module ChatModule
  
  # ユーザー管理
  @@connected_clients = Hash.new

  # logging
  @@logfile = File.open("log/wsChat.log", "a")
  def outputLog str
    @@logfile.sync = true
    @@logfile.puts str
  end

  # 接続ユーザー全員にメッセージを送る
  def sendBroadcast(msg)
    return if msg.empty?
    sendmsg = HtmlUtil.esc("[" + @uname + "](" + getDateText + ") " + msg)
    @@connected_clients[@roomid].each_value { |c| c.send(sendmsg) }
    outputLog sendmsg
    isSucc, errmsg = ChatLog.insertLog(@loginName, msg, @roomid)
    outputLog errmsg unless isSucc and !(errmsg.nil?)
  end

  # ログイン処理
  def login(login,userhash,username,isnewroom,roomname,roompwd)
    retval = false
    retmsg = nil
    if CgiUser.checkOnetimeHash(login,userhash)
      tmpretval = false
      roomid = nil
      tmpretval,retmsg,roomid = ChatRoom.createRoom(roomname, roompwd,
                                                    login) if isnewroom
      roomid = roomname unless isnewroom
      if !isnewroom or (isnewroom and tmpretval)
        tmpretval,retmsg = ChatRoom.loginRoom(roomid, roompwd)

        if tmpretval
          @roomid = roomid
          @@connected_clients[@roomid] = Hash.new unless @@connected_clients.has_key?(roomid)

          if @@connected_clients[@roomid].has_key?(login) == false
            @loginName = login
            @uname, tmpIsAdm = CgiUser.getUser(login)
            
            (@@connected_clients[@roomid])[@loginName] = self
            outputLog "Login name is #{@loginName}"
            retval = true
          else
            retmsg = "同IDで既にログインしている人がいます。"
          end
        else
          retmsg = "指定したルームに入室できません(" + retmsg + ")" unless retmsg.nil?
          retmsg = "指定したルームに入室できません" if retmsg.nil?
        end
      else
        retmsg = "ルームの作成に失敗しました(" + retmsg + ")" unless retmsg.nil?
        retmsg = "ルームの作成に失敗しました" if retmsg.nil?
      end
    else
      retmsg = "ワンタイムパスが一致しません。正しいURLからログインしてください。"
    end
    return retval, retmsg
  end

  #ログアウト処理
  def logout()
    if @loginName && @loginName.empty? == false
      msg = "[#{@uname}] is logout."
      outputLog msg
      @@connected_clients[@roomid].delete(@loginName)
      sendBroadcast(msg);
    end
    outputLog ("WebSocket closed(" + (@loginName.nil? ? "":@loginName) + ")")
  end

  def getDateText
    return HtmlUtil.fmtTime(HtmlUtil.getToday)
  end
end

EM::WebSocket.start(:host => "localhost", :port => 23456) { |ws|
  ws.extend(ChatModule)

  ws.onopen{ |hs|
    # query string proc
    loginid = URI.decode_www_form_component(hs.query["login"]) rescue ""
    userhash = URI.decode_www_form_component(hs.query["userhash"]) rescue ""
    username = URI.decode_www_form_component(hs.query["username"]) rescue ""
    isnewroom = (URI.decode_www_form_component(hs.query["newroom"]) == "true") rescue false
    roomname = URI.decode_www_form_component(hs.query["roomname"]) rescue ""
    roompwd = URI.decode_www_form_component(hs.query["roompwd"]) rescue ""

    # login check
    isLoginComplete, msg = ws.login(loginid,userhash,username,isnewroom,
                                    roomname,roompwd)
    if isLoginComplete
      initViewLogs = 10
      rid = nil
      rid = roomname unless isnewroom
      histArr = ChatLog.getLogs(1,initViewLogs, rid)
      histArr.reverse_each do |elm|
        if elm[:err] != ""
          histHtml = HtmlUtil.esc(elm[:err])
        else
          histHtml = ""
          histHtml += "[" + HtmlUtil.esc(elm[:name].to_s) + "]"
          histHtml += "(" + HtmlUtil.fmtDateTime(elm[:sentDate]) + ")"
          histHtml += HtmlUtil.esc(elm[:message].to_s)
        end
        ws.send(histHtml)
      end
      ws.sendBroadcast("Welcome [#{username}] !")
    else
      ws.outputLog msg
      ws.send msg
      ws.close
    end
  }

  ws.onmessage { |msg|
    return if msg.strip.size < 1
    ws.sendBroadcast(msg)
  }
  
  ws.onclose{
    ws.logout
  }
  
  ws.onerror{ |e|
    ws.outputLog "Error: #{e.message} / " + e.backtrace.inspect
    ws.logout
  }
}
