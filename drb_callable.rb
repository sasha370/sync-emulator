# Use this module to wrap DRb exposed methods to handle and log any error
module DRbCallable
  def drb_callable(method_name)
    alias_method "drb_callable_#{method_name}", method_name

    define_method method_name do |*args|
      public_send("drb_callable_#{method_name}", *args)
    rescue StandardError => e
      puts "Failed to call #{method_name}"
      puts e
      nil
    end
  end
end
