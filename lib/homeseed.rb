require "homeseed/version"
require 'logger'
require 'net/ssh'
require 'net/scp'
require 'yaml'

module Homeseed
  class Connection
    def self.logger
      @logger ||= Logger.new(STDOUT)
      original_formatter = Logger::Formatter.new
      @logger.formatter = proc { |severity, datetime, progname, msg|
        original_formatter.call(severity, datetime, progname, msg.dump)
      }
      @logger
    end

    def logger
      self.class.logger
    end

    def initialize(params={})
      raise 'servers and/or user not specified' unless params[:servers] and params[:user]
      @servers = params[:servers].split(',')
      @user = params[:user]
      @password = params[:password] || ''

      if params[:command]
        @flat_commands = params[:command]
      elsif params[:files]
        @files = params[:files].split(',')
        @flat_commands = ''
        @files.each do |file|
          yml_commands = YAML.load_file(file)
          commands = []
          self.process_hash(commands, '', yml_commands)
          @flat_commands += commands.join('; ') + ';'
        end
      elsif params[:upload_files]
        @remote_path = params[:remote_path] || '/tmp/'
        @upload_files = params[:upload_files].split(',')
      else
        raise 'ERROR command, files or upload_files not specified'
      end
    end

    def process_hash(commands, current_key, obj)
      if obj.is_a?(Hash)
        obj.each do |new_key, value|
          combined_key = [current_key, new_key].delete_if { |k| k == '' }.join(" ")
          process_hash(commands, combined_key, value)
        end
      else obj.is_a?(Array)
        obj.each do |value|
          combined_key = [current_key, value].delete_if { |k| k == '' }.join(" ")
          commands << combined_key
        end
      end
    end

    def ssh_exec
      Hash[@servers.map do |server|
        logger.info "ssh #{@user}@#{server} exec: #{@flat_commands}"

        exit_status = 0
        Net::SSH.start(server, @user, password: @password) do |ssh|
          ssh.open_channel do |channel|
            channel.exec("bash -l") do |ch,success|
              ch.send_data "#{@flat_commands}\n"
              ch.on_data do |c,data|
                data_lines = data.split(/[\r,\n]/)
                data_lines.each do |data_line|
                  logger.info data_line unless data_line == ''
                end
              end

              ch.on_extended_data do |c,type,data|
                data_lines = data.split(/[\r,\n]/)
                data_lines.each do |data_line|
                  logger.error data_line unless data_line == ''
                end
              end

              ch.on_request("exit-status") do |c,data|
                exit_status = data.read_long
              end
              ch.send_data "exit\n"
            end
          end
        end
        [server, { exit_status: exit_status }]
      end]
    end

    def scp_upload
      @servers.each do |server|
        @upload_files.each do |upload_file|
          logger.info "scp #{upload_file} #{@user}@#{server}:#{@remote_path}"
          Net::SCP.start(server, @user) do |scp|
            scp.upload!(upload_file, @remote_path)
          end
        end
      end
    end
  end
end
