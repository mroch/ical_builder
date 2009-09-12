require 'blankslate'

module Builder
  class Ical < BlankSlate
    def initialize(options = {})
      @target = options[:target] || ''
    end

    def to_s
      __fold(@target.to_s)
    end

    def method_missing(sym, *args, &block)
      value = args.shift
      if block
        @target << "BEGIN:#{__property(sym)}\r\n"
        block.call(self)
        @target << "END:#{__property(sym)}\r\n"
      else
        @target << "#{__property(sym)}#{__parameters(args)}:#{__value(value)}\r\n"
      end
    end

    private
      def __property(sym)
        sym.to_s.upcase.gsub(/_/, '-')
      end

      # 4.2 Property Parameters
      def __parameters(args)
        return '' if args.nil? || args.empty?

        ';' + args.collect { |arg| 
          case arg
          when Hash
            arg.collect { |k, v| "#{__property(k)}=#{__value(v)}" }.sort.join(';')
          else
            arg.to_s
          end
        }.join(';')
      end
      
      # 4.3 Property Value Data Types
      def __value(val)
        case val
        when Array
          # 4.1.1
          val.collect { |v| __value(v) }.join(',')
        when Hash
          # 4.1.1
          val.collect { |k, v| "#{__property(k)}=#{__value(v)}" }.sort.join(';')
        when true, false
          # 4.3.2
          val.to_s.upcase
        when Date
          # 4.3.4
          val.strftime('%Y%m%d')
        when Time
          # 4.3.5
          val.strftime('%Y%m%dT%H%M%S' + (val.utc? ? 'Z' : ''))
        else
          val.to_s.gsub(/\r\n/, "\n").gsub(/\n/, "\r\n  ").sub(/\r\n  \z/, "\r\n")
        end
      end
      
      # 4.1 Content Lines
      def __fold(str)
        str.inject([]) { |lines, line|
          if line.length > 75
            lines << line[0..74] << __fold(" " + line[75..-1])
          else
            lines << line
          end
          lines
        }.join("\r\n")
      end
  end
end
