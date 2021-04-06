TAG_FUNCTYPE = 0x60
BLOCK_END = 0x0b
THEN_END = 0x05

SECTION_NAMES = {
  0 => :custom,
  1 => :type,
  2 => :import,
  3 => :function,
  4 => :table,
  5 => :memory,
  6 => :global,
  7 => :export,
  8 => :start,
  9 => :element,
  10 => :code,
  11 => :data,
  12 => :datacount,
}

NUM_TYPES = {
  0x7c => :f64,
  0x7d => :f32,
  0x7e => :i64,
  0x7f => :i32,
}

REF_TYPES = {
  0x70 => :funcref,
  0x6f => :externref,
}

IMPORT_TYPES = {
  0x00 => :type,
  0x01 => :table,
  0x02 => :mem,
  0x03 => :global
}

EXPORT_TYPES = {
  0x00 => :func,
  0x01 => :table,
  0x02 => :mem,
  0x03 => :global
}

INST_UNREACHABLE = 0x00
INST_NOP = 0x01
INST_BLOCK = 0x02
INST_LOOP = 0x03
INST_IF = 0x04
INST_BR = 0x0c
INST_BR_IF = 0x0d
INST_BR_TABLE = 0x0e
INST_RETURN = 0x0f
INST_CALL = 0x10
INST_CALL_INDIRECT = 0x11

INST_REF_NULL = 0xd0
INST_REF_IS_NULL = 0xd1
INST_REF_FUNC = 0xd2

INST_PARAM_DROP = 0x1a
INST_PARAM_SELECT = 0x1b
INST_PARAM_SELECT_VALTYPE = 0x1c

INST_LOCAL_GET = 0x20
INST_LOCAL_SET = 0x21
INST_LOCAL_TEE = 0x22
INST_GLOBAL_GET = 0x23
INST_GLOBAL_SET = 0x24

INST_TABLE_GET = 0x25
INST_TABLE_SET = 0x26

# memory
INST_I32_LOAD = 0x28
INST_I64_LOAD = 0x29
INST_F32_LOAD = 0x2a
INST_F64_LOAD = 0x2b
INST_I32_LOAD8S = 0x2c
INST_I32_LOAD8U = 0x2d
INST_I32_LOAD16S = 0x2e
INST_I32_LOAD16U = 0x2f
INST_I64_LOAD8S = 0x30
INST_I64_LOAD8U = 0x31
INST_I64_LOAD16S = 0x32
INST_I64_LOAD16U = 0x33
INST_I64_LOAD32S = 0x34
INST_I64_LOAD32U = 0x35

INST_I32_STORE = 0x36
INST_I64_STORE = 0x37
INST_F32_STORE = 0x38
INST_F64_STORE = 0x39
INST_I32_STORE8 = 0x3a
INST_I32_STORE16 = 0x3b
INST_I64_STORE8 = 0x3c
INST_I64_STORE16 = 0x3d
INST_I64_STORE32 = 0x3e

INST_MEMORY_SIZE = 0x3f
INST_MEMORY_GROW = 0x40

# numeric
INST_I32_CONST = 0x41
INST_I32_EQZ = 0x45
INST_I32_EQ = 0x46
INST_I32_NE = 0x47
INST_I32_LTS = 0x48
INST_I32_LTU = 0x49
INST_I32_GTS = 0x4a
INST_I32_GTU = 0x4b
INST_I32_LES = 0x4c
INST_I32_LEU = 0x4d
INST_I32_GES = 0x4e
INST_I32_GEU = 0x4f

INST_I32_CLZ = 0x67
INST_I32_CTZ = 0x68
INST_I32_POPCNT = 0x69
INST_I32_ADD = 0x6a
INST_I32_SUB = 0x6b
INST_I32_MUL = 0x6c
INST_I32_DIVS = 0x6d
INST_I32_DIVU = 0x6e
INST_I32_REMS = 0x6f
INST_I32_REMU = 0x70
INST_I32_AND = 0x71
INST_I32_OR = 0x72
INST_I32_XOR = 0x73
INST_I32_SHL = 0x74
INST_I32_SHRS = 0x75
INST_I32_SHRU = 0x76
INST_I32_ROTL = 0x77
INST_I32_ROTR = 0x78

INST_OTHERS = 0xfc
INST_SUB_MEMORY_INIT = 8
INST_SUB_DATA_DROP = 9
INST_SUB_MEMORY_COPY = 10
INST_SUB_MEMORY_FILLT = 11
INST_SUB_TABLE_INIT = 12
INST_SUB_ELEM_DROP = 13
INST_SUB_TABLE_COPY = 14
INST_SUB_TABLE_GROW = 15
INST_SUB_TABLE_SIZE = 16
INST_SUB_TABLE_FILL = 17

=begin
# common

def read_leb128 data
  num = 0
  fig = 0
  loop do
    part = data.shift
    last = part < 128
    part = (part & 0b01111111) << fig
    num = num | part
    fig += 7
    break if last
  end
  num
end

alias read_num read_leb128

