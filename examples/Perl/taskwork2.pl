# Task worker - design 2 in Perl
# Adds pub-sub flow to receive and respond to kill signal

use strict;
use warnings;
use v5.10;

$| = 1; # autoflush stdout after each print

use ZMQ::FFI;
use ZMQ::FFI::Constants qw(ZMQ_PULL ZMQ_PUSH ZMQ_SUB);

use Time::HiRes qw(usleep);
use AnyEvent;
use EV;

my $context = ZMQ::FFI->new();

# Socket to receive messages on
my $receiver = $context->socket(ZMQ_PULL);
$receiver->connect('tcp://localhost:5557');

# Socket to send messages to
my $sender = $context->socket(ZMQ_PUSH);
$sender->connect('tcp://localhost:5558');

# Socket for control input
my $controller = $context->socket(ZMQ_SUB);
$controller->connect('tcp://localhost:5559');
$controller->subscribe('');

# Process messages from either socket

my $receiver_poller = AE::io $receiver->get_fd, 0, sub {
    while ($receiver->has_pollin) {
        my $string = $receiver->recv();

        # Show progress
        say "$string.";

        # Do the work
        usleep $string*1000;

        # Send results to sink
        $sender->send('');
    }
};

my $controller_poller = AE::io $controller->get_fd, 0, sub {
    if ($controller->has_pollin) {
        EV::break;
    }
};

EV::run;
