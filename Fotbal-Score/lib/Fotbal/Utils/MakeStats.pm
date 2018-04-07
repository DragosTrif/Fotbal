package Fotbal::Utils::MakeStats;

use Moo;
use MooX::late;

has data      => ( is => 'ro', isa => 'ArrayRef', required => 1 );
has team_type => ( is => 'ro', isa => 'Str',      required => 1 );

sub get_victory {
  my $self = shift;

  my $results = [];

  my $config = {
    hosts => {
      marked  => "goals_team_1",
      recived => "goals_team_2",
    },
    visitors => {
      marked  => "goals_team_2",
      recived => "goals_team_1",
      }

    };

  my $marked = $config->{ $self->team_type() }->{marked};
  my $recived = $config->{ $self->team_type() }->{recived};
  my $data         = delete $self->{data};
  
  foreach my $data ( @$data ) {
    my $host_results = {};
    $host_results->{name}         = $data->{name};
    $host_results->{goals_marked} = $data->{$marked};
    $host_results->{goals_got}    = $data->{$recived};
    $host_results->{victory}++
      if $data->{$marked} > $data->{$recived};
    $host_results->{defeats}++
      if $data->{$recived} > $data->{$marked};
    push @$results, $host_results;
  }
  
  return $results;
}

1;
