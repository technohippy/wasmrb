require "pp"
require_relative "./wasm/wasmloader.rb"

loader = WebAssembly::WASMLoader.new

mod = loader.load "spec/data/js-api-examples/fail.wasm"
inst = mod.instantiate
begin
  inst.exports.fail_me()
rescue => e
  puts e
end

global = WebAssembly::Context::Global.new 0
mod = loader.load "spec/data/js-api-examples/global.wasm"
inst = mod.instantiate :js => {
  :global => global
}
puts inst.exports.getGlobal() # 0
global.value = 42
puts inst.exports.getGlobal() # 42
inst.exports.incGlobal()
puts inst.exports.getGlobal() # 43

mod = loader.load "spec/data/js-api-examples/memory.wasm"
inst = mod.instantiate :js => {
  :mem => (0..9).to_a.pack("i*").unpack("C*")
}
puts inst.exports.accumulate(0, 10) # 45

mod = loader.load "spec/data/js-api-examples/simple.wasm"
inst = mod.instantiate :imports => {
  :imported_func => lambda {|n| puts n}
}
inst.exports.exported_func() # 42

mod = loader.load "spec/data/js-api-examples/table.wasm"
inst = mod.instantiate
puts inst.exports.tbl[0].call # 13
puts inst.exports.tbl[1].call # 42

tbl = []
mod = loader.load "spec/data/js-api-examples/table2.wasm"
inst = mod.instantiate :js => {
  :tbl => tbl
}
puts tbl[0].call # 42
puts tbl[1].call # 83

mod = loader.load "spec/data/understanding-text-format/add.wasm"
inst = mod.instantiate
puts inst.exports.add(1, 2) # 3

mod = loader.load "spec/data/understanding-text-format/call.wasm"
inst = mod.instantiate
puts inst.exports.getAnswerPlus1() # 43

mod = loader.load "spec/data/understanding-text-format/logger.wasm"
inst = mod.instantiate(
  :console => {
    :log => lambda {|msg| puts msg}
  }
)
inst.exports.logIt() # 13

mod = loader.load "spec/data/understanding-text-format/logger2.wasm"
mem = []
inst = mod.instantiate(
  :console => {
    :log => lambda {|offset, length|
      bytes = mem[offset...(offset+length)]
      puts bytes.pack("U*")
    }
  },
  :js => {
    :mem => mem
  }
)
inst.exports.writeHi() # Hi

import_object = {
  :js => {
    :memory => [],
    :table => []
  }
}
mod0 = loader.load "spec/data/understanding-text-format/shared0.wasm"
inst0 = mod0.instantiate import_object
mod1 = loader.load "spec/data/understanding-text-format/shared1.wasm"
inst1 = mod1.instantiate import_object
puts inst1.exports.doIt() # 42

mod = loader.load "spec/data/understanding-text-format/wasm-table.wasm"
inst = mod.instantiate
puts inst.exports.callByIndex(0) # 42
puts inst.exports.callByIndex(1) # 13
begin
  puts inst.exports.callByIndex(2) # error
rescue => e
  puts e
end