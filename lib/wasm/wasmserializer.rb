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
				method_name = "serialize_#{Section.name_by_id section.id}_section"
				send method_name, section_bytes, section

				bytes.push section.id
				bytes.push section_bytes.size
				bytes.push *section_bytes
				p section.class.name
				p bytes.map {|b| b.to_s(16)}
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
			raise StandardError.new("not implemented yet")
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
			serialize_num locals.count
			serialize_num locals.valtype # TODO
		end

		def serialize_instruction bytes, instr
			case instr
			when LocalGetInstruction
				bytes.push LocalGetInstruction::TAG
				serialize_num bytes, instr.index
			when I32AddInstruction
				bytes.push I32AddInstruction::TAG
			end
		end

		#

		# leb128
		def serialize_num bytes, num
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