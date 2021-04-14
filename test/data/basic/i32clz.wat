(module
  (func (export "i32clz") (param $param i32) (result i32)
    (i32.clz (local.get $param))
  )
)