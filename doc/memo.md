
# メモ

## 開発環境(詳細)
 - PHYチップ型番: ICS1894-43 (FPGAとはRMIIインターフェースで接続)
 - PHYデータシート: https://www.idt.com/document/dst/1894-43-datasheet


## DE0と拡張ボードの接続情報
外側のGPIOと拡張ボードが接続されている。接続されているピンの情報を以下に示す。

| Name         | GPIO No  | Pin No     |
|:------------:|:--------:|:----------:|
| E\_TXER      | -        | PIN\_      |
| E\_TXEN      | 2        | PIN\_AA20  |
| E\_TX1       | 6        | PIN\_AB19  |
| E\_TX0       | 4        | PIN\_AB20  |

| Name         | GPIO No  | Pin No     |
|:------------:|:--------:|:----------:|
| E\_RMII/RXDV | -        | PIN\_      |
| E\_RXDV      | 1        | PIN\_AA22  |
| E\_RXER      | 3        | PIN\_      |
| E\_RX1       | 5        | PIN\_AB18  |
| E\_RX0       | 7        | PIN\_AA19  |


| Name         | GPIO No  | Pin No     |
|:------------:|:--------:|:----------:|
| E\_MDC       | 10       | PIN\_AB17  |
| E\_MDIO      | 8        | PIN\_AA18  |
| E\_nINT      | 25       | PIN\_      |
| E\_nRST      | 9        | PIN\_      |
| E\_REFCK     | 19       | PIN\_R16   |
