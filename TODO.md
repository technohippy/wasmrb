# TODO

## 読込

- [x] リフレクションを使用してInstruction周りのコードをまとめる
- [ ] 後回しにしてるコードを足す
	- [ ] Instruction
		- [ ] i32以外
	- [x] Section

## 実行

- [x] インスタンス化して実行
	- type, code, funcの情報をまとめて呼び出し可能な関数を生成
- [ ] 後回しにしてるコードを足す
	- [ ] Instruction
		- [ ] i32以外
		- [ ] 整数の符号ありなし対応

## 生成

- [ ] wasmを生成

## 拡張

- [ ] watっぽいドメイン特化言語を使ってModule定義

## リファクタリング

- [ ] テスト作成
- [ ] プロパティ名を仕様書に合わせる
- [ ] ファイル分割
- [ ] attr_accessorを使っている部分を一部attr_readerに

## リリース

- [ ] 諸々の機能をコマンドとして呼べるように
- [ ] gem化

## その他

- [ ] irb/pry内でwasmを解析したり書き換えたり
- [ ] watを読み込み
- [ ] watを生成
- [ ] 生成したwasmを呼び出すhtml/jsの雛形も合わせて生成
- [ ] エラーメッセージ詳細化
- [ ] moduleの中身をqueryStringのような形式で取り出して変更できるように
	- いまは今はこうするしかない
		- const = mod.code_section.codes[0].expressions[6].instructions[0].instructions[10]
		- const.value = 1

# OPコード進捗

