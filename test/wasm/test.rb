require "test-unit"
require_relative "../../lib/wasm/wasmloader.rb"
require_relative "../../lib/wasm/wasmserializer.rb"

class WasmTest < Test::Unit::TestCase
  def setup
    @loader = WebAssembly::WASMLoader.new
  end

  # def teardown
  # end

  def test_fail
    mod = @loader.load "test/data/js-api-examples/fail.wasm"
    inst = mod.instantiate
    begin
      inst.exports.fail_me()
    rescue => e
      assert true, "successfully an error occured."
    end
  end
  
  def test_global
    global = WebAssembly::Context::Global.new 0
    mod = @loader.load "test/data/js-api-examples/global.wasm"
    inst = mod.instantiate :js => {
      :global => global
    }
    assert_equal 0, inst.exports.getGlobal()
    global.value = 42
    assert_equal 42, inst.exports.getGlobal()
    inst.exports.incGlobal()
    assert_equal 43, inst.exports.getGlobal()
  end

  def test_memory
    mod = @loader.load "test/data/js-api-examples/memory.wasm"
    inst = mod.instantiate :js => {
      :mem => (0..9).to_a.pack("i*").unpack("C*")
    }
    assert_equal 45, inst.exports.accumulate(0, 10)
  end

  def test_table
    mod = @loader.load "test/data/js-api-examples/table.wasm"
    inst = mod.instantiate
    assert_equal 13, inst.exports.tbl[0].call
    assert_equal 42, inst.exports.tbl[1].call 
  end

  def test_table_from_js
    tbl = []
    mod = @loader.load "test/data/js-api-examples/table2.wasm"
    inst = mod.instantiate :js => {
      :tbl => tbl
    }
    assert_equal 42, tbl[0].call 
    assert_equal 83, tbl[1].call 
  end

  def test_add
    mod = @loader.load "test/data/understanding-text-format/add.wasm"
    inst = mod.instantiate
    assert_equal 3, inst.exports.add(1, 2)
  end

  def test_call
    mod = @loader.load "test/data/understanding-text-format/call.wasm"
    inst = mod.instantiate
    assert_equal 43, inst.exports.getAnswerPlus1()
  end

  def test_logger
    out = nil
    mod = @loader.load "test/data/understanding-text-format/logger.wasm"
    inst = mod.instantiate(
      :console => {
        :log => lambda {|msg| out = msg}
      }
    )
    inst.exports.logIt()
    assert_equal 13, out
  end

  def test_mem_logger
    out = nil
    mod = @loader.load "test/data/understanding-text-format/logger2.wasm"
    mem = []
    inst = mod.instantiate(
      :console => {
        :log => lambda {|offset, length|
          bytes = mem[offset...(offset+length)]
          out = bytes.pack("U*")
        }
      },
      :js => {
        :mem => mem
      }
    )
    inst.exports.writeHi()
    assert_equal "Hi", out
  end

  def test_shared
    import_object = {
      :js => {
        :memory => [],
        :table => []
      }
    }
    mod0 = @loader.load "test/data/understanding-text-format/shared0.wasm"
    inst0 = mod0.instantiate import_object
    mod1 = @loader.load "test/data/understanding-text-format/shared1.wasm"
    inst1 = mod1.instantiate import_object
    assert_equal 42, inst1.exports.doIt()
  end

  def test_table_form_wasm
    mod = @loader.load "test/data/understanding-text-format/wasm-table.wasm"
    inst = mod.instantiate
    assert_equal 42, inst.exports.callByIndex(0)
    assert_equal 13, inst.exports.callByIndex(1)
    begin
      inst.exports.callByIndex(2) # error
    rescue => e
      assert true, "successfully an error occured."
    end
  end

  # {:magic=>[0, 97, 115, 109],
  # :version=>[1, 0, 0, 0],
  # :sections=>
  # 	[{:section=>"type",
  # 		:id=>1,
  # 		:types=>[{:params=>[:i32, :i32], :results=>[:i32]}]},
  # 	{:section=>"function", :id=>3, :size=>2, :types=>[0]},
  # 	{:section=>"export",
  # 		:id=>7,
  # 		:exports=>[{:name=>"add", :desc=>{:func=>0}}]},
  # 	{:section=>"code",
  # 		:id=>10,
  # 		:codes=>
  # 		[{:locals=>[],
  # 			:expressions=>
  # 				[{:name=>"local.get", :index=>0},
  # 				{:name=>"local.get", :index=>1},
  # 				{:name=>"i32.add"}]}]}]}
  def test_generate
    type_section = WebAssembly::TypeSection.new
    type_section.add_functype WebAssembly::FuncType.new([:i32, :i32], [:i32])

    function_section = WebAssembly::FunctionSection.new
    function_section.add_type_index 0

    export = WebAssembly::Export.new
    export.name = "add"
    export.desc = WebAssembly::FuncIndex.new 0
    export_section = WebAssembly::ExportSection.new
    export_section.add_export export

    code = WebAssembly::Code.new
    code.add_expression WebAssembly::LocalGetInstruction.new(0)
    code.add_expression WebAssembly::LocalGetInstruction.new(1)
    code.add_expression WebAssembly::I32AddInstruction.new
    code_section = WebAssembly::CodeSection.new
    code_section.add_code code

    mod = WebAssembly::Module.new [type_section, function_section, export_section, code_section]

    inst = mod.instantiate
    assert_equal 3, inst.exports.add(1, 2)
  end

  def test_serialize
    mod = @loader.load "test/data/understanding-text-format/add.wasm"
    serializer = WebAssembly::WASMSerializer.new
    bytes = serializer.serialize mod
    assert_equal @loader.buffer.data, bytes
  end
end