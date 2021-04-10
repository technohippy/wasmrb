require_relative "../lib/wasm/module.rb"

####

$types = []
$funcs = []
$exports = []
$codes = []

def mod &block
  block.call
  p $types, $funcs, $exports, $codes

  type_section = WebAssembly::TypeSection.new
  function_section = WebAssembly::FunctionSection.new
  $types.each_with_index do |t, i|
    type_section.add_functype WebAssembly::FuncType.new(t.keys[0], t.values[0])
    function_section.add_type_index i
  end

  export_section = WebAssembly::ExportSection.new
  $exports.each do |e|
    export = WebAssembly::Export.new
    export.name = e[0]
    funcidx = $funcs.index e[1]
    export.desc = WebAssembly::FuncIndex.new funcidx
    export_section.add_export export
  end

  code_section = WebAssembly::CodeSection.new
  $codes.each do |c|
    code = WebAssembly::Code.new
    c.each do |i|
      case i[0]
      when "local.get"
        code.add_expression WebAssembly::LocalGetInstruction.new(i[1])
      when "i32.const"
        code.add_expression WebAssembly::I32ConstInstruction.new(i[1])
      when "i32.add"
        code.add_expression WebAssembly::I32AddInstruction.new
      when "call"
        funcidx = $funcs.index i[1]
        code.add_expression WebAssembly::CallInstruction.new(funcidx)
      end
    end
    code_section.add_code code
  end

  WebAssembly::Module.new [type_section, function_section, export_section, code_section]
end

def export exported_name, funcname
  $exports.push [exported_name, funcname]
end

def func name, sig, &block
  $funcs.push name
  $types.push sig # todo: identity check
  typeid = $types.size - 1
  $codes.push []
  block.call
end

def arg index
  last_type = $types[$types.size-1]
  arg_sig = last_type.keys[0]
  last_code = $codes[$codes.size-1]
  last_code.push ["local.get", index]
end

def call name
  last_code = $codes[$codes.size-1]
  last_code.push ["call", name]
end

class I32
  def add *args
    last_code = $codes[$codes.size-1]
    last_code.push ["i32.add"]
  end

  def const num
    last_code = $codes[$codes.size-1]
    last_code.push ["i32.const", num]
  end
end

i32 = I32.new

####

wasm =
  mod {
    func :f1, [:i32, :i32] => [:i32] {
      i32.add arg(0), arg(1)
      i32.add call(:f2)
    }
    
    func :f2, [] => [:i32] {
      i32.const 42
    }

    export "add42", :f1
  }

require "pp"
pp wasm.to_hash
inst = wasm.instantiate
puts inst.exports.add42(1, 2) # 1+2+42 = 45