| op                  | load | save | exec |
| ------------------- | ---- | ---- | ---- |
| nop                 |      |      |      |
| unreachable         |      |      |      |
| block               |      |      |      |
| loop                |      |      |      |
| if                  |      |      |      |
| br                  |      |      |      |
| br_if               |      |      |      |
| br_table            |      |      |      |
| return              |      |      |      |
| call                |      |      |      |
| call_indirect       |      |      |      |
| i32.const           |      |      |      |
| f32.const           |      |      |      |
| i64.const           |      |      |      |
| f64.const           |      |      |      |
| i32.clz             |      |      |      |
| i32.ctz             |      |      |      |
| i32.popcnt          |      |      |      |
| i32.add             |      |      |      |
| i32.sub             |      |      |      |
| i32.mul             |      |      |      |
| i32.div_s           |      |      |      |
| i32.div_u           |      |      |      |
| i32.rem_s           |      |      |      |
| i32.rem_u           |      |      |      |
| i32.and             |      |      |      |
| i32.or              |      |      |      |
| i32.xor             |      |      |      |
| i32.shl             |      |      |      |
| i32.shr_s           |      |      |      |
| i32.shr_u           |      |      |      |
| i32.rotl            |      |      |      |
| i32.rotr            |      |      |      |
| i64.clz             |      |      |      |
| i64.ctz             |      |      |      |
| i64.popcnt          |      |      |      |
| i64.add             |      |      |      |
| i64.sub             |      |      |      |
| i64.mul             |      |      |      |
| i64.div_s           |      |      |      |
| i64.div_u           |      |      |      |
| i64.rem_s           |      |      |      |
| i64.rem_u           |      |      |      |
| i64.and             |      |      |      |
| i64.or              |      |      |      |
| i64.xor             |      |      |      |
| i64.shl             |      |      |      |
| i64.shr_s           |      |      |      |
| i64.shr_u           |      |      |      |
| i64.rotl            |      |      |      |
| i64.rotr            |      |      |      |
| f32.abs             |      |      |      |
| f32.neg             |      |      |      |
| f32.sqrt            |      |      |      |
| f32.ceil            |      |      |      |
| f32.floor           |      |      |      |
| f32.trunc           |      |      |      |
| f32.nearest         |      |      |      |
| f64.abs             |      |      |      |
| f64.neg             |      |      |      |
| f64.sqrt            |      |      |      |
| f64.ceil            |      |      |      |
| f64.floor           |      |      |      |
| f64.trunc           |      |      |      |
| f64.nearest         |      |      |      |
| f32.add             |      |      |      |
| f32.sub             |      |      |      |
| f32.mul             |      |      |      |
| f32.div             |      |      |      |
| f32.min             |      |      |      |
| f32.max             |      |      |      |
| f32.copysign        |      |      |      |
| f64.add             |      |      |      |
| f64.sub             |      |      |      |
| f64.mul             |      |      |      |
| f64.div             |      |      |      |
| f64.min             |      |      |      |
| f64.max             |      |      |      |
| f64.copysign        |      |      |      |
| i32.eqz             |      |      |      |
| i32.eq              |      |      |      |
| i32.ne              |      |      |      |
| i32.lt_s            |      |      |      |
| i32.lt_u            |      |      |      |
| i32.gt_s            |      |      |      |
| i32.gt_u            |      |      |      |
| i32.le_s            |      |      |      |
| i32.le_u            |      |      |      |
| i32.ge_s            |      |      |      |
| i32.ge_u            |      |      |      |
| f32.eq              |      |      |      |
| f32.ne              |      |      |      |
| f32.lt              |      |      |      |
| f32.gt              |      |      |      |
| f32.le              |      |      |      |
| f32.ge              |      |      |      |
| i64.eqz             |      |      |      |
| i64.eq              |      |      |      |
| i64.ne              |      |      |      |
| i64.lt_s            |      |      |      |
| i64.lt_u            |      |      |      |
| i64.gt_s            |      |      |      |
| i64.gt_u            |      |      |      |
| i64.le_s            |      |      |      |
| i64.le_u            |      |      |      |
| i64.ge_s            |      |      |      |
| i64.ge_u            |      |      |      |
| f64.eq              |      |      |      |
| f64.ne              |      |      |      |
| f64.lt              |      |      |      |
| f64.gt              |      |      |      |
| f64.le              |      |      |      |
| f64.ge              |      |      |      |
| ref.null            |      |      |      |
| ref.is_null         |      |      |      |
| ref.func            |      |      |      |
| drop                |      |      |      |
| select              |      |      |      |
| local.get           |      |      |      |
| local.set           |      |      |      |
| local.tee           |      |      |      |
| global.get          |      |      |      |
| global.set          |      |      |      |
| table.get           |      |      |      |
| table.set           |      |      |      |
| table.size          |      |      |      |
| table.grow          |      |      |      |
| table.fill          |      |      |      |
| table.copy          |      |      |      |
| table.init          |      |      |      |
| elem.drop           |      |      |      |
| i32.load            |      |      |      |
| f32.load            |      |      |      |
| i32.store           |      |      |      |
| f32.store           |      |      |      |
| i32.load8_s         |      |      |      |
| i32.load8_u         |      |      |      |
| i32.load16_s        |      |      |      |
| i32.load16_u        |      |      |      |
| i64.load            |      |      |      |
| f64.load            |      |      |      |
| i64.store           |      |      |      |
| f64.store           |      |      |      |
| i64.load8_s         |      |      |      |
| i64.load8_u         |      |      |      |
| i64.load16_s        |      |      |      |
| i64.load16_u        |      |      |      |
| i64.load32_s        |      |      |      |
| i64.load32_u        |      |      |      |
| i32.store8          |      |      |      |
| i32.store16         |      |      |      |
| i64.store8          |      |      |      |
| i64.store16         |      |      |      |
| i64.store32         |      |      |      |
| memory.size         |      |      |      |
| memory.grow         |      |      |      |
| memory.fill         |      |      |      |
| memory.copy         |      |      |      |
| memory.init         |      |      |      |
| data.drop           |      |      |      |
| i32.extend8_s       |      |      |      |
| i32.extend16_s      |      |      |      |
| i64.extend8_s       |      |      |      |
| i64.extend16_s      |      |      |      |
| i64.extend32_s      |      |      |      |
| i32.wrap_i64        |      |      |      |
| i64.extend_i32_s    |      |      |      |
| i64.extend_i32_u    |      |      |      |
| i32.trunc_f32_s     |      |      |      |
| i32.trunc_f32_u     |      |      |      |
| i32.trunc_sat_f32_s |      |      |      |
| i32.trunc_sat_f32_u |      |      |      |
| i64.trunc_f32_s     |      |      |      |
| i64.trunc_f32_u     |      |      |      |
| i64.trunc_sat_f32_s |      |      |      |
| i64.trunc_sat_f32_u |      |      |      |
| i32.trunc_f64_s     |      |      |      |
| i32.trunc_f64_u     |      |      |      |
| i32.trunc_sat_f64_s |      |      |      |
| i32.trunc_sat_f64_u |      |      |      |
| i64.trunc_f64_s     |      |      |      |
| i64.trunc_f64_u     |      |      |      |
| i64.trunc_sat_f64_s |      |      |      |
| i64.trunc_sat_f64_u |      |      |      |
| f32.demote_f64      |      |      |      |
| f64.promote_f32     |      |      |      |
| f32.convert_i32_s   |      |      |      |
| f32.convert_i32_u   |      |      |      |
| i32.reinterpret_f32 |      |      |      |
| f32.reinterpret_i32 |      |      |      |
| f64.convert_i32_s   |      |      |      |
| f64.convert_i32_u   |      |      |      |
| i64.reinterpret_f64 |      |      |      |
| f64.reinterpret_i64 |      |      |      |
| f32.convert_i64_s   |      |      |      |
| f32.convert_i64_u   |      |      |      |
| i32.reinterpret_f32 |      |      |      |
| f32.reinterpret_i32 |      |      |      |
| f64.convert_i64_s   |      |      |      |
| f64.convert_i64_u   |      |      |      |
| i64.reinterpret_f64 |      |      |      |
| f64.reinterpret_i64 |      |      |      |