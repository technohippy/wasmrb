WASM.rb
###

WASM loader and runner in Ruby language

I'm developing this tool for a learning purpose.
There must be many bugs and unimplemented specs.

How to Use
---

### How to Load and Inspect

Code:

```ruby
loader = WebAssembly::WASMLoader.new
mod = loader.load "understanding-text-format/add.wasm"
pp mod
```

Output:

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

### How to Run

Code:

```ruby
inst = mod.instantiate
puts inst.exports.add(1, 2)
```

Output:

```
3
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

== Refs.

- https://webassembly.github.io/spec/