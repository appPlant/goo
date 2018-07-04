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
    class ServerTask < BaseTask
      # Execute the shell command on the remote database.
      #
      # @param [ SKI::Planet ] planet The planet where to execute the task.
      #
      # @return [ Void ]
      def exec(planet)
        connect(planet) do |ssh|
          log "Executing shell command on #{ssh.host}" do
            sh(ssh) { |out, suc| Result.new(planet, out, suc) }
          end
        end
      end

      private

      # Execute the shell command on the remote database and yields the code
      # block with the captured result.
      #
      # @param [ SSH::Session ] ssh The SSH session with is connected to the
      #                             remote host.
      #
      # @return [ SKI::Result ]
      def sh(ssh)
        channel  = ssh.open_channel
        out, suc = channel.capture2e(command)

        yield(out, suc && channel.exitstatus == 0)
      end
    end
  end
end