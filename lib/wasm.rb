require "pp"
require_relative "./wasm/module.rb"
require_relative "./wasm/wasmloader.rb"

mod = WebAssembly::Module.new
loader = WebAssembly::WASMLoader.new
loader.load mod, "spec/data/hw.wasm"
pp mod.to_hash

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