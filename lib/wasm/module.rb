module WebAssembly
  class Module
    attr_accessor :magic, :version, :sections

    def initialize
      @sections = []
    end

    def to_hash
      {
        :magic => @magic,
        :version => @version,
        :sections => @sections.map {|e| e.to_hash}
      }
    end
  end

  class Section
    attr_accessor :id, :size

    def self.by_id id
      subclass = nil
      ObjectSpace.each_object(singleton_class) do |k|
        subclass = k if k.superclass == self and k::ID == id
      end
      subclass
    end

    def to_hash
      {
        :id => @id,
        :size => @size
      }
    end
  end

  class CustomSection < Section
    ID = 0
    
    attr_accessor :name, :bytes

    def initialize
      @bytes = []
    end
  end

  class TypeSection < Section
    ID = 1

    def initialize
      @function_types = []
    end
  end

  class ImportSection < Section
    ID = 2
  end

  class FunctionSection < Section
    ID = 3
  end

  class TableSection < Section
    ID = 4
  end

  class MemorySection < Section
    ID = 5
  end

  class GlobalSection < Section
    ID = 6
  end

  class ExportSection < Section
    ID = 7
  end

  class StartSection < Section
    ID = 8
  end

  class ElementSection < Section
    ID = 9
  end

  class CodeSection < Section
    ID = 10
  end

  class DataSection < Section
    ID = 11
  end

  class DataCountSection < Section
    ID = 12
  end
end