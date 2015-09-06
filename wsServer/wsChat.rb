# -*- coding: utf-8 -*-
require 'rubygems'
require 'em-websocket'
require 'digest/sha2'
require 'uri'
require_relative '../util/HtmlUtil'
require_relative '../model/CgiUser'
require_relative '../model/ChatLog'

# チャット用モジュール ユーザー管理を追加
module ChatModule
  
  # ユーザー管理
  @@connected_clients = Hash.new

  # 接続ユーザー全員にメッセージを送る
  def sendBroadcast(msg)
    return if msg.empty?
    sendmsg = "(" + getDateText + ") " + msg
    @@connected_clients.each_value { |c| c.send(sendmsg) }
    puts sendmsg
    isSucc, errmsg = ChatLog.insertLog(@loginName, msg)
    puts errmsg unless isSucc
  end

  # ログイン処理
  def login(login,userhash,username)
    if CgiUser.checkOnetimeHash(login,userhash)
      if @@connected_clients.has_key?(login) == false
        @loginName = login
        @@connected_clients[@loginName] = self
        puts "Login name is #{@loginName}"
        return true
      else
        return false
      end
    else
      return false
    end
  end

  #ログアウト処理
  def logout()
    if @loginName && @loginName.empty? == false
      msg = "[#{@loginName}] is logout."
      puts msg
      @@connected_clients.delete(@loginName)
      @@connected_clients.each_value { |c| c.send(msg) }
    end
    puts "WebSocket closed"
  end

  def getDateText
    return HtmlUtil.fmtDateTime(HtmlUtil.getToday)
  end
end

EM::WebSocket.start(:host => "localhost", :port => 3000) { |ws|
  ws.extend(ChatModule)

  ws.onopen{ |hs|
    loginid = URI.decode_www_form_component(hs.query["login"]) rescue ""
    userhash = URI.decode_www_form_component(hs.query["userhash"]) rescue ""
    username = URI.decode_www_form_component(hs.query["username"]) rescue ""
    if ws.login(loginid,userhash,username)
      ws.send("Welcome!")
      ws.sendBroadcast("Welcome [#{username}] !")
    else
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
    ws.logout
    puts "Error: #{e.message}"
  }
}
