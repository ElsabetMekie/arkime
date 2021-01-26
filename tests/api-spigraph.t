use Test::More tests => 71;
use Cwd;
use URI::Escape;
use MolochTest;
use JSON;
use Test::Differences;
use Data::Dumper;
use strict;

my $pwd = "*/pcap";

sub testMulti {
   my ($json, $mjson, $url) = @_;

   my @items = sort({$a->{name} cmp $b->{name}} @{$json->{items}});
   my @mitems = sort({$a->{name} cmp $b->{name}} @{$mjson->{items}});

   eq_or_diff($mjson->{map}, $json->{map}, "single doesn't match multi map for $url", { context => 3 });
   eq_or_diff($mjson->{graph}, $json->{graph}, "single doesn't match multi graph for $url", { context => 3 });
   eq_or_diff(\@mitems, \@items, "single doesn't match multi graph for $url", { context => 3 });

   return $json;
}

sub get {
my ($url) = @_;

    my $json = viewerGet($url);
    my $mjson = multiGet($url);

    $json = testMulti($json, $mjson, $url);

    return $json
}

sub post {
    my ($url, $content) = @_;

    my $json = viewerPost($url, $content);
    my $mjson = multiPost($url, $content);

    $json = testMulti($json, $mjson, $url);

    return $json;
}

esGet("/_refresh");

my ($json, $mjson, $pjson);

#node
    $json = get("/spigraph.json?map=true&date=-1&field=node&expression=" . uri_escape("file=$pwd/bigendian.pcap|file=$pwd/socks-http-example.pcap|file=$pwd/bt-tcp.pcap"));
    $pjson = post("/api/spigraph", '{"map":true, "date":-1, "field":"node", "expression":"file=' . $pwd . '/bigendian.pcap|file=' . $pwd . '/socks-http-example.pcap|file=' . $pwd . '/bt-tcp.pcap"}');
    delete $json->{health}->{_timeStamp};
    delete $pjson->{health}->{_timeStamp};
    eq_or_diff($json, $pjson, "GET and POST versions of spigraph endpoint are not the same");
    eq_or_diff($json->{map}, from_json('{"dst":{"US": 3, "CA": 1}, "src":{"US": 3, "RU":1}, "xffGeo":{}}'), "map field: no");
    eq_or_diff($json->{graph}->{sessionsHisto}, from_json('[["1335956400000", 1], ["1386003600000", 3], [1387742400000, 1], [1482552000000, 1]]'), "sessionsHisto field: node");
    eq_or_diff($json->{graph}->{srcPacketsHisto}, from_json('[["1335956400000", 2], ["1386003600000", 26], [1387742400000, 3], [1482552000000, 3]]'), "srcPacketsHisto field: node");
    eq_or_diff($json->{graph}->{dstPacketsHisto}, from_json('[["1335956400000", 0], ["1386003600000", 20], [1387742400000, 1], [1482552000000, 1]]'), "dstPacketsHisto field: node");
    eq_or_diff($json->{graph}->{srcDataBytesHisto}, from_json('[["1335956400000", 128], ["1386003600000", 486], [1387742400000, 68], [1482552000000, 68]]'), "srcDataBytesHisto field: node");
    eq_or_diff($json->{graph}->{dstDataBytesHisto}, from_json('[["1335956400000", 0], ["1386003600000", 4801], [1387742400000, 0], [1482552000000, 0]]'), "dstDataBytesHisto field: node");
    eq_or_diff($json->{items}, from_json('[{"totDataBytesHisto":5551,"srcDataBytesHisto":750,"dstDataBytesHisto":4801,"name":"test","totBytesHisto":9261,"srcBytesHisto":2968,"dstBytesHisto":6293,"totPacketsHisto":56,"srcPacketsHisto":34,"dstPacketsHisto":22,"count":6,"map":{"xffGeo":{},"dst":{"CA":1,"US":3},"src":{"RU":1,"US":3}},"graph":{"dstBytesHisto":[[1335956400000,0],[1386003600000,6145],[1387742400000,66],[1482552000000,82]],"srcPacketsHisto":[[1335956400000,2],[1386003600000,26],[1387742400000,3],[1482552000000,3]],"xmax":1482552000000,"xmin":1335956400000,"sessionsTotal":6,"totBytesTotal":9261,"totDataBytesTotal":5551,"totPacketsTotal":56,"dstPacketsHisto":[[1335956400000,0],[1386003600000,20],[1387742400000,1],[1482552000000,1]],"srcDataBytesHisto":[[1335956400000,128],[1386003600000,486],[1387742400000,68],[1482552000000,68]],"srcBytesHisto":[[1335956400000,196],[1386003600000,2238],[1387742400000,248],[1482552000000,286]],"dstDataBytesHisto":[[1335956400000,0],[1386003600000,4801],[1387742400000,0],[1482552000000,0]],"interval":3600,"sessionsHisto":[[1335956400000,1],[1386003600000,3],[1387742400000,1],[1482552000000,1]]},"sessionsHisto":6}]'), "items field: node", { context => 3 });
    cmp_ok ($json->{recordsTotal}, '>=', 194);
    cmp_ok ($json->{recordsFiltered}, '==', 6);

