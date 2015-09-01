# encoding: utf-8
# Menu Controller
require_relative '../util/HtmlUtil'
require 'erb'
require 'pathname'

class MenuController
  def index session,args
    form = Pathname("view/Menu.html.erb").read(:encoding => Encoding::UTF_8)
    return (ERB.new(form).result(binding)), false, ""
  end
end
