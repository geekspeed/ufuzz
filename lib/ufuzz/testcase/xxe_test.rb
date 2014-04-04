module UFuzz

class XxeTest < TestCase
  def initialize(opts = {})
    @limit  = opts[:limit] || -1
    @vals   = File.read(File.expand_path(File.join(
                File.dirname(__FILE__), '..', 'wordlist', 'xxe.txt')))
                
    super
  end
  
  def threadable?
    true
  end
  
  def test(content)
    [/xterm/, /root:/].each do |regex|
      if content.to_s =~ regex
        return Fault.new('xml external entity injection', "possible xxe injection - #{@current.inspect}: found #{regex.inspect}")
      end
    end
    @monitor.check # has a nasty habit of crashing embedded xml parsers
    nil
  end
  
  def update_transforms
    @transforms = [ proc { |a| a.to_s } ]
    add_context_transforms
  end
  
  private
    
  def init_block
    @block = Fiber.new do
      @vals.each_line do |val|
        begin
          val = eval('"' + val + '"')
        rescue SyntaxError
          log "Error in wordlist: #{val.inspect}", WARN
        end
        val.chomp!
        @transforms.each do |t|
          Fiber.yield( t.call(val) )
        end
      end
      nil
    end
  end
end

end