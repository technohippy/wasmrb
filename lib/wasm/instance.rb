module WebAssembly
	class Instance
		def initialize mod, import_object=nil
			@mod = mod
			@import_object = import_object
		end

		def compile
			p @mod.section_by_name "export"
		end
	end
end