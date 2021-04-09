読込

- [v] リフレクションを使用してInstruction周りのコードをまとめる
- 足りないコードを埋める
	- Instruction
	- [v] Section

実行

- インスタンス化して実行
	- type, code, funcの情報をまとめて呼び出し可能な関数を生成

生成

- wasmを生成

拡張

- watっぽいドメイン特化言語を使ってModule定義

リリース

- 諸々の機能をコマンドとして呼べるように
- gem化

追加

- watを読み込み
- watを生成
- wasmを呼び出すhtml/jsも生成
- エラーメッセージ詳細化
- moduleの中身をqueryStringのような形式で取り出して変更できるように
	- いまは今はこうするしかない
		- const = mod.code_section.codes[0].expressions[6].instructions[0].instructions[10]
		- const.value = 1