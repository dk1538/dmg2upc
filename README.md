# dmg2upc.pl

## これなに？

Ingress Damage Reportを元に、UPCを列挙したKMLファイルを生成します。

現状、対応しているのは、Macの"Mail"です。

## 仕様

第一引数：メールボックスフォルダ

第二引数：agent名

→Ownerが第二引数と一致するポータルを、標準出力へKML形式で出力（"Google Earth"アプリで開けます。）

例）

```
perl dmg2upc.pl /Users/daisuke/Library/Mail/V2/Mailboxes/Ingress\ Damage\ Report.mbox dk1538 >upc.kml
```


なお、第二引数を省略すると、Ownerに関わらずすべてのポータルを出力します。

## 使い方の例

1. Mailにて、「この Mac 内」に「Ingress Damage Report」というメールボックスを作成

2. Mailの環境設定の「ルール」にて、件名「Ingress Damage Report」で始まるメールを、1で作成したメールボックスへコピーするよう設定

3. Ingress用アカウントの受信フォルダで全メッセージを選択して、メニューから[メッセージ→ルールを適用]を選択

4. このページの右の「Download Zip」からdmg2upcをダウンロード

5. 「ターミナル」アプリを起動して、下記のコマンドを実行

```
cd (ダウンロードしたフォルダ)
perl dmg2upc.pl (メールボックスフォルダ) (agent名) >upc.kml
```

6. Google Earthアプリをダウンロード

7. upc.kmlをダブルクリック

※かなりはしょった説明でごめんなさい。

## ご注意

動作は全く保証しません。

明らかにキャプチャしたことのあるはずのポータルが表示されていない（UPC:276のところ、171箇所認識）ので、イマイチ正確ではないようです。
（Damage Reportメールが来ていないのか、このスクリプトに不具合があるのかは不明。。）

少なくとも、一発でOwner:[Uncaptured]になった場合は、UPCとして認識不可能です。

なお、同様のWebサービスがすでにあるようなのですが、私はGmailの読み込み権限を第三者のサービスに渡すのは無理なので、作ってみました。

