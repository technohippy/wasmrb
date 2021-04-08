module WebAssembly
	class Instance
		attr_reader :exports, :exported_methods
		attr_reader :context # TODO: for dev

		def initialize mod, import_object=nil
			@mod = mod
			@import_object = import_object
			@context = Context.new
			@exports = Object.new
			@exported_methods = []
		end

		def compile
			type_section = @mod.type_section

			# import
			import_section = @mod.import_section
			if import_section
				import_section.imports.each do |i|
					obj = i.retrieve @import_object
					case i.desc
					when ImportMemoryDesc
						memdesc = i.desc
						@context.memories.push obj
					when ImportTableDesc
						tabledesc = i.desc
						@context.tables.push obj
					when ImportTypeDesc
						funcdesc = i.desc
						@context.functions.push ImportedFunction.new(type_section.functypes[funcdesc.index.index], obj)
					when ImportGlobalDesc
						globaldesc = i.desc
						@context.globals.push obj
					end
				end
			end

			# function
			function_section = @mod.function_section
			code_section = @mod.code_section
			if function_section
				function_section.type_indices.each_with_index do |ti, i|
					@context.functions.push Function.new(type_section.functypes[ti], code_section.codes[i])
				end
			end

			# export
			export_section = @mod.export_section
			if export_section
				export_section.exports.each do |e|
					case e.desc
					when FuncIndex
						@exported_methods.push e.name
						context = @context
						functions = @context.functions
						@exports.define_singleton_method e.name do |*args|
							result = functions[e.desc.index].call(context, *args)
							#context.clear_stack # TODO: check spec
							result
						end
					when TableIndex
						tables = @context.tables
						@exports.define_singleton_method e.name do
							tables[e.desc.index]
						end
					when MemoryIndex
						memories = @context.memories
						@exports.define_singleton_method e.name do
							memories[e.desc.index]
						end
					when GlobalIndex
						globals = @context.globals
						@exports.define_singleton_method e.name do
							globals[e.desc.index]
						end
					end
				end
			end

			# data
			data_section = @mod.data_section
			if data_section
				data_section.data.each do |data|
					memidx = data.memidx || 0
					mem = @context.memories[memidx]
					ctx = Context.new
					data.expressions.each {|instr| instr.call ctx}
					offset = ctx.stack.pop
					data.bytes.each_with_index do |b, i|
						mem[i+offset] = b
					end
				end
			end

			# table
			table_section = @mod.table_section
			if table_section
				table_section.tabletypes.each do |tt|
					@context.tables.push []
				end
			end

			# element
			elem_section = @mod.element_section
			if elem_section
				elem_section.elements.each do |elem|
					ctx = Context.new
					elem.expression.each {|instr| instr.call ctx}
					tblidx = ctx.stack.pop
					table = @context.tables[tblidx]
					elem.funcidxs.each do |funcidx|
						table.push @context.functions[funcidx]
					end
				end
			end
		end
	end

	class Function
		def initialize functype, code
			@type = functype
			@code = code
		end

		def call context, *args
			args.each_with_index do |arg, i|
				context.locals[i] = arg
			end
			@code.locals.each do |local|
				local.count.times do
					context.locals.push 0
				end
			end
			@code.expressions.each do |instr|
				instr.call context
			end
			context.stack[context.stack.length-1]
		end

		def to_hash
			{
				:type => @type.to_hash,
				:code => @code.to_hash,
			}
		end
	end

	class ImportedFunction
		def initialize functype, code
			@type = functype
			@code = code
		end

		def call context
			args = []
			@type.params.length.times do
				args.unshift context.stack.pop
			end
			result = @code.call(*args)
			context.stack.push result unless @type.results.empty?
		end

		def to_hash
			{
				:type => @type.to_hash,
				:code => @code
			}
		end
	end

	class Context
		class Global
			attr_accessor :value

			def initialize value
				@value = value
			end
		end

		attr_reader :stack, :tables, :memories, :functions, :globals, :locals
		attr_accessor :branch

		def initialize
			@stack = []
			@functions = []
			@memories = []
			@tables = []
			@globals = []
			@locals = []
			@branch = -1
		end

		def clear_stack
			@stack.clear
		end
	end
end