require_relative "./instance.rb"

module WebAssembly
  class Module
    attr_accessor :magic, :version, :sections

    def initialize
      @sections = []
    end

    def magic=(magic)
      raise "invalid magic: #{magic}" unless magic == [0x00, 0x61, 0x73, 0x6d]
      @magic = magic
    end

    def version=(version)
      raise "invalid version: #{version}" unless version == [0x01, 0x00, 0x00, 0x00]
      @version = version
    end

    def section_by_name name
      @sections.find do |sec|
        sec.class.name.split("::").last.sub(/Section$/, "").downcase == name
      end
    end

    def instantiate import_object=nil
      inst = Instance.new self, import_object
      inst.compile
      inst
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

    def self.name_by_id id
      self.by_id(id).name.split("::").last.sub(/Section$/, "").downcase
    end

    def to_hash
      {
        :section => Section.name_by_id(@id),
        :id => @id,
        :size => @size,
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
      @functypes = []
    end

    def add_functype functype
      @functypes.push functype
    end

    def to_hash
      super.to_hash.merge({
        :types => @functypes.map {|t| t.to_hash}
      })
    end
  end

  class ImportSection < Section
    ID = 2

    def initialize
      @imports = []
    end

    def add_import import
      @imports.push import
    end

    def to_hash
      super.to_hash.merge({
        :types => @imports.map {|t| t.to_hash}
      })
    end
  end

  class FunctionSection < Section
    ID = 3

    def initialize
      @type_indices = []
    end

    def add_type_index type_index
      @type_indices.push type_index
    end

    def to_hash
      super.to_hash.merge({
        :types => @type_indices
      })
    end
  end

  class TableSection < Section
    ID = 4

    def initialize
      @tabletypes = []
    end

    def add_tabletype tabletype
      @tabletypes.push tabletype
    end

    def to_hash
      super.to_hash.merge({
        :types => @tabletypes.map {|tt| tt.to_hash}
      })
    end
  end

  class MemorySection < Section
    ID = 5

    def initialize
      @memtypes = []
    end

    def add_memtype limit
      @memtypes.push limit
    end

    def to_hash
      super.to_hash.merge({
        :types => @memtypes
      })
    end
  end

  class GlobalSection < Section
    ID = 6

    def initialize
      @globals = []
    end

    def add_global global
      @globals.push global
    end

    def to_hash
      super.to_hash.merge({
        :globals => @globals
      })
    end
  end

  class ExportSection < Section
    ID = 7

    def initialize
      @exports = []
    end

    def add_export export
      @exports.push export
    end

    def to_hash
      super.to_hash.merge({
        :exports => @exports.map {|e| e.to_hash}
      })
    end
  end

  class StartSection < Section
    ID = 8

    def initialize
      @starts = []
    end

    def add_start start
      @starts.push start
    end

    def to_hash
      super.to_hash.merge({
        :starts => @starts
      })
    end
  end

  class ElementSection < Section
    ID = 9

    def initialize
      @elements = []
    end

    def add_element element
      @elements.push element
    end

    def to_hash
      super.to_hash.merge({
        :elements => @elements.map {|e| e.to_hash}
      })
    end
  end

  class CodeSection < Section
    ID = 10

    def initialize
      @codes = []
    end

    def add_code code
      @codes.push code
    end

    def to_hash
      super.to_hash.merge({
        :codes => @codes.map {|c| c.to_hash}
      })
    end
  end

  class DataSection < Section
    ID = 11

    attr_accessor :data

    def initialize
      @data = []
    end

    def add_data data
      @data.push data
    end

    def to_hash
      super.to_hash.merge({
        :data => @data.map {|d| d.to_hash}
      })
    end
  end

  class DataCountSection < Section
    ID = 12

    attr_accessor :count

    def to_hash
      super.to_hash.merge({
        :count => @count
      })
    end
  end

  class Limit
    attr_accessor :min, :max

    def to_hash
      h = {:min => @min}
      h[:max] = @max if @max
      h
    end
  end

  class FuncType
    TAG = 0x60

    attr_accessor :params, :results

    def initialize
      @params = []
      @results = []
    end

    def to_hash
      {
        :params => @params,
        :results => @results,
      }
    end
  end

  class Import
    attr_accessor :mod, :name, :desc

    def to_hash
      {
        :mod => @mod,
        :name => @name,
        :desc => @desc.to_hash,
      }
    end
  end

  class ImportDesc
  end

  class ImportTypeDesc < ImportDesc
    TAG = 0x00

    attr_accessor :index

    def to_hash
      {
        :type => {
          :index => index.to_hash,
        }
      }
    end
  end

  class ImportTableDesc < ImportDesc
    TAG = 0x01

    attr_accessor :reftype, :limits

    def to_hash
      {
        :table => {
          :reftype => @reftype.to_hash,
          :limits => @limits.to_hash,
        }
      }
    end
  end

  class ImportMemoryDesc < ImportDesc
    TAG = 0x02

    attr_accessor :limits

    def to_hash
      {
        :memory => {
          :limits => @limits.to_hash,
        }
      }
    end
  end

  class ImportGlobalDesc < ImportDesc
    TAG = 0x03

    attr_accessor :globaltype

    def to_hash
      {
        :global => {
          :type => @globaltype.to_hash
        }
      }
    end
  end

  class TableType
    attr_accessor :reftype, :limits

    def to_hash
      {
        :reftype => @reftype,
        :limits => @limits.to_hash,
      }
    end
  end

  class Global
    attr_accessor :globaltype, :expr
  end

  class GlobalType
    attr_accessor :valtype, :mut

    def to_hash
      {
        :valtype => @valtype,
        :mut => @mut,
      }
    end
  end

  class Export
    attr_accessor :name, :desc

    def to_hash
      {
        :name => @name,
        :desc => @desc.to_hash,
      }
    end
  end

  class Index
    attr_accessor :index
  end

  class TypeIndex < Index
    def to_hash
      {
        :type => @index
      }
    end
  end

  class FuncIndex < Index
    def to_hash
      {
        :func => @index
      }
    end
  end

  class TableIndex < Index
    def to_hash
      {
        :table => @index
      }
    end
  end

  class MemoryIndex < Index
    def to_hash
      {
        :memory => @index
      }
    end
  end

  class GlobalIndex < Index
    def to_hash
      {
        :global => @index
      }
    end
  end

  class ElementIndex < Index
    def to_hash
      {
        :element => @index
      }
    end
  end

  class DataIndex < Index
    def to_hash
      {
        :data => @index
      }
    end
  end

  class LocalIndex < Index
    def to_hash
      {
        :local => @index
      }
    end
  end

  class LabelIndex < Index
    def to_hash
      {
        :label => @index
      }
    end
  end

  class Element
    attr_accessor :expression

    def initialize
      @funcidxs = []
    end

    def add_funcidx funcidx
      @funcidxs.push funcidx
    end

    def to_hash
      {
        :funcidx => @funcidxs
      }
    end
  end

  class Code
    attr_accessor :locals, :expressions

    def initialize
      @locals = []
      @expressions = []
    end

    def add_locals locals
      @locals.push locals
    end

    def to_hash
      {
        :locals => @locals.map {|l| l.to_hash},
        :expressions => @expressions.map {|e| e.to_hash},
      }
    end
  end

  class Locals
    attr_accessor :count, :valtype
  end

  class Instruction
    def self.by_tag tag
      subclass = nil
      ObjectSpace.each_object(singleton_class) do |k|
        subclass = k if k.superclass == self and k::TAG == tag
      end
      subclass
    end

    def self.name_by_tag tag
      self.by_tag(tag).name.split("::").last.sub(/Instruction$/, "").sub(/^(.)/){$1.downcase}.gsub(/([A-Z])/){ "_#{$1.downcase}" }
    end
  end

  class UnreachableInstruction < Instruction
    TAG = 0x00
  end

  class NopInstruction < Instruction
    TAG = 0x01
  end

  class BlockInstruction < Instruction
    TAG = 0x02

    attr_accessor :blocktype, :instructions

    def to_hash
      {
        :name => "block",
        :instructions => @instructions.map {|i| i.to_hash}
      }
    end
  end

  class LoopInstruction < Instruction
    TAG = 0x03

    attr_accessor :blocktype, :instructions

    def to_hash
      {
        :name => "block",
        :instructions => @instructions.map {|i| i.to_hash}
      }
    end
  end

  class IfInstruction < Instruction
    TAG = 0x04

    attr_accessor :blocktype, :then_instructions, :else_instructions

    def to_hash
      h = {
        :name => "if",
        :then => @then_instructions.map {|i| i.to_hash},
      }
      h[:else] = @else_instructions.map {|i| i.to_hash} if @else_instructions
      h
    end
  end

  class BrInstruction < Instruction
    TAG = 0x0c

    attr_accessor :labelidx

    def to_hash
      {
        :name => "br",
        :labelidx => @labelidx
      }
    end
  end

  class BrIfInstruction < Instruction
    TAG = 0x0d

    attr_accessor :labelidx

    def to_hash
      {
        :name => "br_if",
        :labelidx => @labelidx
      }
    end
  end

  class ReturnInstruction < Instruction
    TAG = 0x0e
  end

  class CallInstruction < Instruction
    TAG = 0x10

    attr_accessor :funcidx

    def to_hash
      {
        :name => "call",
        :funcidx => @funcidx
      }
    end
  end

  class CallIndirectInstruction < Instruction
    TAG = 0x11

    attr_accessor :typeidx, :tableidx

    def to_hash
      {
        :name => "call_indirect",
        :typeidx => @typeidx,
        :tableidx => @tableidx
      }
    end
  end

  class RefNullInstruction < Instruction
    TAG = 0xd0
  end

  class RefIsNullInstruction < Instruction
    TAG = 0xd1
  end

  class RefFuncInstruction < Instruction
    TAG = 0xd2
  end

  class DropInstruction < Instruction
    TAG = 0x1a
  end

  class SelectInstruction < Instruction
    TAG = 0x1b
  end

  class SelectTypesInstruction < Instruction
    TAG = 0x1c
  end

  class LocalGetInstruction < Instruction
    TAG = 0x20

    attr_accessor :index

    def to_hash
      {
        :name => "local.get",
        :index => @index
      }
    end
  end

  class LocalSetInstruction < Instruction
    TAG = 0x21

    attr_accessor :index

    def to_hash
      {
        :name => "local.set",
        :index => @index
      }
    end
  end

  class LocalTeeInstruction < Instruction
    TAG = 0x22

    attr_accessor :index

    def to_hash
      {
        :name => "local.tee",
        :index => @index
      }
    end
  end

  class GlobalGetInstruction < Instruction
    TAG = 0x23

    attr_accessor :index

    def to_hash
      {
        :name => "global.get",
        :index => @index
      }
    end
  end

  class GlobalSetInstruction < Instruction
    TAG = 0x24

    attr_accessor :index

    def to_hash
      {
        :name => "global.set",
        :index => @index
      }
    end
  end

  class TableGetInstruction < Instruction
    TAG = 0x25
  end

  class TableSetInstruction < Instruction
    TAG = 0x26
  end

  class TableInitInstruction < Instruction
    TAG = 0xFC
    SUBTAG = 12
  end

  #..snip..

  class I32LoadInstruction < Instruction
    TAG = 0x28

    attr_accessor :memarg

    def to_hash
      {
        :name => "i32.load",
        :memarg => @memarg.to_hash
      }
    end
  end

  class I32Load8sInstruction < Instruction
    TAG = 0x2c

    attr_accessor :memarg
  end

  class I32Load8uInstruction < Instruction
    TAG = 0x2d

    attr_accessor :memarg
  end

  class I32Load16sInstruction < Instruction
    TAG = 0x2c

    attr_accessor :memarg
  end

  class I32Load16uInstruction < Instruction
    TAG = 0x2d

    attr_accessor :memarg
  end

  class I32StoreInstruction < Instruction
    TAG = 0x36

    attr_accessor :memarg

    def to_hash
      {
        :name => "i32.store",
        :memarg => @memarg.to_hash
      }
    end
  end

  class I32Store8Instruction < Instruction
    TAG = 0x3a

    attr_accessor :memarg
  end

  class I32Store16Instruction < Instruction
    TAG = 0x3b

    attr_accessor :memarg
  end

  class MemorySizeInstruction < Instruction
    TAG = 0x3f
  end

  class MemoryGrowInstruction < Instruction
    TAG = 0x40
  end

  class MemoryInitInstruction < Instruction
    TAG = 0xFC
    SUBTAG = 8
  end

  #..snip..

  class I32ConstInstruction < Instruction
    TAG = 0x41

    attr_accessor :value

    def to_hash
      {
        :name => "i32.const",
        :value => @value
      }
    end
  end

  class I32EqzInstruction < Instruction
    TAG = 0x45

    def to_hash
      {
        :name => "i32.eqz"
      }
    end
  end

  class I32EqInstruction < Instruction
    TAG = 0x46
  end

  class I32NeInstruction < Instruction
    TAG = 0x47
  end

  class I32LtsInstruction < Instruction
    TAG = 0x48
  end

  class I32LtuInstruction < Instruction
    TAG = 0x49
  end

  class I32GtsInstruction < Instruction
    TAG = 0x4a

    def to_hash
      {
        :name => "i32.gts"
      }
    end
  end

  class I32GtuInstruction < Instruction
    TAG = 0x4b
  end

  class I32LesInstruction < Instruction
    TAG = 0x4c
  end

  class I32LeuInstruction < Instruction
    TAG = 0x4d
  end

  class I32GesInstruction < Instruction
    TAG = 0x4e
  end

  class I32GeuInstruction < Instruction
    TAG = 0x4f
  end

  class I32ClzInstruction < Instruction
    TAG = 0x67
  end

  class I32CtzInstruction < Instruction
    TAG = 0x68
  end

  class I32PopcntInstruction < Instruction
    TAG = 0x69
  end

  class I32AddInstruction < Instruction
    TAG = 0x6a

    def to_hash
      {
        :name => "i32.add"
      }
    end
  end

  class I32SubInstruction < Instruction
    TAG = 0x6b

    def to_hash
      {
        :name => "i32.sub"
      }
    end
  end

  class I32MulInstruction < Instruction
    TAG = 0x6c

    def to_hash
      {
        :name => "i32.mul"
      }
    end
  end

  class I32DivsInstruction < Instruction
    TAG = 0x6d

    def to_hash
      {
        :name => "i32.div_s"
      }
    end
  end

  class I32DivuInstruction < Instruction
    TAG = 0x6e

    def to_hash
      {
        :name => "i32.div_u"
      }
    end
  end

  class I32RemsInstruction < Instruction
    TAG = 0x6f
  end

  class I32RemuInstruction < Instruction
    TAG = 0x70
  end

  class I32AndInstruction < Instruction
    TAG = 0x71

    def to_hash
      {
        :name => "i32.and"
      }
    end
  end

  class I32OrInstruction < Instruction
    TAG = 0x72
  end

  class I32XorInstruction < Instruction
    TAG = 0x73
  end

  class I32ShlInstruction < Instruction
    TAG = 0x74
  end

  class I32ShrsInstruction < Instruction
    TAG = 0x75
  end

  class I32ShruInstruction < Instruction
    TAG = 0x76
  end

  class I32RotlInstruction < Instruction
    TAG = 0x77
  end

  class I32RotrInstruction < Instruction
    TAG = 0x78
  end

  class Memarg
    attr_accessor :align, :offset

    def to_hash
      {
        :align => @arign,
        :offset => @offset
      }
    end
  end

  class Data
    attr_accessor :memidx, :expressions, :bytes

    def initialize
      @bytes = []
    end

    def add_byte byte
      @bytes.push byte
    end

    def to_hash
      h = {
        :bytes => @bytes
      }
      h[:expressions] = @expressions.map {|e| e.to_hash} if @expressions
      h[:memidx] = @memidx if @memidx
      h
    end
  end
end