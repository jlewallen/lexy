require 'pathname'
require 'open-uri'

module JacobLewallen
  module Glassfish
    class Output
      def initialize(lines)
        @lines = lines
      end

      def matching(re)
        @lines.map { |l| re.match(l) }.compact.map { |m| m.to_a }
      end
    end

    class Server
      def initialize(port)
        @port = port
      end

      def clusters
        @c ||= begin
           Hash[*Output.new(lines('list-clusters')).matching(/^(\S+) (.*running)$/).map { |r| [ r[1], r[2] == 'running' ] }.flatten]
        end
      end

      def create_cluster(name)
        execute("create-cluster #{name}")
      end

    private
      def asadmin
        "/opt/glassfish/glassfish/bin/asadmin"
      end

      def lines(*args)
        `#{asadmin} --port #{@port} #{args.join(' ')}`.split("\n")
      end

      def execute(*args)
        system("#{asadmin} --port #{@port} #{args.join(' ')}")
      end
    end
  end
end
