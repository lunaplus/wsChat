# encoding: utf-8
# Menu Controller
require_relative '../util/HtmlUtil'
require_relative '../model/ChatLog'
require 'erb'
require 'pathname'
require 'uri'

class HistoryController
  def index session,args
    splitCount = 15

    fromNum = (args[0]["from"][0]).to_i

    logcounts,strErr = ChatLog.getLogCounts
    if strErr == ""
      existPrev = fromNum != 0
      existNext = (fromNum + splitCount) < logcounts

      prevUrl = HtmlUtil.getHistoryUrl + "?from=" +
        (existPrev and fromNum > splitCount ? fromNum - splitCount : 0).to_s
      nextUrl = HtmlUtil.getHistoryUrl + "?from=" + (fromNum + splitCount).to_s
      mainUrl = HtmlUtil.getMainUrl

      logArr = ChatLog.getLogs(fromNum, splitCount)
      logStr = "<ul>"
      logArr.each do |elm|
          tmpStr = "<li>"
        if elm[:err] == ""
          tmpStr += HtmlUtil.esc(elm[:rname].to_s) +
            " / " unless (elm[:rname].to_s).empty?
          tmpStr += "[" + HtmlUtil.esc(elm[:name].to_s) + "]"
          tmpStr += " (" +
            HtmlUtil.esc(HtmlUtil.fmtDateTime(elm[:sentDate])) + ") "
          tmpStr += HtmlUtil.esc(elm[:message].to_s)
        else
          tmpStr += "!!! " + elm[:err].to_s + " !!!"
        end
        tmpStr += "</li>"
        logStr += tmpStr
      end
      logStr += "</ul>"
    end

    form = Pathname("view/History.html.erb").read(:encoding => Encoding::UTF_8)
    return (ERB.new(form).result(binding)), false, ""
  end
end
