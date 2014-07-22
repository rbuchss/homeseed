require "homeseed/version"
require 'logger'
require 'net/ssh'
require 'net/scp'
require 'yaml'
require_relative './logging'

module Homeseed
  class Connection
    include Logging

    def initialize(params={})
      raise 'servers and/or user not specified' unless params[:servers] and params[:user]
      @servers = params[:servers].split(',')
      @user = params[:user]
      @password = params[:password] || ''

      if params[:logger]
        @logger = params[:logger]
      else
        logger.level = params[:logger_level] || Logger::INFO
      end

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

        exit_status = nil
        exit_signal = nil

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
                  unless data_line == ''
                    if data_line.match(/error|failed/i)
                      logger.error data_line
                    else
                      logger.info data_line
                    end
                  end
                end
              end

              ch.on_request("exit-status") do |c,data|
                exit_status = data.read_long
              end

              ch.on_request("exit-signal") do |c,data|
                exit_signal = data.read_long
              end

              ch.send_data "exit\n"
            end
          end
        end
        [server, { exit_status: exit_status, exit_signal: exit_signal }]
      end]
    end

    def scp_upload
      @servers.each do |server|
        @upload_files.each do |upload_file|
          logger.info "starting scp #{upload_file} #{@user}@#{server}:#{@remote_path}"
          begin
            Net::SCP.start(server, @user) { |scp| scp.upload!(upload_file, @remote_path) }
            logger.info "finished scp #{upload_file} #{@user}@#{server}:#{@remote_path}"
          rescue => err
            logger.error "scp FAILED #{err}"
          end
        end
      end
    end
  end
end
