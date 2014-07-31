module Homeseed
  class Homeshick < Connection
    include Logging

    def install(params={})
      @config_files = Array[config_file_path('homeshick-install.yml')]
      @config_files.push(config_file_path('homeshick-source.yml'))
      @config_files.unshift(config_file_path('homeshick-prep.yml')) if params[:clean]
      push_commands(files: @config_files)
      if params[:url]
        exec(params.merge(user_config: :url))
      else
        exec(params.merge(user_config: :local, file: '.homeseed.yml'))
      end
    end

    def update(params={})
      @config_files = Array[config_file_path('homeshick-source.yml')]
      push_commands(files: @config_files)
      fetch_user_config(params)
      if params[:url]
        exec(params.merge(user_config: :url))
      else
        exec(params.merge(user_config: :local, file: '.homeup.yml'))
      end
    end

    def fetch_user_config(params={})
      case params[:user_config]
      when :url
        push_commands(url: params[:url])
      when :local
        file = File.expand_path(params[:file], ENV['HOME'])
        push_commands(file: file)
      end
    end

    def exec(params={})
      fetch_user_config(params)
      super
    end
  end
end