def read_name data
  bytes = read_vec data do |dt|
    read_byte dt
  end
  bytes.pack("U*")
end

def read_vec data, &readfunc
  vec = []
  read_num(data).times do
    vec.push readfunc.call(data)
  end
  vec
end

def read_byte data
  data.shift
end

#

def read_module data
  {
    :magic => read_magic(data),
    :version => read_version(data),
    :sections => read_sections(data),
  }
end

def read_magic data
  magic_data = data.shift(4)
  raise "invalid magic: #{magic_data}" unless magic_data == [0x00, 0x61, 0x73, 0x6d]
  magic_data
end

def read_version data
  version_data = data.shift(4)
  raise "invalid version: #{version_data}" unless version_data == [0x01, 0x00, 0x00, 0x00]
  version_data
end

def read_sections data
  sections = []
  loop do
    break if data.empty?
    sections.push read_section(data)
  end
  sections
end

def read_section data
  secid, length = read_section_header data
  section_data = data.shift length
  section = send("read_#{SECTION_NAMES[secid]}_section", section_data)
  section
end

def read_section_header data
  secid = data.shift
  length = read_num data
  [secid, length]
end

def read_custom_section data 
  name = read_name data
  {
    :custom => {
      :name => name,
      :data => "**omit**" #data
    }
  }
end

def read_type_section data 
  types = []
  type_num = read_num data
  type_num.times do
    types.push read_functype(data)
  end
  {
    :type => types
  }
end

def read_functype data
  tag = data.shift
  raise "invalid functype: #{tag}" unless tag == TAG_FUNCTYPE
  paramtype = read_resulttype data
  resulttype = read_resulttype data
  {
    :params => paramtype,
    :results => resulttype,
  }
end

def read_resulttype data
  resulttype = read_vec data do |dt|
    read_valtype dt
  end
  resulttype
end

def read_valtype data
  num = read_num data
  NUM_TYPES[num] || REF_TYPES[num]
end

def read_import_section data 
  imports = read_vec data do |dt|
    read_import dt
  end
  {
    :import => imports
  }
end

def read_import data
  mod = read_name data
  name = read_name data
  importtype = data.shift
  import = send "read_#{IMPORT_TYPES[importtype]}_import", data
  {
    :mod => mod,
    :name => name,
    :type => importtype,
    :import => import
  }
end

def read_type_import data
  index = read_num data
  {
    :type => index
  }
end

def read_table_import data
  reftype = read_num data
  limits = read_limits data
  {
    :table => {
      :reftype => reftype,
      :limits => limits
    }
  }
end

def read_mem_import data
  limits = read_limits data
  {
    :mem => limits
  }
end

def read_limits data
  type = data.shift
  if type == 0
    {
      :min => read_num(data)
    }
  elsif type == 1
    {
      :min => read_num(data),
      :max => read_num(data)
    }
  else
    raise "invalid limit type: #{type}"
  end
end

def read_global_import data
  global = read_global_type data
  {
    :global => global
  }
end

def read_global_type data
  valuetype = read_valtype data
  mut = read_mut data
  {
    :valuetype => valuetype,
    :mut => mut
  }
end

def read_mut data
  type = read_num data
  if type == 0
    :const
  elsif type == 1
    :mut
  else
    raise "invalid mut: #{type}"
  end
end

def read_function_section data 
  typeidx = read_vec data do |dt|
    read_num data
  end
  {
    :function => typeidx
  }
end

def read_table_section data 
  tables = read_vec data do |dt|
    read_tabletype dt
  end
  {
    :table => tables
  }
end

def read_tabletype data
  limits = read_limits data
  reftype = read_num data
  {
    :limits => limits,
    :reftype => REF_TYPES[reftype]
  }
end

def read_memory_section data 
  memories = read_vec data do |dt|
    read_memtype dt
  end
end

def read_memtype data
  limits = read_limits data
  {
    :limits => limits
  }
end

def read_global_section data 
  globals = read_vec data do |dt|
    read_global dt
  end
  {
    :global => globals
  }
end

def read_global data
  global_type = read_global_type data
  expressions = read_expressions data
end

def read_export_section data 
  exports = read_vec data do |dt|
    read_export dt
  end
  {
    :export => exports
  }
end

def read_export data
  name = read_name data
  type = read_num data
  index = read_num data
  {
    :name => name,
    EXPORT_TYPES[type] => index
  }
end

def read_start_section data 
  starts = read_vec data do |dt|
    read_start dt
  end
  {
    :start => starts
  }
end

def read_start data
  idx = read_num data
  {
    :func => idx
  }
end

def read_element_section data 
  raise :TODO
end

def read_code_section data 
  codes = read_vec data do |dt|
    read_code dt
  end
  {
    :code => codes
  }
end

def read_code data
  size = read_num data
  func_data = data.shift size
  locals = read_vec func_data do |dt|
    read_locals dt
  end
  expressions = read_expressions func_data
  {
    :locals => locals,
    :expr => expressions
  }
end

def read_locals data
  count = read_num data
  valtype = read_valtype dt
  {
    valtype => count
  }
