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

mod = loader.load "spec/data/understanding-text-format/add.wasm"
inst = mod.instantiate
puts inst.exports.add(1, 2)

mod = loader.load "spec/data/understanding-text-format/call.wasm"
inst = mod.instantiate
puts inst.exports.getAnswerPlus1()

mod = loader.load "spec/data/understanding-text-format/logger.wasm"
inst = mod.instantiate(
  :console => {
    :log => lambda {|msg| puts msg}
  }
)
inst.exports.logIt()

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
inst.exports.writeHi()

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
puts inst1.exports.doIt()

mod = loader.load "spec/data/understanding-text-format/wasm-table.wasm"
inst = mod.instantiate
puts inst.exports.callByIndex(0)
puts inst.exports.callByIndex(1)
begin
  puts inst.exports.callByIndex(2) # error
rescue => e
  puts e
end