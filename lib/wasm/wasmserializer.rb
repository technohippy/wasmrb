module WebAssembly
	class WASMSerializer
		# TODO: このあたり、loaderと共有できるように後で変更
		OP_END = 0x0b
		NUM_TYPES = {
			:f64 => 0x7c,
			:f32 => 0x7d,
			:i64 => 0x7e,
			:i32 => 0x7f,
		}
		REF_TYPES = {
			:funcref => 0x70,
			:externref => 0x6f,
		}

		def serialize mod
			bytes = []	
			serialize_module bytes, mod
			bytes
		end

		private
		
		def serialize_module bytes, mod
			bytes.push *mod.magic
			bytes.push *mod.version
			mod.sections.each do |section|
				section_bytes = []
				method_name = "serialize_#{Section.name_by_id section.class::ID}_section"
				send method_name, section_bytes, section

				bytes.push section.id
				bytes.push section_bytes.size
				bytes.push *section_bytes
			end
		end
		
		def serialize_custom_section bytes, section
			raise StandardError.new("not implemented yet")
		end
		
		def serialize_type_section bytes, section
			#serialize_vec bytes, section.functypes, &serialize_functype
			serialize_vec bytes, section.functypes do |bs, i|
				serialize_functype bs, i
			end
		end
		
		def serialize_import_section bytes, section
			#serialize_vec bytes, section.imports, &serialize_import
			serialize_vec bytes, section.imports do |bs, i|
				serialize_import bs, i
			end
		end
		
		def serialize_function_section bytes, section
			#serialize_vec bytes, section.type_indices, &serialize_num
			serialize_vec bytes, section.type_indices do |bs, i|
				serialize_num bs, i
			end
		end
		
		def serialize_table_section bytes, section
			raise StandardError.new("not implemented yet")
		end
		
		def serialize_memory_section bytes, section
			raise StandardError.new("not implemented yet")
		end
		
		def serialize_global_section bytes, section
			raise StandardError.new("not implemented yet")
		end
		
		def serialize_export_section bytes, section
			#serialize_vec bytes, section.exports, &serialize_export
			serialize_vec bytes, section.exports do |bs, i|
				serialize_export bs, i
			end
		end
		
		def serialize_start_section bytes, section
			raise StandardError.new("not implemented yet")
		end
		
		def serialize_element_section bytes, section
			raise StandardError.new("not implemented yet")
		end
		
		def serialize_code_section bytes, section
			#serialize_vec bytes, section.codes, &serialize_code
			serialize_vec bytes, section.codes do |bs, i|
				serialize_code bs, i
			end
		end
		
		def serialize_data_section bytes, section
			raise StandardError.new("not implemented yet")
		end
		
		def serialize_datacount_section bytes, section
			raise StandardError.new("not implemented yet")
		end

		#

		def serialize_functype bytes, functype
			bytes.push FuncType::TAG
			serialize_resulttype bytes, functype.params
			serialize_resulttype bytes, functype.results
		end

		def serialize_resulttype bytes, results
			result_tags = results.map{|r| NUM_TYPES[r]}
			#serialize_vec bytes, result_tags, &serialize_num
			serialize_vec bytes, result_tags do |bs, i|
				serialize_num bs, i
			end
		end

		def serialize_import bytes, import
			serialize_name bytes, import.mod
			serialize_name bytes, import.name
			case import.desc
			when ImportTypeDesc
				bytes.push 0x00
				serialize_num import.desc.index
			when ImportTableDesc
				bytes.push 0x01
				serialize_reftype bytes, import.desc.reftype
				serialize_limits bytes, import.desc.limits
			when ImportMemoryDesc
				bytes.push 0x02
				serialize_limits bytes, import.desc.limits
			when ImportGlobalDesc
				bytes.push 0x03
				serialize_valtype bytes, import.desc.valtype
				serialize_mut bytes, import.desc.mut
			else
				raise StandardError.new("invalid import desc: #{import.desc.class.name}")
			end
		end

		def serialize_reftype bytes, reftype
			case reftype
			when :functype
				bytes.push 0x70
			when :externref
				bytes.push 0x6f
			else
				raise StandardError.new("invalid reftype: #{import.desc.reftype}")
			end
		end

		def serialize_limits bytes, limit
			if limit.max
				bytes.push 0x01
				serialize_num bytes, limit.min
				serialize_num bytes, limit.max
			else
				bytes.push 0x00
				serialize_num bytes, limit.min
			end
		end

		def serialize_valtype bytes, valtype
			bytes.push({
				:i32 => 0x7f,
				:i64 => 0x7e,
				:f32 => 0x7d,
				:f64 => 0x7c,
				:funref => 0x70,
				:externref => 0x6f,
			}[valtype])
		end

		def serialize_mut bytes, mut
			bytes.push({
				:const => 0x00,
				:var => 0x01,
			}[mut])
		end

		def serialize_export bytes, export
			serialize_name bytes, export.name
			bytes.push \
				case export.desc
				when FuncIndex
					0x00
				when TableIndex
					0x01
				when MemoryIndex
					0x02
				when GlobalIndex
					0x03
				else
					raise StandardError.new("invalid export desc: #{export.desc.class.name}")
				end
			serialize_num bytes, export.desc.index
		end

		def serialize_code bytes, code
			code_body_bytes = []
			serialize_vec code_body_bytes, code.locals do |bs, i|
				serialize_locals bs, i
			end
			code.expressions.each do |instr|
				serialize_instruction code_body_bytes, instr
			end
			code_body_bytes.push OP_END
			
			serialize_num bytes, code_body_bytes.size
			bytes.push *code_body_bytes
		end

		def serialize_locals bytes, locals
			serialize_num bytes, locals.count
			serialize_valtype bytes, locals.valtype
		end

		def serialize_instruction bytes, instr
			bytes.push instr.class::TAG

			name = Instruction.name_by_tag instr.class::TAG
			method_name = "serialize_inst_#{name}"
			send method_name, bytes, instr
		end

		def serialize_inst_local_get bytes, instr
			serialize_num bytes, instr.index
		end

		def serialize_inst_local_set bytes, instr
			serialize_num bytes, instr.index
		end

		def serialize_inst_i32_load bytes, instr
			serialize_memarg bytes, instr.memarg
		end

		def serialize_memarg bytes, memarg
			serialize_num bytes, memarg.align
			serialize_num bytes, memarg.offset
		end

		def serialize_inst_i32_const bytes, instr
			serialize_num bytes, instr.value
		end

		def serialize_inst_i32_add bytes, instr
			# pass
		end

		def serialize_inst_i32_mul bytes, instr
			# pass
		end

		def serialize_inst_i32_eq bytes, instr
			# pass
		end

		def serialize_inst_block bytes, instr
			serialize_blocktype bytes, instr.blocktype
			instr.instructions.each do |i|
				serialize_instruction bytes, i
			end
			bytes.push OP_END
		end

		def serialize_blocktype bytes, blocktype
			if blocktype == 0x40
				bytes.push 0x40
			elsif NUM_TYPES.has_key? blocktype
				bytes.push NUM_TYPES[blocktype]
			elsif REF_TYPES.has_key? blocktype
				bytes.push REF_TYPES[blocktype]
			else
				serialize_signed_num bytes, blocktype
			end
		end

		# TODO: same as serialize_inst_block
		def serialize_inst_loop bytes, instr
			serialize_blocktype bytes, instr.blocktype
			instr.instructions.each do |i|
				serialize_instruction bytes, i
			end
			bytes.push OP_END
		end

		# TODO: same as br_if
		def serialize_inst_br bytes, instr
			serialize_num bytes, instr.labelidx
		end

		def serialize_inst_br_if bytes, instr
			serialize_num bytes, instr.labelidx
		end

		#

		# https://en.wikipedia.org/wiki/LEB128
		def serialize_leb128 bytes, num
			bs = []
			loop do
				low = num & 0b01111111
				num = num >> 7
				if num == 0
					bs.push low
					break
				else
					low |= 0b10000000
					bs.push low
				end
			end
			bytes.push *bs
		end

		alias serialize_num serialize_leb128

		# https://en.wikipedia.org/wiki/LEB128#Signed_LEB128
		def serialize_signed_num bytes, num
			raise StandardError.new("not yet implemented")
		end

		def serialize_name bytes, name
			chars = name.unpack("C*")
			serialize_vec bytes, chars do |bt, c|
				bt.push c
			end
		end

		def serialize_vec bytes, items, &serialize
			serialize_num bytes, items.size
			items.each do |item|
				serialize.call bytes, item
			end
		end
	end
end