(module
  (func (export "i32popcnt") (param $param i32) (result i32)
    (i32.popcnt (local.get $param))
  )
)