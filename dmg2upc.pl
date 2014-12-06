#!/usr/bin/perl
use strict;
use warnings;
use Data::Dumper;
use Encode;
use utf8;
use MIME::Base64;
use open ":utf8";
binmode STDIN, ':encoding(utf8)';
binmode STDOUT, ':encoding(utf8)';
binmode STDERR, ':encoding(utf8)';

# kml追加済みポータル名格納配列
my @done_portalnames;

# メールフォルダ毎の処理を再帰的に行う
sub process_recursive {
    my ($dir) = @_;
    opendir my $dh, $dir or die "opendir error";
    while (my $file = readdir $dh) {
        # .で始まるファイル・フォルダは無視
        if( $file =~ /^\./ ) {
            next;
        }
        # ディレクトリなら再帰処理
        if( -d $dir."/".$file ) {
            process_recursive($dir."/".$file);
        }
        # ファイルなら処理
        else {
            # ---------- テキスト読み込み ----------
            my $data = '';
            # emlxで終わるファイルのみ対象
            if( $file =~ /emlx$/ ) {
                # ファイル名を標準エラー出力
                print STDERR "file:".$file.":";
                my $base64mode = 0;
                my $quotedprintablemode = 0;
                my $base64data = '';
                my $notingress = 0;
                my $title = '';
                # ファイルを開く
                chdir($dir);
                open(IN,"< ".$file) or die "cannot open";
                # 行毎読み込み
                while(my $line = <IN>) {
                    # quotedprintableモードなら、=の後の改行を削除して$dataへ追加
                    if( $quotedprintablemode == 1 ) {
                        $line =~ s/=[\r\n]+//;
                        $data = $data.$line;
                    }
                    # base64モードなら、改行削除して$base64dataへ追加
                    elsif( $base64mode == 1 ) {
                        $line =~ s/[\r\n]+//;
                        $base64data = $base64data.$line;
                    }
                    # 件名判定
                    if( $line =~ /^Subject: (Ingress Damage Report.+)/ ) {
                        $title = $1;
                    }
                    elsif( $line =~ /^Subject:(.+) / ) {
                        $notingress = 1;
                        $title = $1;
                        last;
                    }
                    # モードきりかえ
                    if( $line =~ /Content-Transfer-Encoding: base64/ ) {
                        $base64mode = 1;
                        $quotedprintablemode = 0;
                    }
                    elsif( $line =~ /Content-Transfer-Encoding: quoted-printable/ ) {
                        $base64mode = 0;
                        $quotedprintablemode = 1;
                    }
                    elsif( $line =~ /Content-Transfer-Encoding:/ ) {
                        $base64mode = 0;
                        $quotedprintablemode = 0;
                    }
                    elsif( $line =~ /--[0-9a-f]+--/ ) {#終了判定これでいいかどうかはわからないがとりあえず
                        $base64mode = 0;
                        $quotedprintablemode = 0;
                    }
                }
                # 件名がIngress Damage Report〜でないときは次のファイルへ
                if( $notingress == 1 ) {
                    print STDERR $title.":NOTINGRESS\n";
                    next;
                }
                else {
                    print STDERR $title.":INGRESS\nOwner:";
                }
                # =だけエスケープ解除（本当はポータル名のところでやっているエスケープ解除をここでやりたいが文字化けを直せなかった・・・）
                $data =~ s/=3D/=/g;
                #print STDERR $data;
                
                # $dataの後ろにbase64をdecodeして追加
                my $decoded = decode_base64($base64data);
                $decoded = decode('ISO-2022-JP',$decoded);
                $data = $data.$decoded;
                # ファイルを閉じる
                close(IN);
            }
            # ---------- ポータル名抽出 ----------
            my @portalnames;
            while( $data =~ /\"Portal - (.+?)\"/g )
            {
                # =エスケープUTF-8
                my $data_bytes = '';
                my @chs = split(//,$1);
                my $chs_count = @chs;
                for( my $i = 0; $i < $chs_count; $i++ ) {
                    if( $chs[$i] eq "=" ) {
                        $data_bytes = $data_bytes.chr(hex($chs[$i+1].$chs[$i+2]));
                        $i += 2;
                    }
                    else
                    {
                        $data_bytes = $data_bytes.$chs[$i];
                    }
                }
                my $portalname = decode_utf8($data_bytes);
                push(@portalnames,$portalname);
            }
            # ---------- 緯度経度抽出 ----------
            my @lats;
            my @longs;
            # 形式が2種類あったのでどっちも追加（割り切り実装）
            while( $data =~ /intel\?ll=([0-9.]+),([0-9.]+)/g ) {
                push(@lats,$1);
                push(@longs,$2);
            }
            # ---------- オーナー抽出 ----------
            my @owners;
            while( $data =~ /Owner: (\<.+?\>)?(.+?)\<.+?\>/g ) {
                push(@owners,$2);
                print STDERR $2." ";
            }
            print STDERR "\n";
            # ---------- kml出力 ----------
            my $count = @owners;# LINK DESTROYEDの場合、@portalnamesのほうが多くなるので、@ownersの方を数える。割り切りで実装。
            for( my $i = 0; $i < $count; $i++ ) {
                # すでにkml出力済みなら何もしない
                if( grep {$_ eq $portalnames[$i]} @done_portalnames ) {
                    next;
                }
                # 引数2があるときはオーナーが一致する場合のみ出力
                if( @ARGV == 1 or ($owners[$i] eq $ARGV[1]) )
                {
                    # TSV出力ならこんな感じ
                    #print $portalnames[$i]."\t".$lats[$i]."\t".$longs[$i]."\t".$owners[$i]."\n";
                    
                    # kml出力
                    print "<Placemark>\n";
                    print "<name>".$portalnames[$i]."</name>\n";
                    print "<description>".$portalnames[$i]."</description>\n";
                    print "<Point><coordinates>".$longs[$i].",".$lats[$i].",0</coordinates></Point>\n";
                    print "</Placemark>\n";
                    # 登録済み配列追加
                    push(@done_portalnames,$portalnames[$i]);
                }
            }
        }
    }
    closedir $dh;
}

# メイン処理
print "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n".
"<kml xmlns=\"http://earth.google.com/kml/2.2\">\n".
"<Document><Folder><name>UPCs</name>";
process_recursive($ARGV[0]);
print "</Folder></Document></kml>\n";

