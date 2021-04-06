require_relative "./module.rb"

module WebAssembly
	class WASMBuffer
		attr_reader :cursor, :data

		def initialize
			@cursor = 0
			@sizes = [0]
			@data = []
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
			tabletype.reftype = REF_TYPES[read_num data]
			tabletype.limits = @buffer.read_limits data
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
			raise :TODO
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
			instname = Instruction.name_by_tag tag
			method_name = "read_inst_#{instname}"
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

		def read_s33 data
			raise "not yet implemented"
		end

		def read_inst_loop
			inst = LoopInstruction.new
			inst.blocktype = read_blocktype
			inst.instructions = read_expressions
			inst
		end

		def read_inst_if data
			bt = read_blocktype data
			end_tag, then_exprs = read_instructions data do |t|
				t == BLOCK_END || t == THEN_END
			end
			if end_tag == BLOCK_END
				{
					:if => {
						:bt => bt,
						:then => then_exprs
					}
				}
			else
				else_exprs = read_expressions data
				{
					:if => {
						:bt => bt,
						:then => then_exprs,
						:else => else_exprs
					}
				}
			end
		end

		def read_inst_br
			inst = BrInstruction.new
			inst.labelidx = @buffer.read_num
			inst
		end

		def read_inst_br_if
			inst = BrIfInstruction.new
			inst.labelidx = @buffer.read_num
			inst
		end

		def read_inst_call
			inst = CallInstruction.new
			inst.funcidx = @buffer.read_num
			inst
		end

		def read_inst_local_get data
			val = read_num data
			{
				:"local.get" => val
			}
		end

		def read_inst_local_set data
			val = read_num data
			{
				:"local.set" => val
			}
		end

		def read_inst_global_get
			inst = GlobalGetInstruction.new
			inst.index = @buffer.read_num
			inst
		end

		def read_inst_global_set
			inst = GlobalSetInstruction.new
			inst.index = @buffer.read_num
			inst
		end

		def read_inst_i32_load
			inst = I32LoadInstruction.new
			inst.memarg = read_memarg
			inst
		end

		def read_memarg
			memarg = Memarg.new
			memarg.align = @buffer.read_num
			memarg.offset = @buffer.read_num
			memarg
		end

		def read_inst_i32_store
			inst = I32StoreInstruction.new
			inst.memarg = read_memarg
			inst
		end

		def read_inst_i32_const
			inst = I32ConstInstruction.new
			inst.value = @buffer.read_num 
			inst
		end

		def read_inst_i32_eqz
			I32EqzInstruction.new
		end

		def read_inst_i32_eq data
			I32EqInstruction.new
		end

		def read_inst_i32_ne data
			I32NeInstruction.new
		end

		def read_inst_i32_add
			I32AddInstruction.new
		end

		def read_inst_i32_sub
			I32SubInstruction.new
		end

		def read_inst_i32_mul data
			I32MulInstruction.new
		end






		def read_data_section data 
			:data
		end

		def read_datacount_section data 
			:datacount
		end
	end
end