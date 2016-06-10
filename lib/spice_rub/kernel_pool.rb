#--
# = SpiceRub
#
# A wrapper to the SPICE TOOLKIT for space and astronomomical
# computation in Ruby.
#
#
# == kernel_pool.rb
#
# Contains the KernelPool class, SpiceKernel(nested within KernelPool) which is
# the Ruby interface to kernel loading functions such as
# furnsh_c , unload_c, ktotal_c, kclear_c
#++

require 'spice_rub.so'
require 'singleton'

module SpiceRub
  # KernelPool class, the Ruby interface to kernel loading functions such as
  # furnsh_c , unload_c, ktotal_c, kclear_c
  class KernelPool
    include Singleton

    attr_reader :pool
    attr_accessor :path

    #
    # call-seq:
    #     [kernel] -> SpiceKernel
    #
    # Returns a SpiceKernel (loaded/unloaded) from the Kernel Pool 
    #
    # * *Arguments* :
    #   - +kernel+ -> The 0-based index of the kernel in the pool
    #
    # * *Returns* :
    #   - SpiceKernel corresponding to kernel index.
    #
    # Examples :-
    #   kernel_pool = KernelPool.instance
    #   
    #   #Load a kernel file
    #   
    #   kernel_pool[0]
    #     => #<SpiceRub::KernelPool::SpiceKernel:0xMEM @loaded=true, @path_to="spec/data/kernels/naif0011.tls">
    #
    def [](kernel)
      @pool[kernel]
    end
    
    #
    # call-seq:
    #     loaded -> List of SpiceKernel objects
    #
    # Returns the list of loaded kernels present in the kernel pool
    #
    # Examples :-
    #   kernel_pool.pool
    #     => [#<SpiceRub::KernelPool::SpiceKernel:0x0MEM1 @loaded=true, @path_to="spec/data/kernels/naif0011.tls">,
    #         #<SpiceRub::KernelPool::SpiceKernel:0x0MEM2 @loaded=false, @path_to="spec/data/kernels/moon_pa_de421_1900-2050.bpc">,
    #         #<SpiceRub::KernelPool::SpiceKernel:0x0MEM3 @loaded=true, @path_to="spec/data/kernels/de405_1960_2020.bsp">]
    #
    #   kernel_pool.loaded
    #     => [#<SpiceRub::KernelPool::SpiceKernel:0x0000000142ed60 @loaded=true, @path_to="spec/data/kernels/naif0011.tls">,
    #         #<SpiceRub::KernelPool::SpiceKernel:0x00000000a42ef0 @loaded=true, @path_to="spec/data/kernels/de405_1960_2020.bsp">]
    #
    def loaded
      @pool.select(&:loaded?)
    end

    #
    # call-seq:
    #     load -> FixNum
    #
    # Returns a FixNum corresponding to the index of the kernel 
    # in the kernel pool if the load is successful. Ruby interface to furnsh_c from
    # the SPICE toolkit.
    #
    # * *Arguments* :
    #   - +file+ -> The relative file path of the kernel if path is nil, else the filename 
    #               
    # Examples :-
    #   kernel_pool = KernelPool.instance
    #   
    #   kernel_pool.path = "spec/data/kernels/"
    #   
    #   kernel_pool.load("naif0011.tls")
    #     => 0
    #
    def load(file)
      @pool ||= []

      file = @path.dup << file if check_path
      @pool << SpiceKernel.new(file) if SpiceRub::Native.furnsh(file)
      @pool.length - 1
    end

    #
    # call-seq:
    #     clear -> TrueClass/FalseClass
    # 
    # Clears the kernel pool and returns true if successful.
    # Ruby interface to kclear_c from the SPICE Toolkit.
    #        
    # Examples :-
    #   kernel_pool.clear!
    #     => true
    #   
    #   kernel_pool.pool
    #     => []
    #
    def clear!
      unless empty?
        if SpiceRub::Native.kclear
          @pool = []
          return true
        end
      end
      false
    end

    #
    # call-seq:
    #     count -> FixNum
    # 
    # Returns the number of loaded kernels in the kernel pool
    # Ruby interface for ktotal_c from the SPICE Toolkit.        
    #
    # Examples :-
    #   kernel_pool.pool
    #     => [#<SpiceRub::KernelPool::SpiceKernel:0x0000000142ed60 @loaded=true, @path_to="spec/data/kernels/naif0011.tls">,
    #         #<SpiceRub::KernelPool::SpiceKernel:0x00000000aee980 @loaded=true, @path_to="spec/data/kernels/moon_pa_de421_1900-2050.bpc">,
    #         #<SpiceRub::KernelPool::SpiceKernel:0x00000000a42ef0 @loaded=true, @path_to="spec/data/kernels/de405_1960_2020.bsp">]
    #
    #   kernel_pool.count
    #     => 3
    #
    def count(category = :ALL)
      SpiceRub::Native.ktotal(category)
    end

    def empty?
      count.zero?
    end

    def check_path
      if @path && @path.is_a?(String)
        @path << '/' unless @path[-1] == '/'
        true
      else
        false
      end
    end

    def clear_path!
      @path = nil
    end

    private :check_path

    # SpiceKernel class, a helper object used by KernelPool to track
    # kernel files, is not visible outside KernelPool.
    class SpiceKernel
      attr_reader :path_to, :loaded

      def initialize(path)
        @path_to = path
        @loaded = true
      end

      def unload
        if SpiceRub::Native.unload(@path_to)
          @loaded = false
          true
        else
          false
        end
      end

      def loaded?
        @loaded
      end
    end
    private_constant :SpiceKernel
  end
end
