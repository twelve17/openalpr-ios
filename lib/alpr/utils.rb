require 'shellwords'

module Alpr
  module Utils

    def execute(cmd, env={}, opts={})
      opts[:exit_on_error] = true if !opts.has_key?(:exit_on_error)

      if !env.nil? && !env.empty?
        cmd = env.map { |k,v| "#{k}='#{v}'" }.join(" ") + " " + cmd
      end

      if !opts[:quiet] && !opts[:log]
        $stderr.puts "Executing:", cmd
      end
      if opts[:log]
        system("echo '=======================================================================' >> #{opts[:log]}")
        system("echo Executing: #{Shellwords.shellescape(cmd)} >> #{opts[:log]}")
        system("echo '=======================================================================' >> #{opts[:log]}")
        output = `#{cmd} 2>&1 >> #{opts[:log]}`
      else
        output = `#{cmd} 2>&1`
        puts output unless opts[:quiet]
      end
      status = $?
        if opts[:exit_on_error] && !status.success?
          raise "Child returned: #{$?}"
        end
      output.strip
    end

    def qexec(cmd)
      execute(cmd, nil, {quiet: true})
    end

    def xcfind(path)
      qexec("xcrun -find #{path}")
    end

    def do_in_dir(dir, is_tmp=false)
      if is_tmp
        if File.directory?(dir)
          FileUtils.rm_rf(dir)
        end
        FileUtils.mkdir(dir)
      end
      currdir = FileUtils.pwd
      FileUtils.cd(dir)
      yield
      FileUtils.cd(currdir)
      if is_tmp
        FileUtils.rm_rf(dir)
      end
    end

    def log_execute(cmd, env={}, opts={})
      execute(cmd, env, {log: self.log_file})
    end

  end
end


