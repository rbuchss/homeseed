module Homeseed
  class Homeshick < Connection
    include Logging

    EXEC_PATH = '$HOME/.homesick/repos/homeshick/bin/homeshick'

    def initialize(params={})
      super
      @commands = []
    end

    def install(params={})
      @config_files = Array[config_file_path('homeshick-install.yml')]
      @config_files.unshift(config_file_path('homeshick-prep.yml')) if params[:clean]
      push_commands(files: @config_files)
      fetch_user_config(params)
      user_commands = @user_config[:repos].map do |repo_name,repo_meta|
        "#{EXEC_PATH} clone #{repo_meta[:origin]} --batch && #{EXEC_PATH} symlink #{repo_name} --force"
      end
      push_commands(command: user_commands)
      push_yml_commands(@user_config[:post_install]) if @user_config[:post_install]
      exec
    end

    def update(params={})
      fetch_user_config(params)
      user_commands = @user_config[:repos].map do |repo_name,repo_meta|
        "#{EXEC_PATH} pull #{repo_name} --batch && #{EXEC_PATH} symlink #{repo_name} --force"
      end
      push_commands(command: user_commands)
      exec
    end

    def fetch_user_config(params={})
      if params[:url]
        response =  HTTParty.get(params[:url])
        raise HTTPartyError unless response.code == 200
        @user_config = YAML.load(response.body)
      else
        file = File.expand_path('.homeseed.yml', ENV['HOME'])
        @user_config = YAML.load_file(file)
      end
    end
  end
end