#tags
    $json = get("/spigraph.json?map=true&date=-1&field=tags&expression=" . uri_escape("file=$pwd/bigendian.pcap|file=$pwd/socks-http-example.pcap|file=$pwd/bt-tcp.pcap"));
    eq_or_diff($json->{map}, from_json('{"dst":{"US": 3, "CA": 1}, "src":{"US": 3, "RU":1}, "xffGeo":{}}'), "map field: tags");
    eq_or_diff($json->{graph}->{sessionsHisto}, from_json('[["1335956400000", 1], ["1386003600000", 3], [1387742400000, 1], [1482552000000, 1]]'), "sessionsHisto field: tags");
    eq_or_diff($json->{graph}->{srcPacketsHisto}, from_json('[["1335956400000", 2], ["1386003600000", 26], [1387742400000, 3], [1482552000000, 3]]'), "srcPacketsHisto field: tags");
    eq_or_diff($json->{graph}->{dstPacketsHisto}, from_json('[["1335956400000", 0], ["1386003600000", 20], [1387742400000, 1], [1482552000000, 1]]'), "dstPacketsHisto field: tags");
    eq_or_diff($json->{graph}->{srcDataBytesHisto}, from_json('[["1335956400000", 128], ["1386003600000", 486], [1387742400000, 68], [1482552000000, 68]]'), "srcDataBytesHisto field: tags");
    eq_or_diff($json->{graph}->{dstDataBytesHisto}, from_json('[["1335956400000", 0], ["1386003600000", 4801], [1387742400000, 0], [1482552000000, 0]]'), "dstDataBytesHisto field: tags");
    cmp_ok ($json->{recordsTotal}, '>=', 194);
    cmp_ok ($json->{recordsFiltered}, '==', 6);

    my @items = sort({$a->{name} cmp $b->{name}} @{$json->{items}});
    eq_or_diff(\@items, from_json('[{"totDataBytesHisto":5287,"srcDataBytesHisto":486,"dstDataBytesHisto":4801,"name":"byhost2","map":{"xffGeo":{},"src":{"US":3},"dst":{"US":3}},"totBytesHisto":8383,"srcBytesHisto":2238,"dstBytesHisto":6145,"totPacketsHisto":46,"srcPacketsHisto":26,"dstPacketsHisto":20,"count":3,"sessionsHisto":3,"graph":{"dstBytesHisto":[[1386003600000,6145]],"srcBytesHisto":[[1386003600000,2238]],"xmin":1335956400000,"xmax":1482552000000,"sessionsTotal":3,"totBytesTotal":8383,"totDataBytesTotal":5287,"totPacketsTotal":46,"dstPacketsHisto":[[1386003600000,20]],"srcDataBytesHisto":[[1386003600000,486]],"srcPacketsHisto":[[1386003600000,26]],"interval":3600,"dstDataBytesHisto":[[1386003600000,4801]],"sessionsHisto":[[1386003600000,3]]}},{"map":{"src":{},"dst":{},"xffGeo":{}},"totBytesHisto":196,"srcBytesHisto":196,"dstBytesHisto":0,"totPacketsHisto":2,"srcPacketsHisto":2,"dstPacketsHisto":0,"count":1,"sessionsHisto":1,"graph":{"srcBytesHisto":[[1335956400000,196]],"xmax":1482552000000,"sessionsTotal":1,"totBytesTotal":196,"totDataBytesTotal":128,"totPacketsTotal":2,"srcDataBytesHisto":[[1335956400000,128]],"xmin":1335956400000,"dstPacketsHisto":[[1335956400000,0]],"srcPacketsHisto":[[1335956400000,2]],"dstBytesHisto":[[1335956400000,0]],"dstDataBytesHisto":[[1335956400000,0]],"interval":3600,"sessionsHisto":[[1335956400000,1]]},"totDataBytesHisto":128,"srcDataBytesHisto":128,"dstDataBytesHisto":0,"name":"byip2"},{"name":"domainwise","totDataBytesHisto":5287,"srcDataBytesHisto":486,"dstDataBytesHisto":4801,"count":3,"totPacketsHisto":46,"srcPacketsHisto":26,"dstPacketsHisto":20,"totBytesHisto":8383,"srcBytesHisto":2238,"dstBytesHisto":6145,"map":{"dst":{"US":3},"src":{"US":3},"xffGeo":{}},"graph":{"interval":3600,"sessionsHisto":[[1386003600000,3]],"dstDataBytesHisto":[[1386003600000,4801]],"dstBytesHisto":[[1386003600000,6145]],"srcBytesHisto":[[1386003600000,2238]],"srcDataBytesHisto":[[1386003600000,486]],"xmax":1482552000000,"xmin":1335956400000,"sessionsTotal":3,"totBytesTotal":8383,"totDataBytesTotal":5287,"totPacketsTotal":46,"dstPacketsHisto":[[1386003600000,20]],"srcPacketsHisto":[[1386003600000,26]]},"sessionsHisto":3},{"graph":{"dstDataBytesHisto":[[1387742400000,0]],"interval":3600,"sessionsHisto":[[1387742400000,1]],"srcBytesHisto":[[1387742400000,248]],"dstPacketsHisto":[[1387742400000,1]],"xmax":1482552000000,"xmin":1335956400000,"sessionsTotal":1,"totBytesTotal":314,"totDataBytesTotal":68,"totPacketsTotal":4,"srcDataBytesHisto":[[1387742400000,68]],"srcPacketsHisto":[[1387742400000,3]],"dstBytesHisto":[[1387742400000,66]]},"sessionsHisto":1,"totPacketsHisto":4,"srcPacketsHisto":3,"dstPacketsHisto":1,"count":1,"totBytesHisto":314,"srcBytesHisto":248,"dstBytesHisto":66,"map":{"dst":{"CA":1},"src":{"RU":1},"xffGeo":{}},"totDataBytesHisto":68,"srcDataBytesHisto":68,"dstDataBytesHisto":0,"name":"dstip"},{"totDataBytesHisto":5287,"srcDataBytesHisto":486,"dstDataBytesHisto":4801,"name":"hosttaggertest1","map":{"dst":{"US":3},"src":{"US":3},"xffGeo":{}},"count":3,"totPacketsHisto":46,"srcPacketsHisto":26,"dstPacketsHisto":20,"totBytesHisto":8383,"srcBytesHisto":2238,"dstBytesHisto":6145,"sessionsHisto":3,"graph":{"dstBytesHisto":[[1386003600000,6145]],"srcBytesHisto":[[1386003600000,2238]],"srcPacketsHisto":[[1386003600000,26]],"xmax":1482552000000,"sessionsTotal":3,"totBytesTotal":8383,"totDataBytesTotal":5287,"totPacketsTotal":46,"dstPacketsHisto":[[1386003600000,20]],"xmin":1335956400000,"srcDataBytesHisto":[[1386003600000,486]],"interval":3600,"dstDataBytesHisto":[[1386003600000,4801]],"sessionsHisto":[[1386003600000,3]]}},{"graph":{"sessionsHisto":[[1386003600000,3]],"interval":3600,"dstDataBytesHisto":[[1386003600000,4801]],"srcBytesHisto":[[1386003600000,2238]],"xmin":1335956400000,"xmax":1482552000000,"sessionsTotal":3,"totBytesTotal":8383,"totDataBytesTotal":5287,"totPacketsTotal":46,"srcDataBytesHisto":[[1386003600000,486]],"dstPacketsHisto":[[1386003600000,20]],"srcPacketsHisto":[[1386003600000,26]],"dstBytesHisto":[[1386003600000,6145]]},"sessionsHisto":3,"totPacketsHisto":46,"srcPacketsHisto":26,"dstPacketsHisto":20,"count":3,"totBytesHisto":8383,"srcBytesHisto":2238,"dstBytesHisto":6145,"map":{"xffGeo":{},"dst":{"US":3},"src":{"US":3}},"totDataBytesHisto":5287,"srcDataBytesHisto":486,"dstDataBytesHisto":4801,"name":"hosttaggertest2"},{"name":"iptaggertest1","totDataBytesHisto":128,"srcDataBytesHisto":128,"dstDataBytesHisto":0,"map":{"src":{},"dst":{},"xffGeo":{}},"totPacketsHisto":2,"srcPacketsHisto":2,"dstPacketsHisto":0,"count":1,"totBytesHisto":196,"srcBytesHisto":196,"dstBytesHisto":0,"sessionsHisto":1,"graph":{"srcBytesHisto":[[1335956400000,196]],"xmin":1335956400000,"xmax":1482552000000,"sessionsTotal":1,"totBytesTotal":196,"totDataBytesTotal":128,"totPacketsTotal":2,"dstPacketsHisto":[[1335956400000,0]],"srcDataBytesHisto":[[1335956400000,128]],"srcPacketsHisto":[[1335956400000,2]],"dstBytesHisto":[[1335956400000,0]],"dstDataBytesHisto":[[1335956400000,0]],"interval":3600,"sessionsHisto":[[1335956400000,1]]}},{"count":1,"totPacketsHisto":2,"srcPacketsHisto":2,"dstPacketsHisto":0,"totBytesHisto":196,"srcBytesHisto":196,"dstBytesHisto":0,"map":{"xffGeo":{},"src":{},"dst":{}},"graph":{"srcBytesHisto":[[1335956400000,196]],"srcPacketsHisto":[[1335956400000,2]],"srcDataBytesHisto":[[1335956400000,128]],"xmax":1482552000000,"xmin":1335956400000,"sessionsTotal":1,"totBytesTotal":196,"totDataBytesTotal":128,"totPacketsTotal":2,"dstPacketsHisto":[[1335956400000,0]],"dstBytesHisto":[[1335956400000,0]],"dstDataBytesHisto":[[1335956400000,0]],"interval":3600,"sessionsHisto":[[1335956400000,1]]},"sessionsHisto":1,"name":"iptaggertest2","totDataBytesHisto":128,"srcDataBytesHisto":128,"dstDataBytesHisto":0},{"totDataBytesHisto":128,"srcDataBytesHisto":128,"dstDataBytesHisto":0,"name":"ipwise","totPacketsHisto":2,"srcPacketsHisto":2,"dstPacketsHisto":0,"count":1,"totBytesHisto":196,"srcBytesHisto":196,"dstBytesHisto":0,"map":{"xffGeo":{},"src":{},"dst":{}},"graph":{"srcBytesHisto":[[1335956400000,196]],"xmax":1482552000000,"sessionsTotal":1,"totBytesTotal":196,"totDataBytesTotal":128,"totPacketsTotal":2,"dstPacketsHisto":[[1335956400000,0]],"xmin":1335956400000,"srcDataBytesHisto":[[1335956400000,128]],"srcPacketsHisto":[[1335956400000,2]],"dstBytesHisto":[[1335956400000,0]],"dstDataBytesHisto":[[1335956400000,0]],"interval":3600,"sessionsHisto":[[1335956400000,1]]},"sessionsHisto":1},{"totDataBytesHisto":68,"srcDataBytesHisto":68,"dstDataBytesHisto":0,"name":"ipwisecsv","graph":{"dstBytesHisto":[[1387742400000,66]],"srcPacketsHisto":[[1387742400000,3]],"xmin":1335956400000,"xmax":1482552000000,"sessionsTotal":1,"totBytesTotal":314,"totDataBytesTotal":68,"totPacketsTotal":4,"dstPacketsHisto":[[1387742400000,1]],"srcDataBytesHisto":[[1387742400000,68]],"srcBytesHisto":[[1387742400000,248]],"dstDataBytesHisto":[[1387742400000,0]],"interval":3600,"sessionsHisto":[[1387742400000,1]]},"sessionsHisto":1,"totPacketsHisto":4,"srcPacketsHisto":3,"dstPacketsHisto":1,"count":1,"totBytesHisto":314,"srcBytesHisto":248,"dstBytesHisto":66,"map":{"xffGeo":{},"src":{"RU":1},"dst":{"CA":1}}},{"sessionsHisto":1,"graph":{"dstDataBytesHisto":[[1387742400000,0]],"interval":3600,"sessionsHisto":[[1387742400000,1]],"xmin":1335956400000,"xmax":1482552000000,"sessionsTotal":1,"totBytesTotal":314,"totDataBytesTotal":68,"totPacketsTotal":4,"dstPacketsHisto":[[1387742400000,1]],"srcDataBytesHisto":[[1387742400000,68]],"srcPacketsHisto":[[1387742400000,3]],"srcBytesHisto":[[1387742400000,248]],"dstBytesHisto":[[1387742400000,66]]},"map":{"xffGeo":{},"dst":{"CA":1},"src":{"RU":1}},"count":1,"totPacketsHisto":4,"srcPacketsHisto":3,"dstPacketsHisto":1,"totBytesHisto":314,"srcBytesHisto":248,"dstBytesHisto":66,"totDataBytesHisto":68,"srcDataBytesHisto":68,"dstDataBytesHisto":0,"name":"srcip"},{"map":{"xffGeo":{},"src":{"US":3},"dst":{"US":3}},"totPacketsHisto":46,"srcPacketsHisto":26,"dstPacketsHisto":20,"count":3,"totBytesHisto":8383,"srcBytesHisto":2238,"dstBytesHisto":6145,"sessionsHisto":3,"graph":{"dstBytesHisto":[[1386003600000,6145]],"srcPacketsHisto":[[1386003600000,26]],"xmax":1482552000000,"dstPacketsHisto":[[1386003600000,20]],"xmin":1335956400000,"sessionsTotal":3,"totBytesTotal":8383,"totDataBytesTotal":5287,"totPacketsTotal":46,"srcDataBytesHisto":[[1386003600000,486]],"srcBytesHisto":[[1386003600000,2238]],"sessionsHisto":[[1386003600000,3]],"interval":3600,"dstDataBytesHisto":[[1386003600000,4801]]},"totDataBytesHisto":5287,"srcDataBytesHisto":486,"dstDataBytesHisto":4801,"name":"wisebyhost2"},{"sessionsHisto":1,"graph":{"interval":3600,"sessionsHisto":[[1335956400000,1]],"dstDataBytesHisto":[[1335956400000,0]],"srcBytesHisto":[[1335956400000,196]],"xmax":1482552000000,"srcDataBytesHisto":[[1335956400000,128]],"xmin":1335956400000,"sessionsTotal":1,"totBytesTotal":196,"totDataBytesTotal":128,"totPacketsTotal":2,"dstPacketsHisto":[[1335956400000,0]],"srcPacketsHisto":[[1335956400000,2]],"dstBytesHisto":[[1335956400000,0]]},"map":{"src":{},"dst":{},"xffGeo":{}},"totBytesHisto":196,"srcBytesHisto":196,"dstBytesHisto":0,"count":1,"totPacketsHisto":2,"srcPacketsHisto":2,"dstPacketsHisto":0,"name":"wisebyip2","totDataBytesHisto":128,"srcDataBytesHisto":128,"dstDataBytesHisto":0}]'), "items field: tags", { context => 3 });

