# -*- coding: utf-8 -*-
require 'rubygems'
require 'em-websocket'
require 'digest/sha2'
require 'uri'
require_relative '../util/HtmlUtil'
require_relative '../model/CgiUser'
require_relative '../model/ChatLog'

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
    sendmsg = "[" + @uname + "](" + getDateText + ") " + msg
    @@connected_clients.each_value { |c| c.send(sendmsg) }
    outputLog sendmsg
    isSucc, errmsg = ChatLog.insertLog(@loginName, msg)
    outputLog errmsg unless isSucc
  end

  # ログイン処理
  def login(login,userhash,username,isnewroom,roomname,roompwd)
    retval = false
    retmsg = nil
    if CgiUser.checkOnetimeHash(login,userhash)
      if @@connected_clients.has_key?(login) == false
        # ChatRoom.createRoom if isnewroom
        # ChatRoom.loginRoom unless isnewroom

        @loginName = login
        @uname, tmpIsAdm = CgiUser.getUser(login)
        @@connected_clients[@loginName] = self
        outputLog "Login name is #{@loginName}"
        retval = true
      else
        retmsg = "同IDで既にログインしている人がいます。"
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
      @@connected_clients.delete(@loginName)
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
    msg = "Welcome!" if isLoginComplete

    ws.send(msg)
    ws.sendBroadcast("Welcome [#{username}] !") if isLoginComplete
    ws.close unless isLoginComplete
  }

  ws.onmessage { |msg|
    return if msg.strip.size < 1
    ws.sendBroadcast(msg)
  }
  
  ws.onclose{
    ws.logout
  }
  
  ws.onerror{ |e|
    ws.logout
    outputLog "Error: #{e.message}"
  }
}
