# encoding: utf-8
# Model Master
require 'mysql2'

class ModelMaster
  DBNAME = "cgiruby"
  def self.getMysqlClient
    return Mysql2::Client.new(:host => "localhost",
                              :username => "cgiruby",
                              :password => "cg1ruby",
                              :database => DBNAME)
  end
end
