use feature ':5.10';
no warnings 'utf8';

use JSON;
use Encode;
use Selenium::Remote::Driver;
use Mojo::UserAgent;
my $ua = Mojo::UserAgent->new;
$ua->transactor->name("Mozilla/5.0 (Windows NT 6.1; rv:51.0) Gecko/20100101 Firefox/51.0");
$ua->inactivity_timeout(30);
$ua->connect_timeout(30);
$ua->request_timeout(0);    #下载整个网页所用最大时间
$ua->max_connections(0);
$ua->max_redirects(7);
$n              = 0;
$remoteURL      = '';
@video_url_list = ();
open a, '>', ".\\busy.txt" or die "Error:$!\n";
system("start phantomjs --ignore-ssl-errors=true --webdriver=4444");
sleep 3;
$driver = Selenium::Remote::Driver->new( "browser_name" => "phantomjs" );

$script1 = <<'END_MESSAGE';
function crc32(t)  {
    var e = document.createElement("a");
    e.href = t;
    var n = function() {
        for (var t = 0,e = new Array(256),n = 0; 256 != n; ++n) t = n,
                t = 1 & t ? -306674912 ^ t >>> 1 : t >>> 1,
                t = 1 & t ? -306674912 ^ t >>> 1 : t >>> 1,
                t = 1 & t ? -306674912 ^ t >>> 1 : t >>> 1,
                t = 1 & t ? -306674912 ^ t >>> 1 : t >>> 1,
                t = 1 & t ? -306674912 ^ t >>> 1 : t >>> 1,
                t = 1 & t ? -306674912 ^ t >>> 1 : t >>> 1,
                t = 1 & t ? -306674912 ^ t >>> 1 : t >>> 1,
                t = 1 & t ? -306674912 ^ t >>> 1 : t >>> 1,
                e[n] = t;
        return "undefined" != typeof Int32Array ? new Int32Array(e) : e}(),
        o = function(t) {
        for (var e,o,r = -1,i = 0,a = t.length; i < a;) e = t.charCodeAt(i++),
                e < 128 ? r = r >>> 8 ^ n[255 & (r ^ e)] : e < 2048 ? (r = r >>> 8 ^ n[255 & (r ^ (192 | e >> 6 & 31))],
                r = r >>> 8 ^ n[255 & (r ^ (128 | 63 & e))]) : e >= 55296 && e < 57344 ? (e = (1023 & e) + 64,
                o = 1023 & t.charCodeAt(i++),
                r = r >>> 8 ^ n[255 & (r ^ (240 | e >> 8 & 7))],
                r = r >>> 8 ^ n[255 & (r ^ (128 | e >> 2 & 63))],
                r = r >>> 8 ^ n[255 & (r ^ (128 | o >> 6 & 15 | (3 & e) << 4))],
                r = r >>> 8 ^ n[255 & (r ^ (128 | 63 & o))]) : (r = r >>> 8 ^ n[255 & (r ^ (224 | e >> 12 & 15))],
                r = r >>> 8 ^ n[255 & (r ^ (128 | e >> 6 & 63))],
                r = r >>> 8 ^ n[255 & (r ^ (128 | 63 & e))]);
        return r ^ -1},
        r = e.pathname + "?r=" + Math.random().toString(10).substring(2);
    "/" != r[0] && (r = "/" + r);
    var i = o(r) >>> 0,
        a = location.protocol.indexOf("http") > -1;
    return (a ? [ location.protocol, e.hostname ] : [ "http:", e.hostname ]).join("//") + r + "&s=" + i};
	
	
