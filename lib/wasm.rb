require "pp"
require_relative "./wasm/wasmloader.rb"

filepath = %w(
  spec/data/hw.wasm
  spec/data/echo.wasm
  spec/data/fizzbuzz.wasm
  spec/data/change.wasm
  spec/data/understanding-text-format/wasm-table.wasm
  spec/data/understanding-text-format/logger2.wasm
)[3]
loader = WebAssembly::WASMLoader.new
mod = loader.load filepath
pp mod.to_hash

#p WebAssembly::IfInstruction.instance_methods.find_all {|m| m.to_s =~ /[a-z_]+=$/}

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