#srcIp
    $json = get("/spigraph.json?map=true&date=-1&field=srcIp&expression=" . uri_escape("file=$pwd/bigendian.pcap|file=$pwd/socks-http-example.pcap|file=$pwd/bt-tcp.pcap"));
    eq_or_diff($json->{map}, from_json('{"dst":{"US": 3, "CA": 1}, "src":{"US": 3, "RU":1}, "xffGeo":{}}'), "map field: srcIp");
    eq_or_diff($json->{graph}->{sessionsHisto}, from_json('[["1335956400000", 1], ["1386003600000", 3], [1387742400000, 1], [1482552000000, 1]]'), "sessionsHisto field: srcIp");
    eq_or_diff($json->{graph}->{srcPacketsHisto}, from_json('[["1335956400000", 2], ["1386003600000", 26], [1387742400000, 3], [1482552000000, 3]]'), "srcPacketsHisto field: srcIp");
    eq_or_diff($json->{graph}->{dstPacketsHisto}, from_json('[["1335956400000", 0], ["1386003600000", 20], [1387742400000, 1], [1482552000000, 1]]'), "dstPacketsHisto field: srcIp");
    eq_or_diff($json->{graph}->{srcDataBytesHisto}, from_json('[["1335956400000", 128], ["1386003600000", 486], [1387742400000, 68], [1482552000000, 68]]'), "srcDataBytesHisto field: srcIp");
    eq_or_diff($json->{graph}->{dstDataBytesHisto}, from_json('[["1335956400000", 0], ["1386003600000", 4801], [1387742400000, 0], [1482552000000, 0]]'), "dstDataBytesHisto field: srcIp");
    my @items = sort({$a->{name} cmp $b->{name}} @{$json->{items}});
    eq_or_diff(\@items, from_json('[{"graph":{"dstBytesHisto":[[1387742400000,66]],"xmin":1335956400000,"dstDataBytesHisto":[[1387742400000,0]],"interval":3600,"srcDataBytesHisto":[[1387742400000,68]],"xmax":1482552000000,"sessionsTotal":1,"totBytesTotal":314,"totDataBytesTotal":68,"totPacketsTotal":4,"dstPacketsHisto":[[1387742400000,1]],"sessionsHisto":[[1387742400000,1]],"srcPacketsHisto":[[1387742400000,3]],"srcBytesHisto":[[1387742400000,248]]},"totDataBytesHisto":68,"srcDataBytesHisto":68,"dstDataBytesHisto":0,"name":"10.0.0.1","totPacketsHisto":4,"srcPacketsHisto":3,"dstPacketsHisto":1,"totBytesHisto":314,"srcBytesHisto":248,"dstBytesHisto":66,"count":1,"map":{"dst":{"CA":1},"xffGeo":{},"src":{"RU":1}},"sessionsHisto":1},{"graph":{"srcBytesHisto":[[1482552000000,286]],"sessionsHisto":[[1482552000000,1]],"srcPacketsHisto":[[1482552000000,3]],"dstPacketsHisto":[[1482552000000,1]],"xmax":1482552000000,"srcDataBytesHisto":[[1482552000000,68]],"interval":3600,"xmin":1335956400000,"sessionsTotal":1,"totBytesTotal":368,"totDataBytesTotal":68,"totPacketsTotal":4,"dstDataBytesHisto":[[1482552000000,0]],"dstBytesHisto":[[1482552000000,82]]},"count":1,"totBytesHisto":368,"srcBytesHisto":286,"dstBytesHisto":82,"totPacketsHisto":4,"srcPacketsHisto":3,"dstPacketsHisto":1,"totDataBytesHisto":68,"srcDataBytesHisto":68,"dstDataBytesHisto":0,"name":"10.10.10.10","sessionsHisto":1,"map":{"xffGeo":{},"src":{},"dst":{}}},{"sessionsHisto":3,"map":{"dst":{"US":3},"src":{"US":3},"xffGeo":{}},"graph":{"interval":3600,"dstDataBytesHisto":[[1386003600000,4801]],"xmin":1335956400000,"sessionsTotal":3,"totBytesTotal":8383,"totDataBytesTotal":5287,"totPacketsTotal":46,"dstBytesHisto":[[1386003600000,6145]],"xmax":1482552000000,"dstPacketsHisto":[[1386003600000,20]],"srcPacketsHisto":[[1386003600000,26]],"sessionsHisto":[[1386003600000,3]],"srcBytesHisto":[[1386003600000,2238]],"srcDataBytesHisto":[[1386003600000,486]]},"count":3,"totPacketsHisto":46,"srcPacketsHisto":26,"dstPacketsHisto":20,"totBytesHisto":8383,"srcBytesHisto":2238,"dstBytesHisto":6145,"totDataBytesHisto":5287,"srcDataBytesHisto":486,"dstDataBytesHisto":4801,"name":"10.180.156.185"},{"graph":{"interval":3600,"dstBytesHisto":[[1335956400000,0]],"xmin":1335956400000,"dstDataBytesHisto":[[1335956400000,0]],"srcPacketsHisto":[[1335956400000,2]],"srcBytesHisto":[[1335956400000,196]],"sessionsHisto":[[1335956400000,1]],"dstPacketsHisto":[[1335956400000,0]],"xmax":1482552000000,"sessionsTotal":1,"totBytesTotal":196,"totDataBytesTotal":128,"totPacketsTotal":2,"srcDataBytesHisto":[[1335956400000,128]]},"count":1,"name":"192.168.177.160","totDataBytesHisto":128,"srcDataBytesHisto":128,"dstDataBytesHisto":0,"totPacketsHisto":2,"srcPacketsHisto":2,"dstPacketsHisto":0,"totBytesHisto":196,"srcBytesHisto":196,"dstBytesHisto":0,"sessionsHisto":1,"map":{"src":{},"xffGeo":{},"dst":{}}}]'), "items field: srcIp", { context => 3 });
    cmp_ok ($json->{recordsTotal}, '>=', 194);
    cmp_ok ($json->{recordsFiltered}, '==', 6);

