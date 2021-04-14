module WebAssembly
	class WASMSerializer
		# TODO: このあたり、loaderと共有できるように後で変更
		OP_BLOCK_END = 0x0b
		OP_THEN_END = 0x05
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
				serialize_uint bytes, section_bytes.size
				bytes.push *section_bytes
			end
		end
		
		def serialize_custom_section bytes, section
			serialize_name bytes, section.name
			bytes.push *section.bytes
		end
		
		def serialize_type_section bytes, section
			#serialize_vec bytes, section.functypes, &serialize_functype
			serialize_vec bytes, section.functypes do |bs, f|
				serialize_functype bs, f
			end
		end
		
		def serialize_import_section bytes, section
			#serialize_vec bytes, section.imports, &serialize_import
			serialize_vec bytes, section.imports do |bs, i|
				serialize_import bs, i
			end
		end
		
		def serialize_function_section bytes, section
			#serialize_vec bytes, section.type_indices, &serialize_uint
			serialize_vec bytes, section.type_indices do |bs, t|
				serialize_uint bs, t
			end
		end
		
		def serialize_table_section bytes, section
			#serialize_vec bytes, section.tabletypes, &serialize_tabletype
			serialize_vec bytes, section.tabletypes do |bs, t|
				serialize_tabletype bs, t
			end
		end
		
		def serialize_memory_section bytes, section
			#serialize_vec bytes, section.memtypes, &serialize_memtype
			serialize_vec bytes, section.memtypes do |bs, m|
				serialize_memtype bs, m
			end
		end
		
		def serialize_global_section bytes, section
			#serialize_vec bytes, section.globals, &serialize_global
			serialize_vec bytes, section.globals do |bs, g|
				serialize_global bs, g
			end
		end
		
		def serialize_export_section bytes, section
			#serialize_vec bytes, section.exports, &serialize_export
			serialize_vec bytes, section.exports do |bs, e|
				serialize_export bs, e
			end
		end
		
		def serialize_start_section bytes, section
			#serialize_vec bytes, section.starts, &serialize_start
			serialize_vec bytes, section.starts do |bs, s|
				serialize_start bs, s
			end
		end
		
		def serialize_element_section bytes, section
			#serialize_vec bytes, section.elements, &serialize_start
			serialize_vec bytes, section.elements do |bs, e|
				serialize_element bs, e
			end
		end
		
		def serialize_code_section bytes, section
			#serialize_vec bytes, section.codes, &serialize_code
			serialize_vec bytes, section.codes do |bs, i|
				serialize_code bs, i
			end
		end
		
		def serialize_data_section bytes, section
			#serialize_vec bytes, section.data, &serialize_code
			serialize_vec bytes, section.data do |bs, d|
				serialize_data bs, d
			end
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
			#serialize_vec bytes, result_tags, &serialize_uint
			serialize_vec bytes, result_tags do |bs, i|
				serialize_uint bs, i
			end
		end

		def serialize_import bytes, import
			serialize_name bytes, import.mod
			serialize_name bytes, import.name
			case import.desc
			when ImportTypeDesc
				bytes.push 0x00
				typeidx = import.desc.index
				serialize_uint bytes, typeidx.index
			when ImportTableDesc
				bytes.push 0x01
				serialize_reftype bytes, import.desc.reftype
				serialize_limits bytes, import.desc.limits
			when ImportMemoryDesc
				bytes.push 0x02
				serialize_limits bytes, import.desc.limits
			when ImportGlobalDesc
				bytes.push 0x03
				globaltype = import.desc.globaltype
				serialize_valtype bytes, globaltype.valtype
				serialize_mut bytes, globaltype.mut
			else
				raise StandardError.new("invalid import desc: #{import.desc.class.name}")
			end
		end

		def serialize_reftype bytes, reftype
			case reftype
			when :funcref
				bytes.push 0x70
			when :externref
				bytes.push 0x6f
			else
				raise StandardError.new("invalid reftype: #{reftype}")
			end
		end

		def serialize_limits bytes, limit
			if limit.max
				bytes.push 0x01
				serialize_uint bytes, limit.min
				serialize_uint bytes, limit.max
			else
				bytes.push 0x00
				serialize_uint bytes, limit.min
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

		def serialize_tabletype bytes, tabletype
			serialize_reftype bytes, tabletype.reftype
			serialize_limits bytes, tabletype.limits
		end

		def serialize_memtype bytes, memtype
			serialize_limits bytes, memtype.limits
		end

		def serialize_global bytes, global
			serialize_globaltype bytes, global.globaltype
			serialize_expression bytes, global.expr
		end

		def serialize_expression bytes, expr
			expr.each do |instr|
				serialize_instruction bytes, instr
			end
			bytes.push OP_BLOCK_END
		end

		def serialize_globaltype bytes, globaltype
			serialize_valtype bytes, globaltype.valtype
			serialize_mut bytes, globaltype.mut
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
			serialize_uint bytes, export.desc.index
		end

		def serialize_start bytes, start
			serialize_uint bytes, start.funcidx
		end

		def serialize_element bytes, element
			tag = element.tag
			serialize_uint bytes, tag
			case tag
			when 0b000
				serialize_expression bytes, element.expression
				serialize_vec bytes, element.funcidxs do |bs, f|
					serialize_uint bs, f
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
		end

		def serialize_code bytes, code
			code_body_bytes = []
			serialize_vec code_body_bytes, code.locals do |bs, i|
				serialize_locals bs, i
			end
			code.expressions.each do |instr|
				serialize_instruction code_body_bytes, instr
			end
			code_body_bytes.push OP_BLOCK_END
			
			serialize_uint bytes, code_body_bytes.size
			bytes.push *code_body_bytes
		end

		def serialize_locals bytes, locals
			serialize_uint bytes, locals.count
			serialize_valtype bytes, locals.valtype
		end

		def serialize_instruction bytes, instr
			bytes.push instr.class::TAG

			name = Instruction.name_by_tag instr.class::TAG
			method_name = "serialize_inst_#{name}"
			send method_name, bytes, instr
		end

		def serialize_inst_block bytes, instr
			serialize_blocktype bytes, instr.blocktype
			instr.instructions.each do |i|
				serialize_instruction bytes, i
			end
			bytes.push OP_BLOCK_END
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
			bytes.push OP_BLOCK_END
		end

		def serialize_inst_if bytes, instr
			serialize_blocktype bytes, instr.blocktype
			instr.then_instructions.each do |i|
				serialize_instruction bytes, i
			end
			if instr.else_instructions
				bytes.push OP_THEN_END
				instr.else_instructions.each do |i|
					serialize_instruction bytes, i
				end
			end
			bytes.push OP_BLOCK_END
		end

		# TODO: same as br_if
		def serialize_inst_br bytes, instr
			serialize_uint bytes, instr.labelidx
		end

		def serialize_inst_br_if bytes, instr
			serialize_uint bytes, instr.labelidx
		end

		def serialize_inst_return bytes, instr
			# pass
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
			"i32_load" => {"memarg" => "serialize_memarg"},
			"i32_load8s" => {"memarg" => "serialize_memarg"},
			"i32_load8u" => {"memarg" => "serialize_memarg"},
			"i32_load16s" => {"memarg" => "serialize_memarg"},
			"i32_load16u" => {"memarg" => "serialize_memarg"},
			"i32_store" => {"memarg" => "serialize_memarg"},
			"i32_store8" => {"memarg" => "serialize_memarg"},
			"i32_store16" => {"memarg" => "serialize_memarg"},
			"memory_size" => [],
			"memory_grow" => [],
			"memory_init" => ["dataidx"],
			"data_drop" => ["dataidx"],
			"memory_copy" => [],
			"memory_fill" => [],
			"i32_const" => {"value" => "serialize_sint"},
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

			"i64_load" => {"memarg" => "serialize_memarg"},
			"i64_store" => {"memarg" => "serialize_memarg"},

			"f64_const" => {"value" => "serialize_f64"},
			"f64_load" => {"memarg" => "serialize_memarg"},
			"f64_add" => [],
			"f64_sqrt" => [],
			"f64_convert_i32s" => [],
		}.each do |name, props|
			define_method "serialize_inst_#{name}" do |bytes, instr|
				if props.instance_of? Array
					props.each do |prop|
						serialize_uint bytes, instr.send(prop)
					end
				else
					props.each do |prop, serializer|
						send serializer, bytes, instr.send(prop)
					end
				end
			end
		end

		def serialize_memarg bytes, memarg
			serialize_uint bytes, memarg.align
			serialize_uint bytes, memarg.offset
		end

		def serialize_data bytes, data
			if data.memidx 
				bytes.push 0x02
			elsif data.expressions
				bytes.push 0x00
			else 
				bytes.push 0x01
			end

			if data.memidx
				serialize_uint bytes, data.memidx
			end
			if data.expressions
				serialize_expression bytes, data.expressions
			end
			serialize_vec bytes, data.bytes do |bs, b|
				bytes.push b
			end
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

		alias serialize_uint serialize_leb128

		def serialize_signed_leb128 bytes, num
			return serialize_leb128(bytes, num) if 0 <= num

			num = -(num+1)
			bs = []
			loop do
				low = num & 0b01111111
				low = low ^ 0b01111111
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
		alias serialize_sint serialize_signed_leb128

		def serialize_name bytes, name
			chars = name.unpack("C*")
			serialize_vec bytes, chars do |bt, c|
				bt.push c
			end
		end

		def serialize_f64 bytes, num
			bytes.push *([num].pack("d").unpack("C*"))
		end

		def serialize_vec bytes, items, &serialize
			serialize_uint bytes, items.size
			items.each do |item|
				serialize.call bytes, item
			end
		end
	end
end