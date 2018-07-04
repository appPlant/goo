# Apache 2.0 License
#
# Copyright (c) 2018 Sebastian Katzer, appPlant GmbH
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

module SKI
  module Task
    class BaseTask
      # Default configuration for every SSH connection
      SSH_CONFIG = { key: ENV['ORBIT_KEY'], compress: true, timeout: 5_000 }.freeze

      # Initialize the task specified by opts.
      #
      # @param [ Hash<Symbol,Object> ] opts A key-value hash.
      #
      # @return [ Void ]
      def initialize(opts)
        @opts = opts
      end

      protected

      # The command to execute on the remote server.
      #
      # @return [ String ]
      def command
        (@opts[:script] ? IO.read(@opts[:script]) : @opts[:command])&.strip
      end

      private

      # Logging device that writes into $ORBIT_HOME/log/plip.log
      #
      # @return [ Logger ]
      def logger
        $logger ||= begin
          dir = File.join(ENV['ORBIT_HOME'], 'logs')
          Dir.mkdir(dir) unless Dir.exist? dir

          Logger.new("#{dir}/ski.log", formatter: lambda do |sev, ts, _, msg|
            "[#{sev[0, 3]}] #{ts}: #{msg}\n"
          end)
        end
      end

      # Write a log message, execute the code block and write another log.
      # that the task is done.
      #
      # @param [ String ] msg The message to log.
      # @param [ Proc ] block The code block to execute.
      #
      # @return [ Void ]
      def log(msg)
        logger.info msg
        res = yield
        logger.info "#{msg} done"
        res
      end

      # Write an error log message.
      #
      # @param [ String ] user The remote user.
      # @param [ String ] host The remote host.
      # @param [ SSH::Session ] ssh The connected SSH session.
      # @param [ String ] msg  The error message.
      #
      # @return [ Void ]
      def log_error(usr, host, ssh, msg = nil)
        logger.error "#{usr}@#{host} #{ssh&.last_error} #{ssh&.last_errno} #{msg}"
      end

      # Start an SSH session.
      #
      # @param [ SKI::Planet ] planet The planet where to connect to.
      #
      # @return [ Void ]
      def connect(planet)
        user, host = planet.user_and_host
        ssh        = SSH.start(host, user, SSH_CONFIG.dup)
        res        = yield(ssh)
        log_error(user, host, ssh) if ssh.last_error
        res
      rescue RuntimeError => e
        log_error(user, host, ssh, e.message)
        [e.message, false]
      ensure
        ssh&.close
      end
    end
  end
end