#http.requestHeader
    # $json = get("/spigraph.json?map=true&date=-1&field=http.requestHeader&expression=" . uri_escape("file=$pwd/bigendian.pcap|file=$pwd/socks-http-example.pcap|file=$pwd/bt-tcp.pcap"));
    $json = post("/api/spigraph", '{"map":true, "date":-1, "field":"http.requestHeader", "expression":"file=' . $pwd . '/bigendian.pcap|file=' . $pwd . '/socks-http-example.pcap|file=' . $pwd . '/bt-tcp.pcap"}');
    eq_or_diff($json->{map}, from_json('{"dst":{"US": 3, "CA": 1}, "src":{"US": 3, "RU":1}, "xffGeo":{}}'), "map field: http.requestHeader");
    eq_or_diff($json->{graph}->{sessionsHisto}, from_json('[["1335956400000", 1], ["1386003600000", 3], [1387742400000, 1], [1482552000000, 1]]'), "sessionsHisto field: h1");
    eq_or_diff($json->{graph}->{srcPacketsHisto}, from_json('[["1335956400000", 2], ["1386003600000", 26], [1387742400000, 3], [1482552000000, 3]]'), "srcPacketsHisto field: h1");
    eq_or_diff($json->{graph}->{dstPacketsHisto}, from_json('[["1335956400000", 0], ["1386003600000", 20], [1387742400000, 1], [1482552000000, 1]]'), "dstPacketsHisto field: h1");
    eq_or_diff($json->{graph}->{srcDataBytesHisto}, from_json('[["1335956400000", 128], ["1386003600000", 486], [1387742400000, 68], [1482552000000, 68]]'), "srcDataBytesHisto field: h1");
    eq_or_diff($json->{graph}->{dstDataBytesHisto}, from_json('[["1335956400000", 0], ["1386003600000", 4801], [1387742400000, 0], [1482552000000, 0]]'), "dstDataBytesHisto field: h1");
    my @items = sort({$a->{name} cmp $b->{name}} @{$json->{items}});
    eq_or_diff(\@items, from_json('[{"graph":{"dstBytesHisto":[[1386003600000,6145]],"xmin":1335956400000,"sessionsTotal":3,"totBytesTotal":8383,"totDataBytesTotal":5287,"totPacketsTotal":46,"dstDataBytesHisto":[[1386003600000,4801]],"interval":3600,"srcDataBytesHisto":[[1386003600000,486]],"xmax":1482552000000,"dstPacketsHisto":[[1386003600000,20]],"sessionsHisto":[[1386003600000,3]],"srcPacketsHisto":[[1386003600000,26]],"srcBytesHisto":[[1386003600000,2238]]},"name":"accept","totDataBytesHisto":5287,"srcDataBytesHisto":486,"dstDataBytesHisto":4801,"totPacketsHisto":46,"srcPacketsHisto":26,"dstPacketsHisto":20,"totBytesHisto":8383,"srcBytesHisto":2238,"dstBytesHisto":6145,"count":3,"map":{"dst":{"US":3},"src":{"US":3},"xffGeo":{}},"sessionsHisto":3},{"sessionsHisto":3,"map":{"dst":{"US":3},"src":{"US":3},"xffGeo":{}},"graph":{"dstBytesHisto":[[1386003600000,6145]],"dstDataBytesHisto":[[1386003600000,4801]],"xmin":1335956400000,"sessionsTotal":3,"totBytesTotal":8383,"totDataBytesTotal":5287,"totPacketsTotal":46,"interval":3600,"srcDataBytesHisto":[[1386003600000,486]],"srcBytesHisto":[[1386003600000,2238]],"sessionsHisto":[[1386003600000,3]],"srcPacketsHisto":[[1386003600000,26]],"dstPacketsHisto":[[1386003600000,20]],"xmax":1482552000000},"count":3,"name":"host","totDataBytesHisto":5287,"srcDataBytesHisto":486,"dstDataBytesHisto":4801,"totBytesHisto":8383,"srcBytesHisto":2238,"dstBytesHisto":6145,"totPacketsHisto":46,"srcPacketsHisto":26,"dstPacketsHisto":20},{"totPacketsHisto":46,"srcPacketsHisto":26,"dstPacketsHisto":20,"totBytesHisto":8383,"srcBytesHisto":2238,"dstBytesHisto":6145,"name":"user-agent","totDataBytesHisto":5287,"srcDataBytesHisto":486,"dstDataBytesHisto":4801,"count":3,"graph":{"srcDataBytesHisto":[[1386003600000,486]],"xmax":1482552000000,"dstPacketsHisto":[[1386003600000,20]],"sessionsHisto":[[1386003600000,3]],"srcPacketsHisto":[[1386003600000,26]],"srcBytesHisto":[[1386003600000,2238]],"xmin":1335956400000,"sessionsTotal":3,"totBytesTotal":8383,"totDataBytesTotal":5287,"totPacketsTotal":46,"dstDataBytesHisto":[[1386003600000,4801]],"dstBytesHisto":[[1386003600000,6145]],"interval":3600},"map":{"src":{"US":3},"xffGeo":{},"dst":{"US":3}},"sessionsHisto":3}]'), "items field: http.requestHeader", { context => 3 });
