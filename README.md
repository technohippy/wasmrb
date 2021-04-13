WASM.rb
====

WASM Runner in Ruby language

I'm developing this tool for a learning purpose.
There must be many bugs and unimplemented specs.

How to Test
----

```
$ ruby test/run-test.rb
```

How to Use
---

### Load and Inspect

#### Code:

```ruby
loader = WebAssembly::WASMLoader.new
mod = loader.load "add.wasm"
pp mod.to_hash
```

##### Shortcut:

```ruby
mod = WebAssembly::load "add.wasm"
pp mod.to_hash
```

#### Output:

```ruby
{:magic=>[0, 97, 115, 109],
 :version=>[1, 0, 0, 0],
 :sections=>
  [{:section=>"type",
    :id=>1,
    :size=>7,
    :types=>[{:params=>[:i32, :i32], :results=>[:i32]}]},
   {:section=>"function", :id=>3, :size=>2, :types=>[0]},
   {:section=>"export",
    :id=>7,
    :size=>7,
    :exports=>[{:name=>"add", :desc=>{:func=>0}}]},
   {:section=>"code",
    :id=>10,
    :size=>9,
    :codes=>
     [{:locals=>[],
       :expressions=>
        [{:name=>"local.get", :index=>0},
         {:name=>"local.get", :index=>1},
         {:name=>"i32.add"}]}]}]}
```

### Run Exported Function

#### Code:

```ruby
loader = WebAssembly::WASMLoader.new
mod = loader.load "add.wasm"
inst = mod.instantiate
puts inst.exports.add(1, 2)
```

##### Shortcut:

```ruby
inst = WebAssembly::instantiate "add.wasm"
puts inst.exports.add(1, 2)
```

#### Output:

```
3
```

#### Code (with import_object):

```ruby
loader = WebAssembly::WASMLoader.new
mod = loader.load "logger.wasm"

import_object = {
  :console => {
    :log => lambda {|msg| puts msg}
  }
}
inst = mod.instantiate import_object
inst.exports.logIt()
```

##### Shortcut:

```ruby
import_object = {
  :console => {
    :log => lambda {|msg| puts msg}
  }
}
inst = WebAssembly::instantiate "logger.wasm", imprt_object
inst.exports.logIt()
```

#### Output:

```
13
```

### Construct Module with Code

#### Code:

```ruby
type_section = WebAssembly::TypeSection.new
type_section.add_functype WebAssembly::FuncType.new([:i32, :i32], [:i32])

function_section = WebAssembly::FunctionSection.new
function_section.add_type_index 0

export = WebAssembly::Export.new
export.name = "add"
export.desc = WebAssembly::FuncIndex.new 0
export_section = WebAssembly::ExportSection.new
export_section.add_export export

code = WebAssembly::Code.new
code.add_expression WebAssembly::LocalGetInstruction.new(0)
code.add_expression WebAssembly::LocalGetInstruction.new(1)
code.add_expression WebAssembly::I32AddInstruction.new
code_section = WebAssembly::CodeSection.new
code_section.add_code code

mod = WebAssembly::Module.new [type_section, function_section, export_section, code_section]

inst = mod.instantiate
puts inst.exports.add(1, 2)
```

#### Output:

```
3
```

##### DSL (experimental)

[simple-dsl.rb](https://github.com/technohippy/wasmrb/blob/master/misc/simple-dsl.rb)

Code:

```ruby
wasm =  mod {
          func :f1, [:i32, :i32] => [:i32] {
            i32.add arg(0), arg(1)
            i32.add call(:f2)
          }
          
          func :f2, [] => [:i32] {
            i32.const 42
          }

          export "add42", :f1
        }

inst = wasm.instantiate
puts inst.exports.add42(1, 2) # 1+2+42 = 45
```

Output:

```
45
```

### Serialize Module into WASM

```ruby
serializer = WebAssembly::WASMSerializer.new
bytes = serializer.serialize mod
File.binwrite "add.wasm", bytes.pack("C*")
```

Sample Codes
----

### Global 

```ruby
global = WebAssembly::Context::Global.new 0
mod = loader.load "js-api-examples/global.wasm"
inst = mod.instantiate :js => {
  :global => global
}
puts inst.exports.getGlobal() # 0
global.value = 42
puts inst.exports.getGlobal() # 42
inst.exports.incGlobal()
puts inst.exports.getGlobal() # 43
```

### Memory

```ruby
mod = loader.load "js-api-examples/memory.wasm"
inst = mod.instantiate :js => {
  :mem => (0..9).to_a.pack("i*").unpack("C*")
}
puts inst.exports.accumulate(0, 10) # 45
```

```ruby
mod = loader.load "understanding-text-format/logger2.wasm"
mem = []
inst = mod.instantiate(
  :console => {
    :log => lambda {|offset, length|
      bytes = mem[offset...(offset+length)]
      puts bytes.pack("U*")
    }
  },
  :js => {
    :mem => mem
  }
)
inst.exports.writeHi() # Hi
```

### Table

```ruby
mod = loader.load "js-api-examples/table.wasm"
inst = mod.instantiate
puts inst.exports.tbl[0].call # 13
puts inst.exports.tbl[1].call # 42
```

```ruby
tbl = []
mod = loader.load "js-api-examples/table2.wasm"
inst = mod.instantiate :js => {
  :tbl => tbl
}
puts tbl[0].call # 42
puts tbl[1].call # 83
```

```ruby
mod = loader.load "understanding-text-format/wasm-table.wasm"
inst = mod.instantiate
puts inst.exports.callByIndex(0) # 42
puts inst.exports.callByIndex(1) # 13
begin
  puts inst.exports.callByIndex(2) # error
rescue => e
  puts e
end
```

### Shared

```ruby
import_object = {
  :js => {
    :memory => [],
    :table => []
  }
}
mod0 = loader.load "understanding-text-format/shared0.wasm"
inst0 = mod0.instantiate import_object
mod1 = loader.load "understanding-text-format/shared1.wasm"
inst1 = mod1.instantiate import_object
puts inst1.exports.doIt() # 42
```

Refs.
----

- [WebAssembly Specification](https://webassembly.github.io/spec/)
- [WebAssembly Opcodes](https://pengowray.github.io/wasm-ops/)
- [WebAssembly Examples (MDN)](https://github.com/mdn/webassembly-examples)