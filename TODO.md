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

- [x] add.wasmを生成
- [ ] 後回しにしてるコードを足す

## 拡張

- [x] コードを使用してModule構築
- [ ] watっぽいドメイン特化言語を使ってModule定義

## リファクタリング

- [x] テスト作成
- [ ] プロパティ名を仕様書に合わせる
- [ ] ファイル分割
- [ ] attr_accessorを使っている部分を一部attr_readerに
- [ ] expr, expression, expressionsが混在してる

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
- [ ] to_json
	- require "json"; mod.to_hash.to_json でいいかも

# OPコード進捗

| op                  | load | save | exec |
| ------------------- | ---- | ---- | ---- |
| nop                 | o    | o    | o    |
| unreachable         | o    | o    | o    |
| block               | o    | o    | o    |
| loop                | o    | o    | o    |
| if                  | o    | o    | o    |
| br                  | o    | o    | o    |
| br_if               | o    | o    | o    |
| br_table            | o    | o    | o    |
| return              | o    | o    | o    |
| call                | o    | o    | o    |
| call_indirect       | o    | o    | o    |
| i32.const           | o    | o    | o    |
| f32.const           |      |      |      |
| i64.const           |      |      |      |
| f64.const           | o    |      | o    |
| i32.clz             | o    | o    |      |
| i32.ctz             | o    | o    |      |
| i32.popcnt          | o    | o    |      |
| i32.add             | o    | o    | o    |
| i32.sub             | o    | o    | o    |
| i32.mul             | o    | o    | o    |
| i32.div_s           | o    | o    | o    |
| i32.div_u           | o    | o    | o    |
| i32.rem_s           | o    | o    |      |
| i32.rem_u           | o    | o    |      |
| i32.and             | o    | o    | o    |
| i32.or              | o    | o    | o    |
| i32.xor             | o    | o    | o    |
| i32.shl             | o    | o    |      |
| i32.shr_s           | o    | o    |      |
| i32.shr_u           | o    | o    |      |
| i32.rotl            | o    | o    |      |
| i32.rotr            | o    | o    |      |
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
| f64.add             | o    |      | o    |
| f64.sub             |      |      |      |
| f64.mul             |      |      |      |
| f64.div             |      |      |      |
| f64.min             |      |      |      |
| f64.max             |      |      |      |
| f64.copysign        |      |      |      |
| i32.eqz             | o    | o    | o    |
| i32.eq              | o    | o    | o    |
| i32.ne              | o    | o    | o    |
| i32.lt_s            | o    | o    | o    |
| i32.lt_u            | o    | o    | o    |
| i32.gt_s            | o    | o    | o    |
| i32.gt_u            | o    | o    | o    |
| i32.le_s            | o    | o    | o    |
| i32.le_u            | o    | o    | o    |
| i32.ge_s            | o    | o    | o    |
| i32.ge_u            | o    | o    | o    |
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
| ref.null            | o    | o    |      |
| ref.is_null         | o    | o    |      |
| ref.func            | o    | o    |      |
| drop                | o    | o    |      |
| select              | o    | o    |      |
| local.get           | o    | o    | o    |
| local.set           | o    | o    | o    |
| local.tee           | o    | o    | o    |
| global.get          | o    | o    | o    |
| global.set          | o    | o    | o    |
| table.get           | o    | o    |      |
| table.set           | o    | o    |      |
| table.size          | o    | o    |      |
| table.grow          | o    | o    |      |
| table.fill          | o    | o    |      |
| table.copy          | o    | o    |      |
| table.init          | o    | o    |      |
| elem.drop           | o    | o    |      |
| i32.load            | o    | o    | o    |
| f32.load            |      |      |      |
| i32.store           | o    | o    | o    |
| f32.store           |      |      |      |
| i32.load8_s         | o    | o    |      |
| i32.load8_u         | o    | o    |      |
| i32.load16_s        | o    | o    |      |
| i32.load16_u        | o    | o    |      |
| i64.load            |      |      |      |
| f64.load            | o    |      | o    |
| i64.store           |      |      |      |
| f64.store           |      |      |      |
| i64.load8_s         |      |      |      |
| i64.load8_u         |      |      |      |
| i64.load16_s        |      |      |      |
| i64.load16_u        |      |      |      |
| i64.load32_s        |      |      |      |
| i64.load32_u        |      |      |      |
| i32.store8          | o    | o    |      |
| i32.store16         | o    | o    |      |
| i64.store8          |      |      |      |
| i64.store16         |      |      |      |
| i64.store32         |      |      |      |
| memory.size         | o    | o    |      |
| memory.grow         | o    | o    |      |
| memory.fill         | o    | o    |      |
| memory.copy         | o    | o    |      |
| memory.init         | o    | o    |      |
| data.drop           | o    | o    |      |
| i32.extend8_s       | o    | o    |      |
| i32.extend16_s      | o    | o    |      |
| i64.extend8_s       |      |      |      |
| i64.extend16_s      |      |      |      |
| i64.extend32_s      |      |      |      |
| i32.wrap_i64        | o    | o    |      |
| i64.extend_i32_s    |      |      |      |
| i64.extend_i32_u    |      |      |      |
| i32.trunc_f32_s     | o    | o    |      |
| i32.trunc_f32_u     | o    | o    |      |
| i32.trunc_sat_f32_s | o    | o    |      |
| i32.trunc_sat_f32_u | o    | o    |      |
| i64.trunc_f32_s     |      |      |      |
| i64.trunc_f32_u     |      |      |      |
| i64.trunc_sat_f32_s |      |      |      |
| i64.trunc_sat_f32_u |      |      |      |
| i32.trunc_f64_s     | o    | o    |      |
| i32.trunc_f64_u     | o    | o    |      |
| i32.trunc_sat_f64_s | o    | o    |      |
| i32.trunc_sat_f64_u | o    | o    |      |
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
| i32.reinterpret_f32 | o    | o    |      |
| f32.reinterpret_i32 |      |      |      |
| f64.convert_i64_s   |      |      |      |
| f64.convert_i64_u   |      |      |      |
| i64.reinterpret_f64 |      |      |      |
| f64.reinterpret_i64 |      |      |      |