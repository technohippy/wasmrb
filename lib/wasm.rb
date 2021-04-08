require "pp"
require_relative "./wasm/wasmloader.rb"

loader = WebAssembly::WASMLoader.new

=begin
[
  "spec/data/hw.wasm",
  "spec/data/echo.wasm",
  "spec/data/fizzbuzz.wasm",
  #"spec/data/change.wasm",
  "spec/data/understanding-text-format/wasm-table.wasm",
  "spec/data/understanding-text-format/logger2.wasm",
  "spec/data/understanding-text-format/shared1.wasm",
  "spec/data/understanding-text-format/add.wasm",
].each do |filepath|
  mod = loader.load filepath
  pp mod.to_hash
end
=end

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
puts inst.exports.getGlobal() # -> 0
global.value = 42
puts inst.exports.getGlobal() # -> 42
inst.exports.incGlobal()
puts inst.exports.getGlobal() # -> 43

mod = loader.load "spec/data/js-api-examples/memory.wasm"
inst = mod.instantiate :js => {
  :mem => [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]
}
puts :wrong
puts inst.exports.accumulate(0, 10)

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