package Fotbal::Utils::Sqlib;

use strict;
use warnings;

use base 'Exporter';
our @EXPORT_OK = qw(
  make_stats_sql
);
our %EXPORT_TAGS = ( all => \@EXPORT_OK );

sub make_stats_sql {
  my $host = shift;
  my $sql_part = "on t.id = g.team_id_2";
  $sql_part = "on t.id = g.team_id_1"
    if $host;
 
  my $sql = "SELECT * FROM teams t
    join games g
    $sql_part
    join score s 
    ON s.id = g.id;";

  return $sql;
}
1;