require_relative "./module.rb"

module WebAssembly
	class WASMBuffer
		attr_reader :cursor, :data

		def self.load filepath
			buffer = self.new
			buffer.load filepath
			buffer
		end

		def initialize
			@cursor = 0
			@sizes = [0]
			@data = []
		end

		def load filepath
			File.open(filepath) do |f|
				begin
					loop do
						self.add f.readbyte
					end
				rescue => _
				end
			end
		end

		def add byte
			@data.push byte
			@sizes[@sizes.size-1] += 1
		end

		def peek
			@data[@cursor]
		end

		def viewport length, &block
			@sizes.push(@cursor + length) 
			ret = block.call
			@cursor = @sizes.pop
			ret
		end

		def size
			@sizes[@sizes.size-1]
		end

		def empty?
			size <= @cursor
		end

		def read length=1
			puts "#{@cursor}: #{@data[@cursor].to_s(16)}" if $DEBUG

			@cursor += length
			if length == 1
				@data[@cursor-length]
			else
				@data[(@cursor-length)...@cursor]
			end
		end

		def read_byte
			read
		end

		def read_leb128
			num = 0
			fig = 0
			loop do
				part = read
				last = part < 128
				part = (part & 0b01111111) << fig
				num = num | part
				fig += 7
				break if last
			end
			num
		end

		alias read_num read_leb128

		def read_name
			bytes = read_vec do
				read_byte
			end
			bytes.pack("U*")
		end

		def read_vec &readfunc
			vec = []
			read_num.times do
				vec.push readfunc.call
			end
			vec
		end

		def read_limits
			limit = Limit.new
			type = read_byte
			if type == 0
				limit.min = read_num
			elsif type == 1
				limit.min = read_num
				limit.max = read_num
			else
				raise "invalid limit type: #{type}"
			end
			limit
		end
	end

	class WASMLoader
		BLOCK_END = 0x0b
		THEN_END = 0x05
		NUM_TYPES = {
			0x7c => :f64,
			0x7d => :f32,
			0x7e => :i64,
			0x7f => :i32,
		}
		REF_TYPES = {
			0x70 => :funcref,
			0x6f => :externref,
		}
		IMPORT_TYPES = {
			0x00 => :type,
			0x01 => :table,
			0x02 => :mem,
			0x03 => :global
		}
		EXPORT_TYPES = {
			0x00 => :func,
			0x01 => :table,
			0x02 => :mem,
			0x03 => :global
		}

		def load filepath
			@buffer = WASMBuffer.load filepath

			mod = Module.new
			mod.magic = read_magic
			mod.version = read_version
			mod.sections = read_sections
			mod
		end

		private

		def read_magic
			magic_data = @buffer.read 4
			magic_data
		end

		def read_version
			version_data = @buffer.read 4
			version_data
		end

		def read_sections
			sections = []
			loop do
				break if @buffer.empty?
				sections.push read_section
			end
			sections
		end

		def read_section
			id, size = read_section_header
			name = Section.name_by_id(id)
			@buffer.viewport size do
				method_name = "read_#{name}_section"
				p "SECTION: #{method_name}" if $DEBUG
				section = send method_name
				section.id = id
				section.size = size
				section
			end
		end

		def read_section_header
			secid = @buffer.read_byte
			length = @buffer.read_num
			[secid, length]
		end

		def read_custom_section
			section = CustomSection.new
			section.name = @buffer.read_name
			section.bytes = nil#read_all
			section
		end

		def read_type_section
			section = TypeSection.new
			types = []
			type_num = @buffer.read_num
			type_num.times do
				section.add_functype read_functype
			end
			section
		end

		def read_functype
			functype = FuncType.new
			tag = @buffer.read_byte
			raise "invalid functype: #{tag}" unless tag == FuncType::TAG
			functype.params = read_resulttype
			functype.results = read_resulttype
			functype
		end

		def read_resulttype
			resulttype = @buffer.read_vec do
				read_valtype
			end
			resulttype
		end

		def read_valtype
			num = @buffer.read_num
			NUM_TYPES[num] || REF_TYPES[num]  # TODO
		end

		def read_import_section 
			section = ImportSection.new
			@buffer.read_vec do
				section.add_import read_import
			end
			section
		end

		def read_import
			import = Import.new
			import.mod = @buffer.read_name
			import.name = @buffer.read_name
			import.desc = read_import_desc
			import
		end

		def read_import_desc
			importtype = @buffer.read_byte
			send "read_#{IMPORT_TYPES[importtype]}_import"
		end

		def read_type_import
			desc = ImportTypeDesc.new
			index = TypeIndex.new
			index.index = @buffer.read_num
			desc.index = index
			desc
		end

		def read_table_import
			desc = ImportTableDesc.new
			desc.reftype = @buffer.read_num
			desc.limits = @buffer.read_limits
			desc
		end

		def read_mem_import
			desc = ImportMemoryDesc.new
			desc.limits = @buffer.read_limits
			desc
		end

		def read_global_import
			desc = ImportGlobalDesc.new
			desc.globaltype = read_globaltype
			desc
		end

		def read_globaltype
			globaltype = GlobalType.new
			globaltype.valtype = read_valtype
			type = @buffer.read_num
			globaltype.mut =
				case type
				when 0
					:const
				when 1
					:mut
				else
					raise "invalid mut: #{type}"
				end
			globaltype
		end

		def read_function_section
			section = FunctionSection.new
			@buffer.read_vec do
				section.add_type_index @buffer.read_num
			end
			section
		end

		def read_table_section
			section = TableSection.new
			@buffer.read_vec do
				section.add_tabletype read_tabletype
			end
			section
		end

		def read_tabletype
			tabletype = TableType.new
			tabletype.reftype = REF_TYPES[@buffer.read_num]
			tabletype.limits = @buffer.read_limits
			tabletype
		end

		def read_memory_section
			section = MemorySection.new
			@buffer.read_vec do
				section.add_memtype @buffer.read_limits
			end
			section
		end

		def read_global_section
			section = GlobalSection.new
			@buffer.read_vec do
				section.add_global read_global
			end
			section
		end

		def read_global
			global = Global.new
			global.globaltype = read_globaltype
			global.expr = read_expressions
		end

		def read_export_section
			section = ExportSection.new
			@buffer.read_vec do
				section.add_export read_export
			end
			section
		end

		def read_export
			export = Export.new
			export.name = @buffer.read_name
			type = @buffer.read_num
			export.desc = 
				case type
				when 0x00
					FuncIndex.new
				when 0x01
					TableIndex.new
				when 0x02
					MemoryIndex.new
				when 0x03
					GlobalIndex.new
				else
					raise "invalid export desc: #{type}"
				end
			export.desc.index = @buffer.read_num
			export
		end

		def read_start_section
			section = StartSection.new
			@buffer.read_vec do
				funcidx = FuncIndex.new
				funcidx.index = @buffer.read_num
				section.add_start funcidx
			end
			section
		end

		def read_element_section
			section = ElementSection.new
			@buffer.read_vec do
				section.add_element read_element
			end
			section
		end

		def read_element
			element = Element.new
			tag = @buffer.read_byte
			case tag
			when 0b000
				element.expression = read_expressions
				@buffer.read_vec do
					element.add_funcidx @buffer.read_num
				end
			when 0b001
				raise "not yet implemented: #{tag}"
			when 0b010
				raise "not yet implemented: #{tag}"
			when 0b011
				raise "not yet implemented: #{tag}"
			when 0b100
				raise "not yet implemented: #{tag}"
			when 0b101
				raise "not yet implemented: #{tag}"
			when 0b110
				raise "not yet implemented: #{tag}"
			when 0b111
				raise "not yet implemented: #{tag}"
			else
				raise "invalid element: #{tag}"
			end
			element
		end

		def read_code_section
			section = CodeSection.new
			@buffer.read_vec do
				section.add_code read_code
			end
			section
		end

		def read_code
			code = Code.new
			size = @buffer.read_num
			@buffer.viewport size do
				@buffer.read_vec do
					code.add_locals read_locals
				end
				code.expressions = read_expressions
			end
			code
		end

		def read_locals
			locals = Locals.new
			locals.count = @buffer.read_num
			locals.valtype = read_valtype
			locals
		end

		def read_expressions
			_, instructions = read_instructions do |t|
				t == BLOCK_END
			end
			instructions
		end

		def read_instructions &end_cond
			instructions = []
			loop do
				break if end_cond.call(@buffer.peek)
				instructions.push read_instruction
			end
			end_tag = @buffer.read_byte # remove end_tag
			[end_tag, instructions]
		end

		def read_instruction
			tag = @buffer.read_byte
			name = Instruction.name_by_tag tag
			method_name = "read_inst_#{name}"
			puts "INSTRUCTION: #{method_name}" if $DEBUG
			send method_name
		end

		def read_inst_block
			inst = BlockInstruction.new
			inst.blocktype = read_blocktype
			inst.instructions = read_expressions
			inst
		end

		def read_blocktype
			return @buffer.read_byte if @buffer.peek == 0x40
			valtype = read_valtype
			return valtype if valtype
			read_s33
		end

		def read_s33
			raise "not yet implemented"
		end

		def read_inst_loop
			inst = LoopInstruction.new
			inst.blocktype = read_blocktype
			inst.instructions = read_expressions
			inst
		end

		def read_inst_if
			inst = IfInstruction.new
			inst.blocktype = read_blocktype

			end_tag, then_exprs = read_instructions do |t|
				t == BLOCK_END || t == THEN_END
			end
			inst.then_instructions = then_exprs
			if end_tag == THEN_END
				_, else_exprs = read_instructions
				inst.else_instructions = else_exprs
			end
			inst
		end

		{
			"br" => ["labelidx"],
			"br_if" => ["labelidx"],
			"call" => ["funcidx"],
			"call_indirect" => ["typeidx", "tableidx"],
			"local_get" => ["index"],
			"local_set" => ["index"],
			"local_tee" => ["index"],
			"global_get" => ["index"],
			"global_set" => ["index"],
			"i32_load" => {"memarg" => "read_memarg"},
			"i32_store" => {"memarg" => "read_memarg"},
			"i32_const" => ["value"],
			"i32_eqz" => [],
			"i32_eq" => [],
			"i32_ne" => [],
			"i32_gts" => [],
			"i32_add" => [],
			"i32_sub" => [],
			"i32_mul" => [],
			"i32_and" => [],
		}.each do |name, props|
			define_method "read_inst_#{name}" do
				classname = name.capitalize.gsub(/_([a-z])/) { $1.upcase }
				classname += "Instruction"
				inst = WebAssembly.const_get(classname).new
				if props.instance_of? Array
					props.each do |prop|
						inst.send "#{prop}=", @buffer.read_num
					end
				else
					props.each do |prop, reader|
						inst.send "#{prop}=", send(reader)
					end
				end
				inst
			end
		end

		def read_memarg
			memarg = Memarg.new
			memarg.align = @buffer.read_num
			memarg.offset = @buffer.read_num
			memarg
		end

		def read_data_section
			section = DataSection.new
			@buffer.read_vec do
				section.add_data read_data
			end
			section
		end

		def read_data
			data = Data.new
			tag = @buffer.read_byte
			case tag
			when 0x00
				data.expressions = read_expressions
				@buffer.read_vec do
					data.add_byte @buffer.read_byte
				end
			when 0x01
				@buffer.read_vec do
					data.add_byte @buffer.read_byte
				end
			when 0x02
				data.memidx = read_num
				data.expressions = read_expressions
				@buffer.read_vec do
					data.add_byte @buffer.read_byte
				end
			else
				raise "invalid data type: #{tag}"
			end
			data
		end

		def read_datacount_section data 
			section = DataCountSection.new
			section.count = @buffer.read_num
			section
		end
	end
end