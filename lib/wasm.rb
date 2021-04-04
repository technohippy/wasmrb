TAG_FUNCTYPE = 0x60

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

def read_expressions data
  raise :TODO
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
  :code
end

def read_data_section data 
  :data
end

def read_datacount_section data 
  :datacount
end

data = []
#File.open("fizzbuzz.wasm") do |f|
File.open("hw.wasm") do |f|
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