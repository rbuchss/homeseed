module Homeseed
  class Connection
    include Logging
    attr_reader :servers, :user, :has_password

    def initialize(params={})
      raise ConnectionError, 'servers and/or user not specified' unless params[:servers] and params[:user]
      @servers = params[:servers].split(',')
      @user = params[:user]
      @commands = []
      @logger = params[:logger] || logger

      if params[:has_password]
        cli = HighLine.new
        @password = cli.ask("Enter password: ") { |q| q.echo = false }
      else
        @password = params[:password] || ''
      end

      push_commands(params)
    end

    def push_commands(params={})
      if params[:command]
        @commands.push(*params[:command])
      elsif params[:files]
        push_bash_files(params[:files])
      elsif params[:file]
        push_bash_file(params[:file])
      elsif params[:url]
        push_url_commands(params[:url])
      elsif params[:upload_files]
        @remote_path = params[:remote_path] || '/tmp/'
        @upload_files = params[:upload_files].split(',')
      end
    end

    def config_file_path(file)
      File.expand_path("../../../config/#{file}", __FILE__)
    end

    def push_bash_files(files)
      @files = files
      @files.each do |file|
        push_bash_file(file)
      end
    end

    def push_bash_file(file)
      @file = file
      yml_commands = YAML.load_file(file)
      push_yml_commands(yml_commands)
    end

    def push_url_commands(url)
      response =  HTTParty.get(url)
      raise HTTPartyError unless response.code == 200
      yml_commands = YAML.load(response.body)
      push_yml_commands(yml_commands)
    end

    def push_yml_commands(yml_commands)
      commands = []
      self.process_hash(commands, '', yml_commands)
      @commands.push(*commands)
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

    def exec(params={})
      if @servers.include?('localhost')
        local_exec
      else
        ssh_exec
      end
    end

    def local_exec
      commands = @commands.join('; ') + ';'
      @logger.info "localhost exec: #{commands}"

      IO.popen("#{commands}") do |chunks|
        chunks.each do |line|
          log_exec(line)
        end
      end
    end

    def ssh_exec
      Hash[@servers.map do |server|
        commands = @commands.join('; ') + ';'
        @logger.info "ssh #{@user}@#{server} exec: #{commands}"

        exit_status = nil
        exit_signal = nil

        Net::SSH.start(server, @user, password: @password) do |ssh|
          ssh.open_channel do |channel|
            channel.exec("bash -l") do |ch,success|
              ch.send_data "#{commands}\n"

              ch.on_data do |c,data|
                log_exec(data)
              end

              ch.on_extended_data do |c,type,data|
                log_exec(data)
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

    def log_exec(data)
      data_lines = data.split(/[\r,\n]/)
      data_lines.each do |data_line|
        unless data_line == ''
          if data_line.match(/error|failed|fatal/i)
            @logger.error data_line
          else
            @logger.info data_line
          end
        end
      end
    end

    def scp_upload
      raise ConnectionError, 'cannot scp to localhost' if @servers.include?('localhost')
      @servers.each do |server|
        @upload_files.each do |upload_file|
          @logger.info "starting scp #{upload_file} #{@user}@#{server}:#{@remote_path}"
          begin
            Net::SCP.start(server, @user) { |scp| scp.upload!(upload_file, @remote_path) }
            @logger.info "finished scp #{upload_file} #{@user}@#{server}:#{@remote_path}"
          rescue => err
            @logger.error "scp FAILED #{err}"
          end
        end
      end
    end
  end
end
