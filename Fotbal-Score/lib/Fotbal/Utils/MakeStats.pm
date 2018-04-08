package Fotbal::Utils::MakeStats;

use Moo;
use MooX::late;

use Data::Dumper;
use List::Util qw(reduce);

has data => ( is => 'ro', isa => 'HashRef', required => 1 );

sub _get_victory {
  my $team = shift;
  my $data = shift;

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

  my $marked  = $config->{$team}->{marked};
  my $recived = $config->{$team}->{recived};

  #my $data         = delete $self->{data};

  foreach my $data (@$data) {
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

sub get_data {
  my $self = shift;

  my $all_game_results = [];
  my $data             = $self->data();

  foreach my $key ( keys %$data ) {
    my $result = _get_victory( $key, $data->{$key} );
    push @$all_game_results, @$result;
  }

  #sdelete $self->data();
  $self->{results} = $all_game_results;
  return $self;
}

sub make_stats {
  my $self = shift;

  my $final_results = {};

  foreach my $result ( @{ $self->{results} } ) {
    my $team_name    = $result->{name};
    my $goals_marked = $result->{goals_marked};
    my $goals_got    = $result->{goals_got};
    my $victories    = $result->{victory};
    my $defeats      = $result->{defeats};

    push @{ $final_results->{ $result->{name} }->{marked} }, $goals_marked
      if $goals_marked;
    push @{ $final_results->{ $result->{name} }->{recived} }, $goals_got
      if $goals_got;
    push @{ $final_results->{ $result->{name} }->{victory} }, $victories
      if $victories;
    push @{ $final_results->{ $result->{name} }->{defeats} }, $defeats
      if $defeats;

    my $sum_marked_goals =
      reduce { $a + $b } @{ $final_results->{ $result->{name} }->{marked} };
    my $sum_recived_goals =
      reduce { $a + $b } @{ $final_results->{ $result->{name} }->{recived} };
    my $no_of_vicories =
      reduce { $a + $b } @{ $final_results->{ $result->{name} }->{victory} };
    my $no_of_defetats =
      reduce { $a + $b } @{ $final_results->{ $result->{name} }->{defeats} };
    $final_results->{ $result->{name} }->{name}          = $result->{name};
    $final_results->{ $result->{name} }->{total_marked}  = $sum_marked_goals;
    $final_results->{ $result->{name} }->{total_recived} = $sum_recived_goals;
    $final_results->{ $result->{name} }->{total_victory} = $no_of_vicories;
    $final_results->{ $result->{name} }->{total_defeats} = $no_of_defetats;

  }
  $self->{final_results} = $final_results;

  return $self;
}

sub make_array_of_hashes {
  my $self = shift;

  my @ready_to_print;

  foreach my $key ( keys %{ $self->{final_results} } ) {
    my $row = {};

    my $name          = $self->{final_results}->{$key}->{name};
    my $total_marked  = $self->{final_results}->{$key}->{total_marked};
    my $total_recived = $self->{final_results}->{$key}->{total_recived};
    my $total_victory = $self->{final_results}->{$key}->{total_victory};
    my $total_defeats = $self->{final_results}->{$key}->{total_defeats};

    $row->{name}          = $name;
    $row->{total_marked}  = $total_marked || 0;
    $row->{recived}       = $total_recived || 0;
    $row->{total_victory} = $total_victory || 0;
    $row->{total_defeats} = $total_defeats || 0;

    push @ready_to_print, $row;
  }

  return \@ready_to_print;
}
1;
