(module
  (func (export "switch") (param $param i32) (result i32)
    (block $b1
      (block $b2
        (block $b3
          (local.get $param)
          (br_table $b1 $b2 $b3)
        )
        (i32.const 3)
        (return)
      )
      (i32.const 2)
      (return)
    )
    (i32.const 1)
  )
)