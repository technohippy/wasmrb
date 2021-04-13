require "pp"
require "test-unit"
require_relative "../lib/wasm.rb"

class WASMText < Test::Unit::TestCase
  def test_load
    mod = nil
    assert_nothing_raised do
      mod = WebAssembly::load "test/data/basic/loop.wasm"
    end
    assert_not_nil mod
  end

  def test_instantiate
    global = WebAssembly::GlobalValue.new 0
    inst = WebAssembly::instantiate "test/data/js-api-examples/global.wasm", :js => {
      :global => global
    }
    assert_equal 0, inst.exports.getGlobal()
    global.value = 42
    assert_equal 42, inst.exports.getGlobal()
    inst.exports.incGlobal()
    assert_equal 43, inst.exports.getGlobal()
  end

  def test_serialize
    loader = WebAssembly::WASMLoader.new
    mod = loader.load "test/data/basic/if.wasm"
    bytes = WebAssembly::serialize mod
    File.binwrite "p2.wasm", bytes.pack("C*")
    assert_equal loader.buffer.data, bytes
  end
end