var txt=crc32("
END_MESSAGE

$script2 = <<'END_MESSAGE';
");

document.write(txt);
END_MESSAGE

chomp($script1);
open b, '<', "urllist_mobile.txt" or die "Error:$!\n";
while (<b>) {
    my $i = $_;
    chomp($i);
    $i =~ m/^([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)$/m;
    my $url2 = $2;

    #say $url2 if $i =~ m/\t1$/m;
    push( @video_url_list, $url2 ) if $i =~ m/\t1$/m;
}
close b;
foreach $i (@video_url_list) {
    say $i;
    $i =~ /(\d{6,})/;
    my $id1 = $1;
    if ( -e $id1 . ".mp4" ) {
        say $id1 . ".mp4\t   跳过\n";
        NEXT;
    }
    else {
        get_video_page($i);
    }
}
system("pause");

sub get_video_js {
    my $url      = shift;
    my $tx       = $ua->get($url);
    my $response = $tx->result->body;
    $response =~ m/remoteURL:"(.+?)"/;
    $remoteURL = $1;
    return;
}

sub get_video_page {
    my $url = shift;
    $url =~ /(\d{6,})/;
    local $id = $1;
    $url = 'https://www.365yg.com/a' . $id;
    my $tx       = $ua->get($url);
    my $response = $tx->result->body;
    if ( $response =~ m/src="(.+?tt-video.js)"/ ) {
        $url_video_js = 'http:' . $1;
        if ( $n == 0 ) {
            get_video_js($url_video_js);
        }
    }
    my $videoid;
    if ( $response =~ m/videoid:'(.+?)'/ ) {
        $videoid = $1;
        $driver->get('http://example.com/');
        $script = $script1 . $remoteURL . $videoid . $script2;
        $driver->execute_script($script);
        my $video_url1 = Encode::encode( 'gbk', $driver->get_body() );
        say $video_url1;
        get_video($video_url1);
        $n++;
    }
    else {
        say "server is none" . "\t" . 'https://www.toutiao.com/a' . $id . '/?iid=0&app=news_article';
        say a "server is none" . "\t" . 'https://www.toutiao.com/a' . $id . '/?iid=0&app=news_article';
        return;
    }
}

sub get_video {
    $url = shift;
    my $tx                    = $ua->get($url);
    my $response              = $tx->result->body;
    my $perl_hash_or_arrayref = decode_json $response ;
    if ( "server is busy" eq $perl_hash_or_arrayref->{"message"} ) {
        say "server is busy" . "\t" . $id;
        say a "server is busy" . "\t" . $id;
        return;
    }
    say $video_url2= $perl_hash_or_arrayref->{"data"}->{"video_list"}->{"video_3"}->{"main_url"};
    if ( $video_url2 eq "" ) {
        say "video_3=0";
        say $video_url2= $perl_hash_or_arrayref->{"data"}->{"video_list"}->{"video_2"}->{"main_url"};
        if ( $video_url2 eq "" ) {
            say "video_2=0";
            say $video_url2= $perl_hash_or_arrayref->{"data"}->{"video_list"}->{"video_1"}->{"main_url"};
        }
    }
    use MIME::Base64;
    sleep 1;
    say $video_url3= decode_base64($video_url2);
    my $url = $video_url3;
    my $tx = $ua->build_tx( GET => $url );
    $| = 1;
    $tx->res->content->on(
        read => sub {
            my $content = shift;
            my $len     = $content->headers->content_length;
            my $size    = $content->progress;
            print "\r\[" . ( "-" x int( ( $size / $len ) * 50 ) ) . ( " " x ( 50 - int( ( $size / $len ) * 50 ) ) ) . "\]";
            printf( "%2.1f %%  %2.1f/%2.1fMB", $size / $len * 100, $size / 1024 / 1024, $len / 1024 / 1024 );
        }
    );
    sleep 2;    #速度太快会无法下载
    $ua->start($tx);
    $| = 0;
    say "";
    my $size           = $tx->res->content->asset->size;
    my $head           = $tx->result->headers->to_string;
    my $content_length = "";
    if ( $head =~ m/content-length: ([^\r\n]*)/is ) {
        $content_length = $1;
    }
    if ( ( $size == $content_length ) ) {
        if ( $tx->res->code eq "200" ) {
            $tx->res->content->asset->move_to( $id . ".mp4" );
        }
    }
    else {
        say $id. "\t未下载完整";
    }
}
$driver->quit();
`TASKKILL /IM  phantomjs.exe /F`;
close a;
system("pause");

