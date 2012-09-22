module Guard
  class Spork
    class SporkInstance
      attr_reader :type, :env, :port, :options, :pid, :process

      def initialize(type, port, env, options)
        @type = type
        @port = port
        @env = env
        @options = options
      end

      def to_s
        case type
        when :rspec
          "RSpec"
        when :cucumber
          "Cucumber"
        when :test_unit
          "Test::Unit"
        when :minitest
          "MiniTest"
        else
          type.to_s
        end
      end

      def start
        cmd = command

        ::Guard::UI.debug "guard-spork command execution: #{cmd}"

        @process = ChildProcess.build *cmd
        @process.environment.merge!(env) unless env.empty?
        @process.io.inherit!
        @process.start
        @pid = @process.pid
      end

      def stop
        process.stop
      end

      def alive?
        pid && process.alive?
      end

      def running?
        return false unless alive?
        TCPSocket.new('localhost', port).close
        true
      rescue Errno::ECONNREFUSED
        false
      end

      def command
        parts = []
				if use_bundler? 
					parts << "bundle"
					parts << "exec"
				end
				if use_foreman?
					parts << "foreman"
					parts << "run"
				end
        parts << "spork"

        if type == :test_unit
          parts << "testunit"
        elsif type == :cucumber
          parts << "cu"
        elsif type == :minitest
          parts << "minitest"
        end

        parts << "-p #{port}"
        parts << "-q" if options[:quiet]
        parts.join(" ")
      end

      def self.spork_pids
        `ps aux | awk '/spork/&&!/awk/{print $2;}'`.split("\n").map { |pid| pid.to_i }
      end

    private

      def use_bundler?
        options[:bundler]
      end

      def use_foreman?
        options[:foreman]
      end

    end
  end
end
