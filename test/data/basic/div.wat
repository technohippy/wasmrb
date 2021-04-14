(module
  (func (export "div_u") (param $p1 i32) (param $p2 i32) (result i32)
    (i32.div_u (local.get $p1) (local.get $p2))
  )
  (func (export "div_s") (param $p1 i32) (param $p2 i32) (result i32)
    (i32.div_s (local.get $p1) (local.get $p2))
  )
)