cmp_ok ($json->{recordsTotal}, '>=', 194);
cmp_ok ($json->{recordsFiltered}, '==', 6);

#http.useragent
    $json = get("/spigraph.json?map=true&date=-1&field=http.useragent&expression=" . uri_escape("file=$pwd/socks5-reverse.pcap|file=$pwd/socks-http-example.pcap|file=$pwd/bt-tcp.pcap"));
    my @items = sort({$a->{name} cmp $b->{name}} @{$json->{items}});
    eq_or_diff(\@items, from_json('[{"totBytesHisto":27311,"srcBytesHisto":25112,"dstBytesHisto":2199,"totDataBytesHisto":24346,"srcDataBytesHisto":23392,"dstDataBytesHisto":954,"totPacketsHisto":52,"srcPacketsHisto":31,"dstPacketsHisto":21,"count":1,"graph":{"srcDataBytesHisto":[[1386788400000,23392]],"srcBytesHisto":[[1386788400000,25112]],"srcPacketsHisto":[[1386788400000,31]],"interval":3600,"sessionsHisto":[[1386788400000,1]],"xmin":1386003600000,"sessionsTotal":1,"totBytesTotal":27311,"totDataBytesTotal":24346,"totPacketsTotal":52,"dstDataBytesHisto":[[1386788400000,954]],"dstPacketsHisto":[[1386788400000,21]],"xmax":1482552000000,"dstBytesHisto":[[1386788400000,2199]]},"map":{"dst":{"CA":1},"src":{"RU":1},"xffGeo":{}},"name":"Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1; SV1; .NET CLR 1.1.4322)","sessionsHisto":1},{"totBytesHisto":8383,"srcBytesHisto":2238,"dstBytesHisto":6145,"totDataBytesHisto":5287,"srcDataBytesHisto":486,"dstDataBytesHisto":4801,"totPacketsHisto":46,"srcPacketsHisto":26,"dstPacketsHisto":20,"count":3,"graph":{"dstBytesHisto":[[1386003600000,6145]],"xmin":1386003600000,"sessionsTotal":3,"totBytesTotal":8383,"totDataBytesTotal":5287,"totPacketsTotal":46,"dstDataBytesHisto":[[1386003600000,4801]],"xmax":1482552000000,"dstPacketsHisto":[[1386003600000,20]],"sessionsHisto":[[1386003600000,3]],"interval":3600,"srcDataBytesHisto":[[1386003600000,486]],"srcBytesHisto":[[1386003600000,2238]],"srcPacketsHisto":[[1386003600000,26]]},"map":{"src":{"US":3},"xffGeo":{},"dst":{"US":3}},"sessionsHisto":3,"name":"curl/7.24.0 (x86_64-apple-darwin12.0) libcurl/7.24.0 OpenSSL/0.9.8y zlib/1.2.5"}]'), "items field: http.useragent", { context => 3 });
    eq_or_diff($json->{graph}->{sessionsHisto}, from_json('[["1386003600000", 3], ["1386788400000", 1], [1387742400000, 1], [1482552000000, 1]]'), "multi sessionsHisto field: http.useragent");
    eq_or_diff($json->{graph}->{srcPacketsHisto}, from_json('[["1386003600000", 26], ["1386788400000", 31], [1387742400000, 3], [1482552000000, 3]]'), "multi srcPacketsHisto field: http.useragent");
    eq_or_diff($json->{graph}->{dstPacketsHisto}, from_json('[["1386003600000", 20], ["1386788400000", 21], [1387742400000, 1], [1482552000000, 1]]'), "multi dstPacketsHisto field: http.useragent");
    eq_or_diff($json->{graph}->{srcDataBytesHisto}, from_json('[["1386003600000", 486], ["1386788400000", 23392], [1387742400000, 68], [1482552000000, 68]]'), "multi srcDataBytesHisto field: http.useragent");
    eq_or_diff($json->{graph}->{dstDataBytesHisto}, from_json('[["1386003600000", 4801], ["1386788400000", 954], [1387742400000, 0], [1482552000000, 0]]'), "multi dstDataBytesHisto field: http.useragent");
    cmp_ok ($json->{recordsTotal}, '>=', 194);
    cmp_ok ($json->{recordsFiltered}, '==', 6);

# no map data
    $json = get("/spigraph.json?date=-1&field=http.useragent&expression=" . uri_escape("file=$pwd/socks5-reverse.pcap|file=$pwd/socks-http-example.pcap|file=$pwd/bt-tcp.pcap"));
    eq_or_diff($json->{map}, from_json('{}'), "no map data");

# file field works
    $json = post("/spigraph.json?date=-1&field=fileand&expression=" . uri_escape("file=$pwd/bigendian.pcap|file=$pwd/socks-http-example.pcap|file=$pwd/bt-tcp.pcap"));
    cmp_ok ($json->{recordsFiltered}, '==', 6);
