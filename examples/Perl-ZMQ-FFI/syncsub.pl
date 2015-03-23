# Synchronized subscriber in Perl

use strict;
use warnings;
use v5.10;

use ZMQ::FFI;
use ZMQ::FFI::Constants qw(ZMQ_SUB ZMQ_REQ);

my $context = ZMQ::FFI->new();

# First, connect our subscriber socket
my $subscriber = $context->socket(ZMQ_SUB);
$subscriber->connect('tcp://localhost:5561');
$subscriber->subscribe('');

# 0MQ is so fast, we need to wait a while...
sleep 1;

# Second, synchronize start with publisher
my $syncclient = $context->socket(ZMQ_REQ);
$syncclient->connect('tcp://localhost:5562');

# send a synchronization request
$syncclient->send('');

# wait for synchronization reply
$syncclient->recv();

# Third, get our updates and report how many we got
my $update_nbr = 0;
while (1) {
    last if $subscriber->recv() eq "END";
    $update_nbr++;
}

say "Received $update_nbr updates";

# Finally, synchronize done with publisher

# send done message
$syncclient->send('');

# wait for done acknowledgment
$syncclient->recv();
