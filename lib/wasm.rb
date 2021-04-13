require_relative "wasm/core/module.rb"
require_relative "wasm/loader/wasmloader.rb"
require_relative "wasm/serializer/wasmserializer.rb"

module WebAssembly
  GlobalValue = Context::Global

  def self.load filename
    loader = WASMLoader.new
    loader.load filename
  end

  def self.instantiate filename, import_obj=nil
    mod = self.load filename
    mod.instantiate import_obj
  end

  def self.serialize mod, filename=nil
    serializer = WASMSerializer.new
    bytes = serializer.serialize mod
    unless filename.nil?
      File.binwrite filename, bytes.pack("C*")
    end
    bytes
  end
end