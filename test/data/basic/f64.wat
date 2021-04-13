(module
  (memory (import "js" "mem") 1)
  (func (export "addf64") (param $param f64) (result f64)
    (f64.add (local.get $param) (f64.load (i32.const 0)))
    (f64.add (f64.const 1.2))
  )
)