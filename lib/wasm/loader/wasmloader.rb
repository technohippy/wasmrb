require_relative "../core/module.rb"

module WebAssembly
	class WASMBuffer
		attr_reader :cursor, :data

		def self.load filepath
			buffer = self.new
			buffer.load filepath
			buffer
		end

		def initialize data=nil
			@cursor = 0
			if data
				@sizes = [data.size]
				@data = data
			else
				@sizes = [0]
				@data = []
			end
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

		# https://en.wikipedia.org/wiki/LEB128
		def read_leb128
			num = 0
			fig = 0
			loop do
				part = read_byte
				last = part < 128
				part = (part & 0b01111111) << fig
				num = num | part
				break if last
				fig += 7
			end
			num
		end

		alias read_uint read_leb128

		def read_signed_leb128
			num = 0
			rnum = 0 # 負数を求めるために反転した数値も合わせて作成
			fig = 0
			loop do
				part = read_byte
				rpart = part ^ 0b11111111
				last = part < 128
				part = (part & 0b01111111) << fig
				num = num | part
				rpart = (rpart & 0b01111111) << fig
				rnum = rnum | rpart

				break if last
				fig += 7
			end
			byte_count = fig/7+1
			minus = (num & (1 << (byte_count * 7)-1)) != 0
			if minus
				num = -(rnum + 1)
			end
			num
		end

		alias read_sint read_signed_leb128

		def read_f32
			bytes = read 4
      bytes.pack("C*").unpack("d")[0]
		end

		def read_f64
			bytes = read 8
      bytes.pack("C*").unpack("d")[0]
		end

		def read_name
			bytes = read_vec do
				read_byte
			end
			bytes.pack("U*")
		end

		def read_vec &readfunc
			vec = []
			read_uint.times do
				vec.push readfunc.call
			end
			vec
		end

		def read_limits
			limit = Limit.new
			type = read_byte
			if type == 0
				limit.min = read_uint
			elsif type == 1
				limit.min = read_uint
				limit.max = read_uint
			else
				raise StandardError.new("invalid limit type: #{type}")
			end
			limit
		end
	end

	class WASMLoader
		OP_BLOCK_END = 0x0b
		OP_THEN_END = 0x05
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

		attr_reader :buffer

		def load filepath_or_buffer
			@buffer =
				case filepath_or_buffer
				when String
					WASMBuffer.load filepath_or_buffer
				else
					filepath_or_buffer
				end

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
			length = @buffer.read_uint
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
			type_num = @buffer.read_uint
			type_num.times do
				section.add_functype read_functype
			end
			section
		end

		def read_functype
			functype = FuncType.new
			tag = @buffer.read_byte
			raise StandardError.new("invalid functype: #{tag}") unless tag == FuncType::TAG
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
			num = @buffer.read_byte
			NUM_TYPES[num] || REF_TYPES[num]  # TODO
		end

		def peek_valtype
			num = @buffer.peek
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
			index.index = @buffer.read_uint
			desc.index = index
			desc
		end

		def read_table_import
			desc = ImportTableDesc.new
			desc.reftype = REF_TYPES[@buffer.read_uint]
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
			type = @buffer.read_uint
			globaltype.mut =
				case type
				when 0
					:const
				when 1
					:var
				else
					raise StandardError.new("invalid mut: #{type}")
				end
			globaltype
		end

		def read_function_section
			section = FunctionSection.new
			@buffer.read_vec do
				section.add_type_index @buffer.read_uint
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
			tabletype.reftype = REF_TYPES[@buffer.read_uint]
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
			global
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
			type = @buffer.read_uint
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
					raise StandardError.new("invalid export desc: #{type}")
				end
			export.desc.index = @buffer.read_uint
			export
		end

		def read_start_section
			section = StartSection.new
			@buffer.read_vec do
				funcidx = FuncIndex.new
				funcidx.index = @buffer.read_uint
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
			element.tag = tag

			case tag
			when 0b000
				element.expression = read_expressions
				@buffer.read_vec do
					element.add_funcidx @buffer.read_uint
				end
			when 0b001
				raise StandardError.new("not yet implemented: #{tag}")
			when 0b010
				raise StandardError.new("not yet implemented: #{tag}")
			when 0b011
				raise StandardError.new("not yet implemented: #{tag}")
			when 0b100
				raise StandardError.new("not yet implemented: #{tag}")
			when 0b101
				raise StandardError.new("not yet implemented: #{tag}")
			when 0b110
				raise StandardError.new("not yet implemented: #{tag}")
			when 0b111
				raise StandardError.new("not yet implemented: #{tag}")
			else
				raise StandardError.new("invalid element: #{tag}")
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
			size = @buffer.read_uint
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
			locals.count = @buffer.read_uint
			locals.valtype = read_valtype
			locals
		end

		def read_expressions
			_, instructions = read_instructions do |t|
				t == OP_BLOCK_END
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
			valtype = peek_valtype
			return read_valtype if valtype
			@buffer.read_sint
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
				t == OP_BLOCK_END || t == OP_THEN_END
			end
			inst.then_instructions = then_exprs
			if end_tag == OP_THEN_END
				_, else_exprs = read_instructions do |t|
					t == OP_BLOCK_END
				end
				inst.else_instructions = else_exprs
			end
			inst
		end

		def read_inst_return
			ReturnInstruction.new
		end

		def read_inst_br_table
			inst = BrTableInstruction.new
			@buffer.read_vec do
				inst.add_labelidx @buffer.read_uint
			end
			inst.labelidx = @buffer.read_uint
			inst
		end

		{
			"unreachable" => [],
			"nop" => [],
			"br" => ["labelidx"],
			"br_if" => ["labelidx"],
			"call" => ["funcidx"],
			"call_indirect" => ["typeidx", "tableidx"],
			"ref_null" => ["reftype"],
			"ref_is_null" => [],
			"ref_func" => ["funcidx"],
			"drop" => [],
			"select" => [],
			#"select_types" => [],
			"local_get" => ["index"],
			"local_set" => ["index"],
			"local_tee" => ["index"],
			"global_get" => ["index"],
			"global_set" => ["index"],
			"table_get" => ["tableidx"],
			"table_set" => ["tableidx"],
			"table_init" => ["elemidx", "tableidx"],
			"elem_drop" => ["elemidx"],
			"table_copy" => ["tableidx1", "tableidx2"],
			"table_grow" => ["tableidx"],
			"table_size" => ["tableidx"],
			"table_fill" => ["tableidx"],
			"i32_load" => {"memarg" => "read_memarg"},
			"f64_load" => {"memarg" => "read_memarg"},
			"i32_load8s" => {"memarg" => "read_memarg"},
			"i32_load8u" => {"memarg" => "read_memarg"},
			"i32_load16s" => {"memarg" => "read_memarg"},
			"i32_load16u" => {"memarg" => "read_memarg"},
			"i32_store" => {"memarg" => "read_memarg"},
			"i32_store8" => {"memarg" => "read_memarg"},
			"i32_store16" => {"memarg" => "read_memarg"},
			"memory_size" => [],
			"memory_grow" => [],
			"memory_init" => ["dataidx"],
			"data_drop" => ["dataidx"],
			"memory_copy" => [],
			"memory_fill" => [],
			#"i32_const" => ["value"],
			"i32_const" => {"value" => proc {|buf| buf.read_sint}},
			"i64_const" => {"value" => proc {|buf| buf.read_sint}},
			"f32_const" => {"value" => proc {|buf| buf.read_f32}},
			"f64_const" => {"value" => proc {|buf| buf.read_f64}},
			"i32_eqz" => [],
			"i32_eq" => [],
			"i32_ne" => [],
			"i32_lts" => [],
			"i32_ltu" => [],
			"i32_gts" => [],
			"i32_gtu" => [],
			"i32_les" => [],
			"i32_leu" => [],
			"i32_ges" => [],
			"i32_geu" => [],
			"i32_clz" => [],
			"i32_ctz" => [],
			"i32_popcnt" => [],
			"i32_add" => [],
			"i32_sub" => [],
			"i32_mul" => [],
			"i32_divs" => [],
			"i32_divu" => [],
			"i32_rems" => [],
			"i32_remu" => [],
			"i32_and" => [],
			"i32_or" => [],
			"i32_xor" => [],
			"i32_shl" => [],
			"i32_shrs" => [],
			"i32_shru" => [],
			"i32_rotl" => [],
			"i32_rotr" => [],
			"i32_wrap_i64" => [],
			"i32_trunc_f32s" => [],
			"i32_trunc_f32u" => [],
			"i32_trunc_f64s" => [],
			"i32_trunc_f64u" => [],

			"i64_load" => {"memarg" => "read_memarg"},
			"i64_store" => {"memarg" => "read_memarg"},
			"f64_add" => [],
			"f64_sqrt" => [],
			"f64_convert_i32s" => [],
		}.each do |name, props|
			define_method "read_inst_#{name}" do
				classname = name.capitalize.gsub(/_([a-z])/) { $1.upcase }
				classname += "Instruction"
				inst = WebAssembly.const_get(classname).new
				if props.instance_of? Array
					props.each do |prop|
						inst.send "#{prop}=", @buffer.read_uint
					end
				else
					props.each do |prop, reader|
						if reader.is_a? String
							inst.send "#{prop}=", send(reader)
						else
							inst.send "#{prop}=", reader.call(@buffer)
						end
					end
				end
				inst
			end
		end

		def read_memarg
			memarg = Memarg.new
			memarg.align = @buffer.read_uint
			memarg.offset = @buffer.read_uint
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
				data.memidx = read_uint
				data.expressions = read_expressions
				@buffer.read_vec do
					data.add_byte @buffer.read_byte
				end
			else
				raise StandardError.new("invalid data type: #{tag}")
			end
			data
		end

		def read_datacount_section data 
			section = DataCountSection.new
			section.count = @buffer.read_uint
			section
		end
	end
end