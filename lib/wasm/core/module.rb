require_relative "./instance.rb"

module WebAssembly
  class Module
    MAGIC = [0x00, 0x61, 0x73, 0x6d]
    VERSION = [0x01, 0x00, 0x00, 0x00]

    attr_accessor :magic, :version, :sections

    def initialize sections=[]
      @magic = MAGIC
      @version = VERSION
      @sections = sections
    end

    def magic=(magic)
      raise StandardError.new("invalid magic: #{magic}") unless magic == [0x00, 0x61, 0x73, 0x6d]
      @magic = magic
    end

    def version=(version)
      raise StandardError.new("invalid version: #{version}") unless version == [0x01, 0x00, 0x00, 0x00]
      @version = version
    end

    def add_section section
      @sections.push section
    end

    def section_by_name name
      @sections.find do |sec|
        sec.class.name.split("::").last.sub(/Section$/, "").downcase == name
      end
    end

    %w(custom type import function table memory global
      export start element code data datacount).each do |name|
      define_method "#{name}_section" do
        section_by_name name
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

    alias inspect to_hash
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
      h = {
        :section => Section.name_by_id(@id),
        :id => @id,
      }
      h[:size] = @size if @size
      h
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

    attr_accessor :functypes

    def initialize
      @id = ID
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

    attr_accessor :imports

    def initialize
      @id = ID
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

    attr_accessor :type_indices

    def initialize indices=[]
      @id = ID
      @type_indices = indices
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

    attr_reader :tabletypes

    def initialize
      @id = ID
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

    attr_reader :memtypes

    def initialize
      @id = ID
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

    attr_reader :globals

    def initialize
      @id = ID
      @globals = []
    end

    def add_global global
      @globals.push global
    end

    def to_hash
      super.to_hash.merge({
        :globals => @globals.map {|g| g.to_hash}
      })
    end
  end

  class ExportSection < Section
    ID = 7

    attr_reader :exports

    def initialize
      @id = ID
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

    attr_reader :starts

    def initialize
      @id = ID
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

    attr_reader :elements

    def initialize
      @id = ID
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

    attr_accessor :codes

    def initialize
      @id = ID
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
      @id = ID
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

    def initialize params=[], results=[]
      @params = params
      @results = results
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

    def retrieve import_object
      import_object[@mod.to_sym][@name.to_sym]
    end

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
          :reftype => @reftype,
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

    def to_hash
      h = {
        :globaltype => @globaltype.to_hash,
        :expression => @expr.map {|e| e.to_hash}
      }
    end
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

    def initialize index=nil
      @index = index
    end
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
    attr_accessor :tag, :funcidxs, :expression

    def initialize
      @funcidxs = []
    end

    def add_funcidx funcidx
      @funcidxs.push funcidx
    end

    def to_hash
      {
        :funcidx => @funcidxs,
        :expression => @expression.map {|e| e.to_hash}
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

    def add_expression expression
      @expressions.push expression
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

    def to_hash
      {
        :count => @count,
        :valtype => @valtype
      }
    end
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
      kls = self.by_tag(tag)
      raise StandardError.new("invalid instruction tag: #{tag}") unless kls
      kls.name.split("::").last.sub(/Instruction$/, "").sub(/^(.)/){$1.downcase}.gsub(/([A-Z])/){ "_#{$1.downcase}" }
    end

    def call context
			raise StandardError.new("not yet implemented: #{self.class.name}")
    end
  end

  class UnreachableInstruction < Instruction
    TAG = 0x00

    def call context
      raise StandardError.new("unreachable op")
    end

    def to_hash
      {
        :name => "unreachable",
      }
    end
  end

  class NopInstruction < Instruction
    TAG = 0x01

    def call context
      # nop
    end

    def to_hash
      {
        :name => "nop",
      }
    end
  end

  class BlockInstruction < Instruction
    TAG = 0x02

    attr_accessor :blocktype, :instructions

    def call context
      br = false
      loop do
        context.depth += 1
        context.branch = -1
        @instructions.each do |instr|
          instr.call context
          if 0 <= context.branch
            context.branch -= 1
            br = true
            break
          end
        end
        context.depth -= 1
        break if br
      end
    end

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

    def call context
      br = false
      loop do
        context.depth += 1
        context.branch = -1
        @instructions.each do |instr|
          instr.call context
          if 0 < context.branch
            context.branch -= 1
            br = true
            break
          end
        end
        context.depth -= 1
        break if br
      end
    end

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

    def call context
      if context.stack.pop != 0
        @then_instructions.each do |instr|
          instr.call context
        end
      elsif not @else_instructions.nil?
        @else_instructions.each do |instr|
          instr.call context
        end
      end
    end

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

    def call context
      context.branch = @labelidx
    end

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

    def call context
      cond = context.stack.pop
      unless cond == 0
        context.branch = @labelidx
      end
    end

    def to_hash
      {
        :name => "br_if",
        :labelidx => @labelidx
      }
    end
  end

  class BrTableInstruction < Instruction
    TAG = 0x0e

    attr_accessor :labelidxs, :labelidx

    def initialize
      @labelidxs = []
    end

    def add_labelidx labelidx
      @labelidxs.push labelidx
    end

    def call context
      table = [*@labelidxs]
      table.push @labelidx
      index = context.stack.pop
      context.branch = table[index]
    end

    def to_hash
      {
        :name => "br_table",
        :labelidxs => @labelidxs,
        :labelidx => @labelidx
      }
    end
  end

  class ReturnInstruction < Instruction
    TAG = 0x0f

    def call context
      context.branch = context.depth
    end

    def to_hash
      {
        :name => "return",
      }
    end
  end

  class CallInstruction < Instruction
    TAG = 0x10

    attr_accessor :funcidx

    def initialize funcidx=nil
      @funcidx = funcidx
    end

    def call context
      func = context.functions[@funcidx]
      func.call context
    end

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

    def call context
      # TODO: must check typeidx
      table = context.tables[@tableidx]
      funcidx = context.stack.pop
      func = table[funcidx]
      raise StandardError.new("invalid funcidx: #{funcidx}") unless func
      func.call context
    end

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

    attr_accessor :reftype

    def to_hash
      {
        :name => "ref.null",
        :reftype => @reftype
      }
    end
  end

  class RefIsNullInstruction < Instruction
    TAG = 0xd1

    def to_hash
      {
        :name => "ref.is_null",
      }
    end
  end

  class RefFuncInstruction < Instruction
    TAG = 0xd2

    attr_accessor :funcidx

    def to_hash
      {
        :name => "ref.func",
        :funcidx => @funcidx
      }
    end
  end

  class DropInstruction < Instruction
    TAG = 0x1a

    def to_hash
      {
        :name => "drop",
      }
    end
  end

  class SelectInstruction < Instruction
    TAG = 0x1b

    def to_hash
      {
        :name => "select",
      }
    end
  end

  class SelectTypesInstruction < Instruction
    TAG = 0x1c
    
    attr_accessor :valtypes

    def to_hash
      {
        :name => "select t*",
        :valtypes => @valtypes
      }
    end
  end

  class LocalGetInstruction < Instruction
    TAG = 0x20

    attr_accessor :index

    def initialize index=nil
      @index = index
    end

    def call context
      context.stack.push context.locals[index]
    end

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

    def call context
      context.locals[index] = context.stack.pop
    end

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

    def call context
      context.locals[index] = context.peep_stack
    end

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

    def call context
      context.stack.push context.globals[@index].value
    end

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

    def call context
      context.globals[@index] = Context::Global.new(0) unless context.globals[@index] # TODO
      context.globals[@index].value = context.stack.pop
    end

    def to_hash
      {
        :name => "global.set",
        :index => @index
      }
    end
  end

  class TableGetInstruction < Instruction
    TAG = 0x25

    attr_accessor :tableidx

    def to_hash
      {
        :name => "table.get",
        :tableidx => @tableidx
      }
    end
  end

  class TableSetInstruction < Instruction
    TAG = 0x26

    attr_accessor :tableidx

    def to_hash
      {
        :name => "table.set",
        :tableidx => @tableidx
      }
    end
  end

  class TableInitInstruction < Instruction
    TAG = 0xFC
    SUBTAG = 12

    attr_accessor :elemidx, :tableidx

    def to_hash
      {
        :name => "table.init",
        :elemidx => @elemidx,
        :tableidx => @tableidx
      }
    end
  end

  class ElemDropInstruction < Instruction
    TAG = 0xFC
    SUBTAG = 13

    attr_accessor :elemidx

    def to_hash
      {
        :name => "elem.drop",
        :elemidx => @elemidx,
      }
    end
  end

  class TableCopyInstruction < Instruction
    TAG = 0xFC
    SUBTAG = 14

    attr_accessor :tableidx1, :tableidx2

    def to_hash
      {
        :name => "table.copy",
        :elemidx => @elemidx,
        :tableidx1 => @tableidx1,
        :tableidx2 => @tableidx2
      }
    end
  end

  class TableGrowInstruction < Instruction
    TAG = 0xFC
    SUBTAG = 15

    attr_accessor :tableidx

    def to_hash
      {
        :name => "table.grow",
        :tableidx => @tableidx
      }
    end
  end

  class TableSizeInstruction < Instruction
    TAG = 0xFC
    SUBTAG = 16

    attr_accessor :tableidx

    def to_hash
      {
        :name => "table.size",
        :tableidx => @tableidx
      }
    end
  end

  class TableFillInstruction < Instruction
    TAG = 0xFC
    SUBTAG = 17

    attr_accessor :tableidx

    def to_hash
      {
        :name => "table.fill",
        :tableidx => @tableidx
      }
    end
  end

  class I32LoadInstruction < Instruction
    TAG = 0x28

    attr_accessor :memarg

    def call context
      memory = context.memories[0] # TODO: all memory instructions implicitly operate on memory index 0.
      position = context.stack.pop
      context.stack.push memory[position + memarg.offset]
    end

    def to_hash
      {
        :name => "i32.load",
        :memarg => @memarg.to_hash
      }
    end
  end

  class F64LoadInstruction < Instruction
    TAG = 0x2b

    attr_accessor :memarg

    def call context
      memory = context.memories[0] # TODO: all memory instructions implicitly operate on memory index 0.
      position = context.stack.pop + memarg.offset
      bytes = memory[position...position+8]
      context.stack.push bytes.pack("C*").unpack("d")[0]
    end

    def to_hash
      {
        :name => "f64.load",
        :memarg => @memarg.to_hash
      }
    end
  end

  class I32Load8sInstruction < Instruction
    TAG = 0x2c

    attr_accessor :memarg

    def to_hash
      {
        :name => "i32.load8_s",
        :memarg => @memarg.to_hash
      }
    end
  end

  class I32Load8uInstruction < Instruction
    TAG = 0x2d

    attr_accessor :memarg

    def to_hash
      {
        :name => "i32.load8_u",
        :memarg => @memarg.to_hash
      }
    end
  end

  class I32Load16sInstruction < Instruction
    TAG = 0x2c

    attr_accessor :memarg

    def to_hash
      {
        :name => "i32.load16_s",
        :memarg => @memarg.to_hash
      }
    end
  end

  class I32Load16uInstruction < Instruction
    TAG = 0x2d

    attr_accessor :memarg

    def to_hash
      {
        :name => "i32.load16_u",
        :memarg => @memarg.to_hash
      }
    end
  end

  class I32StoreInstruction < Instruction
    TAG = 0x36

    attr_accessor :memarg

    def call context
      memory = context.memories[0] # TODO: all memory instructions implicitly operate on memory index 0.
      value = context.stack.pop
      position = context.stack.pop
      memory[position + memarg.offset] = value
    end

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

    def to_hash
      {
        :name => "i32.store8",
        :memarg => @memarg.to_hash
      }
    end
  end

  class I32Store16Instruction < Instruction
    TAG = 0x3b

    attr_accessor :memarg

    def to_hash
      {
        :name => "i32.store16",
        :memarg => @memarg.to_hash
      }
    end
  end

  class MemorySizeInstruction < Instruction
    TAG = 0x3f

    attr_accessor :placeholder

    def to_hash
      {
        :name => "memory.size",
      }
    end
  end

  class MemoryGrowInstruction < Instruction
    TAG = 0x40

    attr_accessor :placeholder

    def to_hash
      {
        :name => "memory.grow",
      }
    end
  end

  class MemoryInitInstruction < Instruction
    TAG = 0xFC
    SUBTAG = 8

    attr_accessor :dataidx, :placeholer

    def to_hash
      {
        :name => "memory.init",
        :dataidx => @dataidx
      }
    end
  end

  class DataDropInstruction < Instruction
    TAG = 0xFC
    SUBTAG = 9

    attr_accessor :dataidx

    def to_hash
      {
        :name => "data.drop",
        :dataidx => @dataidx
      }
    end
  end

  class MemoryCopyInstruction < Instruction
    TAG = 0xFC
    SUBTAG = 10

    attr_accessor :placeholder1, :placeholer2

    def to_hash
      {
        :name => "memory.copy",
      }
    end
  end

  class MemoryFillInstruction < Instruction
    TAG = 0xFC
    SUBTAG = 11

    attr_accessor :placeholder

    def to_hash
      {
        :name => "memory.fill",
      }
    end
  end

  class I32ConstInstruction < Instruction
    TAG = 0x41

    attr_accessor :value

    def initialize value=nil
      @value = value
    end

    def call context
      context.stack.push value
    end

    def to_hash
      {
        :name => "i32.const",
        :value => @value
      }
    end
  end

  class F64ConstInstruction < Instruction
    TAG = 0x44

    attr_accessor :value

    def initialize value=nil
      @value = value
    end

    def call context
      context.stack.push value
    end

    def to_hash
      {
        :name => "f64.const",
        :value => @value
      }
    end
  end

  class I32EqzInstruction < Instruction
    TAG = 0x45

    def call context
      val = context.stack.pop
      context.stack.push(if val == 0 then 1 else 0 end)
    end

    def to_hash
      {
        :name => "i32.eqz"
      }
    end
  end

  class I32EqInstruction < Instruction
    TAG = 0x46

    def call context
      rhs = context.stack.pop
      lhs = context.stack.pop
      context.stack.push(if lhs == rhs then 1 else 0 end)
    end

    def to_hash
      {
        :name => "i32.eq"
      }
    end
  end

  class I32NeInstruction < Instruction
    TAG = 0x47

    def call context
      rhs = context.stack.pop
      lhs = context.stack.pop
      context.stack.push(if lhs != rhs then 1 else 0 end)
    end

    def to_hash
      {
        :name => "i32.ne"
      }
    end
  end

  class I32LtsInstruction < Instruction
    TAG = 0x48

    def call context
      # TODO: signed
      rhs = context.stack.pop
      lhs = context.stack.pop
      context.stack.push(if lhs < rhs then 1 else 0 end)
    end

    def to_hash
      {
        :name => "i32.lt_s"
      }
    end
  end

  class I32LtuInstruction < Instruction
    TAG = 0x49

    def call context
      # TODO: unsigned
      rhs = context.stack.pop
      lhs = context.stack.pop
      context.stack.push(if lhs < rhs then 1 else 0 end)
    end

    def to_hash
      {
        :name => "i32.lt_u"
      }
    end
  end

  class I32GtsInstruction < Instruction
    TAG = 0x4a

    def call context
      # TODO: signed
      rhs = context.stack.pop
      lhs = context.stack.pop
      context.stack.push(if lhs > rhs then 1 else 0 end)
    end

    def to_hash
      {
        :name => "i32.gt_s"
      }
    end
  end

  class I32GtuInstruction < Instruction
    TAG = 0x4b

    def call context
      # TODO: unsigned
      rhs = context.stack.pop
      lhs = context.stack.pop
      context.stack.push(if lhs > rhs then 1 else 0 end)
    end

    def to_hash
      {
        :name => "i32.gt_u"
      }
    end
  end

  class I32LesInstruction < Instruction
    TAG = 0x4c

    def call context
      # TODO: signed
      rhs = context.stack.pop
      lhs = context.stack.pop
      context.stack.push(if lhs <= rhs then 1 else 0 end)
    end

    def to_hash
      {
        :name => "i32.le_s"
      }
    end
  end

  class I32LeuInstruction < Instruction
    TAG = 0x4d

    def call context
      # TODO: unsigned
      rhs = context.stack.pop
      lhs = context.stack.pop
      context.stack.push(if lhs <= rhs then 1 else 0 end)
    end

    def to_hash
      {
        :name => "i32.le_u"
      }
    end
  end

  class I32GesInstruction < Instruction
    TAG = 0x4e

    def call context
      # TODO: signed
      rhs = context.stack.pop
      lhs = context.stack.pop
      context.stack.push(if lhs >= rhs then 1 else 0 end)
    end

    def to_hash
      {
        :name => "i32.ge_s"
      }
    end
  end

  class I32GeuInstruction < Instruction
    TAG = 0x4f

    def call context
      # TODO: unsigned
      rhs = context.stack.pop
      lhs = context.stack.pop
      context.stack.push(if lhs >= rhs then 1 else 0 end)
    end

    def to_hash
      {
        :name => "i32.ge_u"
      }
    end
  end

  class I32ClzInstruction < Instruction
    TAG = 0x67

    def to_hash
      {
        :name => "i32.clz"
      }
    end
  end

  class I32CtzInstruction < Instruction
    TAG = 0x68

    def to_hash
      {
        :name => "i32.ctz"
      }
    end
  end

  class I32PopcntInstruction < Instruction
    TAG = 0x69

    def to_hash
      {
        :name => "i32.popcnt"
      }
    end
  end

  class I32AddInstruction < Instruction
    TAG = 0x6a

    def call context
      rhs = context.stack.pop
      lhs = context.stack.pop
      context.stack.push(lhs+rhs)
    end

    def to_hash
      {
        :name => "i32.add"
      }
    end
  end

  class I32SubInstruction < Instruction
    TAG = 0x6b

    def call context
      rhs = context.stack.pop
      lhs = context.stack.pop
      context.stack.push(lhs-rhs)
    end

    def to_hash
      {
        :name => "i32.sub"
      }
    end
  end

  class I32MulInstruction < Instruction
    TAG = 0x6c

    def call context
      rhs = context.stack.pop
      lhs = context.stack.pop
      context.stack.push(lhs*rhs)
    end

    def to_hash
      {
        :name => "i32.mul"
      }
    end
  end

  class I32DivsInstruction < Instruction
    TAG = 0x6d

    def call context
      # TODO: signed
      rhs = context.stack.pop
      lhs = context.stack.pop
      context.stack.push(lhs/rhs)
    end

    def to_hash
      {
        :name => "i32.div_s"
      }
    end
  end

  class I32DivuInstruction < Instruction
    TAG = 0x6e

    def call context
      # TODO: unsigned
      rhs = context.stack.pop
      lhs = context.stack.pop
      context.stack.push(lhs/rhs)
    end

    def to_hash
      {
        :name => "i32.div_u"
      }
    end
  end

  class I32RemsInstruction < Instruction
    TAG = 0x6f

    def to_hash
      {
        :name => "i32.rem_s"
      }
    end
  end

  class I32RemuInstruction < Instruction
    TAG = 0x70

    def to_hash
      {
        :name => "i32.rem_u"
      }
    end
  end

  class I32AndInstruction < Instruction
    TAG = 0x71

    def call context
      rhs = context.stack.pop
      lhs = context.stack.pop
      context.stack.push(lhs & rhs)
    end

    def to_hash
      {
        :name => "i32.and"
      }
    end
  end

  class I32OrInstruction < Instruction
    TAG = 0x72

    def call context
      rhs = context.stack.pop
      lhs = context.stack.pop
      context.stack.push(lhs | rhs)
    end

    def to_hash
      {
        :name => "i32.or"
      }
    end
  end

  class I32XorInstruction < Instruction
    TAG = 0x73

    def call context
      rhs = context.stack.pop
      lhs = context.stack.pop
      context.stack.push(lhs ^ rhs)
    end

    def to_hash
      {
        :name => "i32.xor"
      }
    end
  end

  class I32ShlInstruction < Instruction
    TAG = 0x74

    def to_hash
      {
        :name => "i32.shl"
      }
    end
  end

  class I32ShrsInstruction < Instruction
    TAG = 0x75

    def to_hash
      {
        :name => "i32.shr_s"
      }
    end
  end

  class I32ShruInstruction < Instruction
    TAG = 0x76

    def to_hash
      {
        :name => "i32.shr_u"
      }
    end
  end

  class I32RotlInstruction < Instruction
    TAG = 0x77

    def to_hash
      {
        :name => "i32.rot_l"
      }
    end
  end

  class I32RotrInstruction < Instruction
    TAG = 0x78

    def to_hash
      {
        :name => "i32.rot_r"
      }
    end
  end

  class I32WrapI64Instruction < Instruction
    TAG = 0xa7

    def to_hash
      {
        :name => "i32.wrap_i64"
      }
    end
  end

  class I32TruncF32sInstruction < Instruction
    TAG = 0xa8

    def to_hash
      {
        :name => "i32.trunc_f32_s"
      }
    end
  end

  class I32TruncF32uInstruction < Instruction
    TAG = 0xa9

    def to_hash
      {
        :name => "i32.trunc_f32_u"
      }
    end
  end

  class I32TruncF64sInstruction < Instruction
    TAG = 0xaa

    def to_hash
      {
        :name => "i32.trunc_f64_s"
      }
    end
  end

  class I32TruncF64uInstruction < Instruction
    TAG = 0xab

    def to_hash
      {
        :name => "i32.trunc_f64_u"
      }
    end
  end

  class I32ReinterpretF32Instruction < Instruction
    TAG = 0xbc

    def to_hash
      {
        :name => "i32.reinterpret_f32"
      }
    end
  end

  class I32Extend8sInstruction < Instruction
    TAG = 0xc0

    def to_hash
      {
        :name => "i32.extend8_s"
      }
    end
  end

  class I32Extend16sInstruction < Instruction
    TAG = 0xc1

    def to_hash
      {
        :name => "i32.extend16_s"
      }
    end
  end

  class I32TruncSatF32sInstruction < Instruction
    TAG = 0xfc
    SUBTAG = 0

    def to_hash
      {
        :name => "i32.trunc_sat_f32_s"
      }
    end
  end

  class I32TruncSatF32uInstruction < Instruction
    TAG = 0xfc
    SUBTAG = 1

    def to_hash
      {
        :name => "i32.trunc_sat_f32_u"
      }
    end
  end

  class I32TruncSatF64sInstruction < Instruction
    TAG = 0xfc
    SUBTAG = 2

    def to_hash
      {
        :name => "i32.trunc_sat_f64_s"
      }
    end
  end

  class I32TruncSatF64uInstruction < Instruction
    TAG = 0xfc
    SUBTAG = 3

    def to_hash
      {
        :name => "i32.trunc_sat_f64_u"
      }
    end
  end

  # ..snip..

  class I64LoadInstruction < Instruction
    TAG = 0x29

    attr_accessor :memarg

    def to_hash
      {
        :name => "i64.load",
        :memarg => @memarg.to_hash
      }
    end
  end

  class I64StoreInstruction < Instruction
    TAG = 0x37

    attr_accessor :memarg

    def to_hash
      {
        :name => "i64.store",
        :memarg => @memarg.to_hash
      }
    end
  end

  class F64AddInstruction < Instruction
    TAG = 0xa0

    def call context
      rhs = context.stack.pop
      lhs = context.stack.pop
      context.stack.push(lhs+rhs)
    end

    def to_hash
      {
        :name => "i32.add"
      }
    end
  end

  class F64SqrtInstruction < Instruction
    TAG = 0x9f

    def to_hash
      {
        :name => "f64.sqrt"
      }
    end
  end

  class F64ConvertI32sInstruction < Instruction
    TAG = 0xb7

    def to_hash
      {
        :name => "f64.convert_i32_s"
      }
    end
  end

  class Memarg
    attr_accessor :align, :offset

    def to_hash
      {
        :align => @align,
        :offset => @offset
      }
      32
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