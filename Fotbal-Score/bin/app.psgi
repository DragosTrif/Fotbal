#!/usr/bin/env perl

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";

use Fotbal::Score;
Fotbal::Score->to_app;