end

def read_expressions data
  _, instructions = read_instructions data do |t|
    t == BLOCK_END
  end
  instructions
end

def read_instructions data, &end_cond
  instructions = []
  loop do
    break if end_cond.call(data[0])
    instructions.push read_instruction(data)
  end
  end_tag = data.shift # remove end_tag
  [end_tag, instructions]
end

def read_instruction data
  tag = data.shift
  case tag
  when INST_BLOCK
    read_inst_block data
  when INST_LOOP
    read_inst_loop data
  when INST_IF
    read_inst_if data
  when INST_BR
    read_inst_br data
  when INST_BR_IF
    read_inst_br_if data
  when INST_CALL
    read_inst_call data
  when INST_LOCAL_GET
    read_inst_local_get data
  when INST_LOCAL_SET
    read_inst_local_set data
  when INST_GLOBAL_GET
    read_inst_global_get data
  when INST_GLOBAL_SET
    read_inst_global_set data
  when INST_I32_LOAD
    read_inst_i32_load data
  when INST_I32_STORE
    read_inst_i32_store data
  when INST_I32_CONST
    read_inst_i32_const data
  when INST_I32_EQZ
    read_inst_i32_eqz data
  when INST_I32_EQ
    read_inst_i32_eq data
  when INST_I32_NE
    read_inst_i32_ne data
  when INST_I32_ADD
    read_inst_i32_add data
  when INST_I32_SUB
    read_inst_i32_sub data
  when INST_I32_MUL
    read_inst_i32_mul data
  else
    #raise "unknown tag: #{tag.to_s(16)}"
  end
end

def read_inst_block data
  bt = read_blocktype data
  exprs = read_expressions data
  {
    :block => {
      :bt => bt,
      :in => exprs
    }
  }
end

def read_blocktype data
  return data.shift if data[0] == 0x40
  valtype = read_valtype data
  return valtype if valtype
  read_s33
end

def read_s33 data
  raise "not yet implemented"
end

def read_inst_loop data
  bt = read_blocktype data
  exprs = read_expressions data
  {
    :loop => {
      :bt => bt,
      :in => exprs
    }
  }
end

def read_inst_if data
  bt = read_blocktype data
  end_tag, then_exprs = read_instructions data do |t|
    t == BLOCK_END || t == THEN_END
  end
  if end_tag == BLOCK_END
    {
      :if => {
        :bt => bt,
        :then => then_exprs
      }
    }
  else
    else_exprs = read_expressions data
    {
      :if => {
        :bt => bt,
        :then => then_exprs,
        :else => else_exprs
      }
    }
  end
end

def read_inst_br data
  labelidx = read_num data
  {
    :br => labelidx
  }
end

def read_inst_br_if data
  labelidx = read_num data
  {
    :br_if => labelidx
  }
end

def read_inst_call data
  funcidx = read_num data
  {
    :call => funcidx
  }
end

def read_inst_local_get data
  val = read_num data
  {
    :"local.get" => val
  }
end

def read_inst_local_set data
  val = read_num data
  {
    :"local.set" => val
  }
end

def read_inst_global_get data
  val = read_num data
  {
    :"global.get" => val
  }
end

def read_inst_global_set data
  val = read_num data
  {
    :"global.set" => val
  }
end

def read_inst_i32_load data
  val = read_memarg data
  {
    :"i32.load" => val
  }
end

def read_memarg data
  align = read_num data
  offset = read_num data
  {
    :align => align,
    :offset => offset
  }
end

def read_inst_i32_store data
  val = read_memarg data
  {
    :"i32.store" => val
  }
end

def read_inst_i32_const data
  val = read_num data
  {
    :"i32.const" => val
  }
end

def read_inst_i32_eqz data
  :"i32.eqz"
end

def read_inst_i32_eq data
  :"i32.eq"
end

def read_inst_i32_ne data
  :"i32.ne"
end

def read_inst_i32_add data
  :"i32.add"
end

def read_inst_i32_sub data
  :"i32.sub"
end

def read_inst_i32_mul data
  :"i32.mul"
end

def read_data_section data 
  :data
end

def read_datacount_section data 
  :datacount
end

data = []
File.open("spec/data/echo.wasm") do |f|
#File.open("spec/data/fizzbuzz.wasm") do |f|
#File.open("spec/data/hw.wasm") do |f|
  begin
    loop do
      data.push f.readbyte
    end
  rescue => e
    nil
  end
end

mod = read_module data

require "pp"
pp mod
=end

require "pp"
require_relative "./wasm/loader.rb"

loader = WebAssembly::Loader.new "spec/data/hw.wasm"
#loader = WebAssembly::Loader.new "spec/data/change.wasm"
mod = loader.load
pp mod.to_hash

=begin
import_objects = {
  :rb => {
    :log => lambda {|msg| p msg}
  }
}
inst = mod.instantiate import_objects # 関数とかの参照を実体と差し替える
inst.exports.run_something "wasm"
inst.run_something "wasm"
=end