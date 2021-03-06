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
  # Execute SQL command on the remote database.
  class DatabaseTask < BaseTask
    # The shell command to invoke pqdb_sql.out
    PQDB = '. profiles/%s.prof > /dev/null && exe/pqdb_sql.out -s -x %s'.freeze
    # The ending of each well formatted sql
    EXIT = ";\nexit\n".freeze

    # Execute the SQL command on the remote database.
    #
    # @param [ SKI::Planet ] planet The planet where to execute the task.
    #
    # @return [ Void ]
    def exec(planet)
      connect(planet) do |ssh|
        log "Executing SQL command on #{ssh.host}" do
          sql(planet, ssh, format(PQDB, planet.user, planet.db))
        end
      end
    end

    protected

    # Well formatted SQL command to execute on the remote server.
    #
    # @return [ String ]
    def command
      ((cmd = super)[-1] == ';' ? cmd.chop! : cmd) << EXIT
    end

    private

    # Execute the SQL command on the remote database and yields the code
    # block with the captured result.
    #
    # @param [ SKI::Planet ]  planet The planet where to execute the task.
    # @param [ SSH::Session ]    ssh The SSH session that is connected to the
    #                                remote host.
    # @param [ String ]          cmd The shell command to invoke pqdb_sql.
    #
    # @return [ SKI::Result ]
    def sql(planet, ssh, cmd)
      channel = ssh.open_channel
      io, ok  = channel.popen2e(cmd)
      out     = io.<<(command).gets(nil)

      result(planet, out, ok && channel.close == 0 && out !~ /^(ORA|SP2)-/)
    end
  end
end
