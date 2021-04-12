(module
  (func (export "return1") (result i32)
    (local $ret i32)
    (local $i i32)
    (local $j i32)

    (local.set $ret (i32.const 0))
    (local.set $i (i32.const 0))
    (block $outerblock (loop $outerloop
      (br_if $outerblock (i32.ge_u (local.get $i) (i32.const 10)))
      (local.set $i (i32.add (local.get $i) (i32.const 1)))

      (local.set $j (i32.const 0))
      (block $innerblock (loop $innerloop
        (br_if $innerblock (i32.ge_u (local.get $j) (i32.const 10)))
        (local.set $j (i32.add (local.get $j) (i32.const 1)))

        (local.set $ret (i32.add (local.get $ret) (i32.const 1)))
        (local.get $ret)
        (return)
        (br $innerloop) ;; skip
      ))

      (br $outerloop) ;; skip
    ))
    (local.get $ret) ;; skip
  )
)