# dmg2upc.pl

## これなに？

Ingress Damage Reportを元に、UPCを列挙したKMLファイルを生成します。

現状、対応しているのは、Macの"Mail"です。

## 使い方

第一引数：メールボックスフォルダ

第二引数：agent名

→Ownerが第二引数と一致するポータルを、標準出力へKML形式で出力（"Google Earth"アプリで開けます。）

例）

```
perl dmg2upc.pl /Users/daisuke/Library/Mail/V2/Mailboxes/Ingress\ Damage\ Report.mbox dk1538 >upc.kml
```


なお、第二引数を省略すると、Ownerに関わらずすべてのポータルを出力します。

