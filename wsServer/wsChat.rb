# -*- coding: utf-8 -*-
require 'rubygems'
require 'em-websocket'
require 'digest/sha2'
require 'uri'
require_relative '../util/HtmlUtil'
require_relative '../model/CgiUser'

# チャット用モジュール ユーザー管理を追加
module ChatModule
  
  # ユーザー管理
  @@connected_clients = Hash.new

  # 接続ユーザー全員にメッセージを送る
  def sendBroadcast(msg)
    return if msg.empty?
    @@connected_clients.each_value { |c| c.send(msg) }
    puts msg
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
end

EM::WebSocket.start(:host => "localhost", :port => 3000) { |ws|
  ws.extend(ChatModule)

  ws.onopen{ |hs|
    loginid = URI.decode_www_form_component(hs.query["login"]) rescue ""
    userhash = URI.decode_www_form_component(hs.query["userhash"]) rescue ""
    username = URI.decode_www_form_component(hs.query["username"]) rescue ""
    if ws.login(loginid,userhash,username)
      ws.send("Welcome!")
      ws.sendBroadcast( "(" + (HtmlUtil.fmtDateTime(HtmlUtil.getToday)) + ")Welcome [#{username}] !")
    else
      ws.close
    end
  }

  ws.onmessage { |msg|
    return if msg.strip.size < 1
    ws.sendBroadcast("(" + (HtmlUtil.fmtDateTime(HtmlUtil.getToday)) + ")" + msg)
  }
  
  ws.onclose{
    ws.logout
  }
  
  ws.onerror{ |e|
    ws.logout
    puts "Error: #{e.message}"
  }
}
