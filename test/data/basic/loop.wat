(module
  (func (export "doubleloop") (result i32)
    (local $i i32)
    (local $j i32)
    (local $sum i32)

    (local.set $sum (i32.const 0))
    (local.set $i (i32.const 0))
    (block $outer (loop $outerloop
      (br_if $outer (i32.ge_u (local.get $i) (i32.const 3)))
      (local.set $i (i32.add (local.get $i) (i32.const 1)))
      (local.set $sum (i32.add (local.get $sum) (i32.const 100)))

      (local.set $j (i32.const 0))
      (block $inner (loop $innerloop
        (br_if $inner (i32.ge_u (local.get $j) (i32.const 5)))
        (local.set $j (i32.add (local.get $j) (i32.const 1)))

        (local.set $sum (i32.add (local.get $sum) (i32.const 1)))
        (br $innerloop)
      ))
      (br $outerloop)
    ))
    (local.get $sum)
  )
)