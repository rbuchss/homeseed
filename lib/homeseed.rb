require "homeseed/version"
require 'logger'
require 'net/ssh'
require 'highline/import'
require 'yaml'

module Homeseed
  class Connection
    def self.logger
      @logger ||= Logger.new(STDOUT)
    end

    def logger
      self.class.logger
    end

    def initialize(params={})
      raise unless params[:servers] and params[:files] and params[:user]
      @servers = params[:servers].split(',')
      @files = params[:files].split(',')
      @user = params[:user]
      @has_password = params[:password]

      @flat_commands = ''
      @files.each do |file|
        yml_commands = YAML.load_file(file)
        commands = []
        self.process_hash(commands, '', yml_commands)
        @flat_commands += commands.join('; ') + ';'
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
      @servers.each do |server|
        logger.info "ssh #{@user}@#{server} exec: #{@flat_commands}"

        password = @has_password ? ask("Enter password: ") { |q| q.echo = "*" } : ''
        Net::SSH.start(server, @user, password: password) do |ssh|
          ssh.open_channel do |channel|
            channel.exec("bash -l") do |ch, success|
              ch.send_data "#{@flat_commands}\n"
              ch.on_data do |c, data|
                data_lines = data.split(/[\r,\n]/)
                data_lines.each do |data_line|
                  logger.info data_line unless data_line == ''
                end
              end

              ch.on_extended_data do |c, type, data|
                data_lines = data.split(/[\r,\n]/)
                data_lines.each do |data_line|
                  logger.error data_line unless data_line == ''
                end
              end
              ch.send_data "exit\n"
            end
          end
        end
      end
    end
  end
end
