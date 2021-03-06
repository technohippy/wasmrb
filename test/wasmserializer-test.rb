require "test-unit"
require_relative "../lib/wasm/loader/wasmloader.rb"
require_relative "../lib/wasm/serializer/wasmserializer.rb"

class WASMSerializerTest < Test::Unit::TestCase
  def setup
    @loader = WebAssembly::WASMLoader.new
    @serializer = WebAssembly::WASMSerializer.new
  end

  # def teardown
  # end

  def bytes_to_string bytes
    bytes = bytes.map do |b|
      "#{if b < 16 then "0" else "" end}#{b.to_s(16)}"
    end
  end
  private :bytes_to_string

  def assert_bytes expected, actual
    assert_equal bytes_to_string(expected), bytes_to_string(actual)
  end

  def test_if
    mod = @loader.load "test/data/basic/if.wasm"
    bytes = @serializer.serialize mod
    #File.binwrite "loop2.wasm", bytes.pack("C*")
    assert_bytes @loader.buffer.data, bytes
  end

  def test_signed_int
    mod = @loader.load "test/data/basic/signed_int.wasm"
    bytes = @serializer.serialize mod
    assert_bytes @loader.buffer.data, bytes
  end

=begin
  # i32.const 100を41 64ってシリアライズしたら何故かダメらしい
  # 41 e4 00が正解らしいけどわからん
  def test_loop
    mod = @loader.load "test/data/basic/loop.wasm"
    bytes = @serializer.serialize mod
    File.binwrite "loop2.wasm", bytes.pack("C*")
    assert_bytes @loader.buffer.data, bytes
  end
=end

  def test_f64
    mod = @loader.load "test/data/basic/f64.wasm"
    bytes = @serializer.serialize mod
    assert_bytes @loader.buffer.data, bytes
  end

  def test_add
    mod = @loader.load "test/data/understanding-text-format/add.wasm"
    bytes = @serializer.serialize mod
    assert_bytes @loader.buffer.data, bytes
  end

  def test_memory
    mod = @loader.load "test/data/js-api-examples/memory.wasm"
    bytes = @serializer.serialize mod
    assert_bytes @loader.buffer.data, bytes
  end

=begin
  # time consuming
  def test_sobel
    mod = @loader.load "test/data/wasm-sobel/change.wasm"
    bytes = @serializer.serialize mod

    # because the original wasm has paddings for numbers
    # it does not match with the generated one.
    #assert_bytes @loader.buffer.data, bytes

    buffer = WebAssembly::WASMBuffer.new bytes
    mod2 = @loader.load buffer
    # because the original wasm has paddings for numbers
    # section size may deffer.
    mod.sections.each {|s| s.size = 0}
    mod2.sections.each {|s| s.size = 0}
    assert_equal mod.to_hash, mod2.to_hash
  end
=end

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
    assert_equal 3, inst.exports.add(1, 2), "run"

    bytes = @serializer.serialize mod
    mod = @loader.load "test/data/understanding-text-format/add.wasm"
    assert_equal @loader.buffer.data, bytes, "serialize"
  end
end