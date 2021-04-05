require_relative "./module.rb"

module WebAssembly
	class WASMBuffer
		def initialize
			@cursor = 0
			@data = []
		end

		def add byte
			@data.push byte
		end
	end

	class WASMLoader
		def initialize filepath
			@buffer = WASMBuffer.new
			File.open(filepath) do |f|
				begin
					loop do
						@buffer.add f.readbyte
					end
				rescue => _
				end
			end
		end

		def load
			mod = Module.new
		end
	end
end