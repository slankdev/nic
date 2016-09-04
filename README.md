
# NIC自作
詳しくはdoc以下を参照してください


## 動機
 - 少しずつ低いレイヤに移動していきたい。。
 - L2-L4まで全部オレオレネットワーク


## 開発環境
Windowsはあまり好きでないが、なんかあんまり情報が多くないのでWin機
を持ち歩いてそこで開発します。

 - ホストPC: Windows10
 - IDE: Quartus II 12.1sp Web Edition
 - FPGA開発ボード: Terasic DE0 (Altera CycloneIII)
 - その他環境: DE0拡張ボードをCQ出版社から購入してそれを使用


## 手順
まずはMII/RMIIインターフェースをFPGAで制御して以下のことを行う

 1. リンクアップ、phyレジスタ操作
 1. パケット受信
 1. パケット送信
 1. MACをFPGAで構成
 1. Linux用デバイスドライバを実装して操作


## 参考文献
使用するサンプルはkozosプロジェクトの坂井さんのサイトを参考にさせていただきました。
ありがとうございます。

 - http://kozos.jp/fpga/index.html



