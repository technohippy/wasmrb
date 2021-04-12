(module
  (func (export "less10") (param $param i32) (result i32)
    (if (result i32) (i32.lt_u (local.get $param) (i32.const 10))
      (then (i32.const 1))
      (else (i32.const 0))
    )
  )
)