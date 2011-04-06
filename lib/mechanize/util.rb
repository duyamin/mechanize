require 'cgi'

class Mechanize::Util
  CODE_DIC = {
    :JIS => "ISO-2022-JP",
    :EUC => "EUC-JP",
    :SJIS => "SHIFT_JIS",
    :UTF8 => "UTF-8", :UTF16 => "UTF-16", :UTF32 => "UTF-32"}

  def self.build_query_string(parameters, enc=nil)
    parameters.map { |k,v|
      # WEBrick::HTTP.escape* has some problems about m17n on ruby-1.9.*.
      [CGI.escape(k.to_s), CGI.escape(v.to_s)].join("=") if k
    }.compact.join('&')
  end

  def self.to_native_charset(s, code=nil)
    if Mechanize.html_parser == Nokogiri::HTML
      return unless s
      code ||= detect_charset(s)
      Iconv.iconv("UTF-8", code, s).join("")
    else
      s
    end
  end

  def self.from_native_charset(s, code)
    return s unless s && code
    return s unless Mechanize.html_parser == Nokogiri::HTML

    if RUBY_VERSION < '1.9.2'
      begin
        Iconv.iconv(code.to_s, "UTF-8", s).join("")
      rescue Iconv::InvalidEncoding, Iconv::IllegalSequence
        s
      end
    else
      s.encode("UTF-8") rescue s
    end
  end

  def self.html_unescape(s)
    return s unless s
    s.gsub(/&(\w+|#[0-9]+);/) { |match|
      number = case match
               when /&(\w+);/
                 Mechanize.html_parser::NamedCharacters[$1]
               when /&#([0-9]+);/
                 $1.to_i
               end

      number ? ([number].pack('U') rescue match) : match
    }
  end

  def self.detect_charset(src)
    tmp = NKF.guess(src || "<html></html>")
    if RUBY_VERSION >= "1.9.0"
      enc = tmp.to_s.upcase
    else
      enc = NKF.constants.find{|c|
        NKF.const_get(c) == tmp
      }
      enc = CODE_DIC[enc.intern]
    end
    enc || "ISO-8859-1"
  end

  def self.uri_unescape str
    @parser ||= begin
                  URI::Parser.new
                rescue NameError
                  URI
                end

    @parser.unescape str
  end

end
