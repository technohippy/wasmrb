### 読込

- [x] リフレクションを使用してInstruction周りのコードをまとめる
- [ ] 後回しにしてるコードを足す
	- [ ] Instruction
		- [ ] i32以外
	- [x] Section

### 実行

- [x] インスタンス化して実行
	- type, code, funcの情報をまとめて呼び出し可能な関数を生成
- [ ] 後回しにしてるコードを足す
	- [ ] Instruction
		- [ ] i32以外
		- [ ] 整数の符号ありなし対応

### 生成

- [ ] wasmを生成

### 拡張

- [ ] watっぽいドメイン特化言語を使ってModule定義

### リファクタリング

- [ ] テスト作成
- [ ] プロパティ名を仕様書に合わせる
- [ ] ファイル分割
- [ ] attr_accessorを使っている部分を一部attr_readerに

### リリース

- [ ] 諸々の機能をコマンドとして呼べるように
- [ ] gem化

### その他

- [ ] irb/pry内でwasmを解析したり書き換えたり
- [ ] watを読み込み
- [ ] watを生成
- [ ] 生成したwasmを呼び出すhtml/jsの雛形も合わせて生成
- [ ] エラーメッセージ詳細化
- [ ] moduleの中身をqueryStringのような形式で取り出して変更できるように
	- いまは今はこうするしかない
		- const = mod.code_section.codes[0].expressions[6].instructions[0].instructions[10]
		- const.value = 1