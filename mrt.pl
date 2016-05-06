#!/usr/bin/perl
#
# MSMT RRD grapher by R.Bruna
#
# Description:
#
# Dumps network device interface octet counters via SNMP,
# creates round-robin database and plot graph into image.
#
# TODO:
#
# -packet count
# -web inteface + input
# -read from txt database array
#
# ifInOctets 1.3.6.1.2.1.2.2.1.10.ifindex (32bit)
# ifOutOctets 1.3.6.1.2.1.2.2.1.16.ifindex (32bit)
# ifInUcastPkts 1.3.6.1.2.1.2.2.1.11.ifindex
# ifInUcastPkts 1.3.6.1.2.1.2.2.1.17.ifindex
#

use strict;
use warnings;
use RRDs;
use Net::SNMP;

my $target='10.3.200.15';
my $store="database";
my $oid= [ '1.3.6.1.2.1.2.2.1.10.98','1.3.6.1.2.1.2.2.1.16.98'];
my $start = time;

#chdir
chdir "/var/www/mrtg";

# Create the RRD database for day/week/month/year for min/max/avg values
if ( not -f "$store/$target.rrd" ){
	RRDs::create("$store/$target.rrd", "--start",$start-1,
	"DS:in:COUNTER:600:U:U",
	"DS:out:COUNTER:600:U:U",
	"RRA:AVERAGE:0.5:1:288",
	"RRA:AVERAGE:0.5:3:672",
	"RRA:AVERAGE:0.5:12:744",
	"RRA:AVERAGE:0.5:72:1480",
	"RRA:MIN:0.5:1:288",
	"RRA:MIN:0.5:3:672",
	"RRA:MIN:0.5:12:744",
	"RRA:MIN:0.5:72:1480",
	"RRA:MAX:0.5:1:288",
	"RRA:MAX:0.5:3:672",
	"RRA:MAX:0.5:12:744",
	"RRA:MAX:0.5:72:1480",
	);
};

#open SNMP session
my ($session, $error) = Net::SNMP->session(
	hostname => $target,
	version => 1,
	community => 'kuk',
	);

if ( ! defined $session ) {
	print $error;
	exit 1;
}

#get OID hash
my $res = $session->get_request( varbindlist => $oid );

if( ! defined $res ) {
	print $session->error,"\n";
	$session->close();
	exit 1;
}

# Update the database
RRDs::update "$store/$target.rrd","$start:$res->{$oid->[0]}:$res->{$oid->[1]}";

#Plot the RRD graph
RRDs::graph ( "$store/$target.png",
	"--title", "$target port Te5/1",
	"--start", "now-1d",
	"--end", "now",
	"--imgformat","PNG",
	"--width=600",
	"--height=150",
	"--step=60",
	"DEF:inmax=$store/$target.rrd:in:MAX",
	"DEF:inavg=$store/$target.rrd:in:AVERAGE",
	"DEF:outmax=$store/$target.rrd:out:MAX",
	"DEF:outavg=$store/$target.rrd:out:AVERAGE",
	"CDEF:inbpsmax=inmax,8,*",
	"CDEF:inbpsavg=inavg,8,*",
	"CDEF:outbpsmax=outmax,8,*",
	"CDEF:outbpsavg=outavg,8,*",
	"AREA:inbpsavg#ccefcc:Average In (bps)",
	"LINE1:inbpsmax#006400: MAx In (bps)",
	"LINE2:outbpsavg#7f7fff: Average Out (bps)",
	"LINE1:inbpsmax#0000ff: MAx Out (bps)",
	"COMMENT:\\s", "COMMENT:\\s",
	"COMMENT:\\s", "COMMENT:\\s",
	"COMMENT:\\t\\t\\t\\t\\tMax.\\t\\t    Avg.\\t\\t Current\\l",
	"COMMENT:     Incoming traffic",
	"GPRINT:inbpsmax:MAX:%8.1lf %sbps",
	"GPRINT:inbpsavg:AVERAGE:%8.1lf %sbps",
	"GPRINT:inbpsmax:LAST:%8.1lf %sbps\\n",
	"COMMENT:     Outgoing traffic",
	"GPRINT:outbpsmax:MAX:%8.1lf %sbps",
	"GPRINT:outbpsavg:AVERAGE:%8.1lf %sbps",
	"GPRINT:outbpsmax:LAST:%8.1lf %sbps\\n",
	"COMMENT:\\s", "COMMENT:\\s",
);

#error catch all

my $err = RRDs::error;
if ($err) { print "$err\n"; }

#exit

exit 0;

