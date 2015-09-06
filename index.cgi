#!/usr/bin/env /Users/sanae/.rvm/rubies/ruby-head/bin/ruby
# encoding: utf-8
ENV['GEM_HOME'] = '/Users/sanae/.rvm/gems/ruby-head@wsChat'

require 'cgi'
require 'cgi/session'
require_relative './util/HtmlUtil'

# == main ==========================================

# initialize ------------------
cgi = CGI.new
session = CGI::Session.new(cgi)
isRedirect = false
redirectLocation = ""

DEBUG = false
debugStr = ""

## get parameters ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
loginid = session[HtmlUtil::LOGINID]
loginname = session[HtmlUtil::LOGINNAME]

## routing ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
pathinfo = "" # path_info環境変数
pathinfo = ENV['PATH_INFO'] unless ENV['PATH_INFO'] == nil

debugStr +=  pathinfo + "\n" if DEBUG

pathelem = [] # path_info環境変数を/でsplitしたarray
if pathinfo != "" and pathinfo != "/"
 pathelem = pathinfo.split("/")
 pathelem.shift # 1要素目は必ず""になるため削除
end

debugStr += pathelem if DEBUG
debugStr += "\n" if DEBUG

### routing rule : as Rails
###   /foo             => call fooController.index
###   /foo/bar         => call fooController.bar
###   /foo/bar/baz/... => call fooController.bar(baz,...)

### Controller interface
###  : new (constructor)
###  : index, and other methods
###  : args   : array
###  : return : htmlsource(string), isRedirect(bool), redirectLocation(string)
ctrler = nil # XxxControllerクラスのインスタンス
ctrlname = pathelem.shift
case ctrlname
when HtmlUtil::LoginCtrlName
 require_relative './controller/LoginController'
 ctrler = LoginController.new
else # 未ログインの場合はログイン画面へ飛ばす。
  if loginid == "" or loginid == nil
    if !isRedirect
      isRedirect = true
      redirectLocation = HtmlUtil.createUrl HtmlUtil::LoginCtrlName,"index"
    end
  else
    debugStr += "else" + "\n" if DEBUG
#############################################################################
## ルーティング変更時に追記する
    case ctrlname
    when HtmlUtil::MenuCtrlName
      require_relative './controller/MenuController'
      ctrler = MenuController.new
    when HtmlUtil::MainCtrlName
      require_relative './controller/MainController'
      ctrler = MainController.new
    when HtmlUtil::HistoryCtrlName
      require_relative './controller/HistoryController'
      ctrler = HistoryController.new
#############################################################################
    else # ログイン済でURLが不正な場合はメイン画面へ
      if !isRedirect
        isRedirect = true
        redirectLocation = HtmlUtil.getMainUrl
      end
    end
  end
end

debugStr += ctrlname + "\n" if DEBUG

### action routing
actname = pathelem.shift
actname = "" if actname == nil # actname.to_symメソッド利用のため
if (ctrler.methods.find { |i| i === actname.to_sym }) == nil
  # actname = "index" # 存在しないactionの場合、indexへ飛ばす
  if !isRedirect
    isRedirect = true
    redirectLocation = HtmlUtil.createUrl ctrlname,"index"
  end
end

## proc call and print HTML ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
actargs = [cgi.params]
htmlSource,isRedirect,redirectLocation = ctrler.send(actname, session, actargs.concat(pathelem)) unless isRedirect
session.close
if isRedirect
  print HtmlUtil.htmlRedirect cgi,redirectLocation
else
  htmlSource += debugStr if DEBUG
  cgi.out (HtmlUtil.initCgi) {
    HtmlUtil.htmlHeader + htmlSource + HtmlUtil.htmlFooter
  }
end
