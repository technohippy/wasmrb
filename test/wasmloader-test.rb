require "test-unit"
require_relative "../lib/wasm/wasmloader.rb"

class WASMLoaderTest < Test::Unit::TestCase
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
end