package Fotbal::Score;
use Dancer2;

use Dancer2::Plugin::Database;
use List::Util qw(reduce);

use Fotbal::Utils::Sqlib qw (make_stats_sql);

our $VERSION = '0.1';

my $flash;

sub set_flash {
  my $message = shift;

  $flash = $message;
}

sub get_flash {

  my $msg = $flash;
  $flash = "";

  return $msg;
}

get '/' => sub {
  template 'index',
    {
    'msg'           => get_flash(),
    'add_entry_url' => uri_for('/add_teams'),
    'stats_url'     => uri_for('/see_stats'),
    'game_url'      => uri_for('/play'),
    };
};

get '/add_teams' => sub {

  template 'add_team';
};

post '/add_teams' => sub {
  my $team_1 = params->{team_1};
  #my $team_2 = params->{team_2};
  database->quick_insert( 'teams', { name => $team_1 } );
  #database->quick_insert( 'teams', { name => $team_2 } );
  set_flash(
    "$team_1 -> added. 
      Go play\n"
  );

  redirect '/';
};

get '/play' => sub {
  my @all_teams = ();

  my $sth = database->prepare('select * from teams');
  $sth->execute();

  while ( my $row = $sth->fetchrow_hashref ) {
    push @all_teams, $row;
  }

  template 'create_games', { 'team_names' => \@all_teams, };
};

post '/paly' => sub {
  my $team_1 = params->{team_1};
  my $team_2 = params->{team_2};

  # get team id
  my $sth = database->prepare( 'select id from teams where name = ?', );

  my @ids;

  foreach my $name ( $team_1, $team_2 ) {
    $sth->execute($name);
    push @ids, $sth->fetchrow_hashref;
  }

  # create game and generate score
  database->quick_insert( 'games',
    { team_id_1 => $ids[0]->{id}, team_id_2 => $ids[1]->{id} } );

  my $goals_team_1 = int( rand( length($team_1) ) );
  my $goals_team_2 = int( rand( length($team_2) ) );

  database->quick_insert( 'score',
    { goals_team_1 => $goals_team_1, goals_team_2 => $goals_team_2 } );

  set_flash("Go stats to see the result of the game");
  redirect '/';
};

get '/see_stats' => sub {
  my $sth_hosts = database->prepare( &make_stats_sql(1) );
  my $sth_visitors = database->prepare( &make_stats_sql() );
  my $hosts     = [];
  my $visitors = [];

  $sth_hosts->execute();
  $sth_visitors->execute();

  while ( my $row = $sth_hosts->fetchrow_hashref ) {
    push @$hosts, $row;
  }

  while ( my $row = $sth_visitors->fetchrow_hashref ) {
    push @$visitors, $row;
  }
  
my $results = [];

  foreach my $data (@$hosts) {
    my $host_results = {};
    $host_results->{name} = $data->{name};
    $host_results->{goals_marked} = $data->{goals_team_1};
    $host_results->{goals_got} = $data->{goals_team_2};
    $host_results->{victory}++
      if $data->{goals_team_1} > $data->{goals_team_2};
    $host_results->{defeats}++
      if $data->{goals_team_2} > $data->{goals_team_1};
      push @$results, $host_results;
  }

  foreach my $data (@$visitors) {
    my $visitor_results = {};

    $visitor_results->{name} = $data->{name};
    $visitor_results->{goals_marked} = $data->{goals_team_2};
    $visitor_results->{goals_got} = $data->{goals_team_1};
    $visitor_results->{victory}++
      if $data->{goals_team_2} > $data->{goals_team_1};
    $visitor_results->{defeats}++
      if $data->{goals_team_1} > $data->{goals_team_2};
      push @$results, $visitor_results;
  }
  my $final_results = {};
  my @vic;
  my @defeats;
  my @goals_marked;
  my @goals_got;

  foreach my $result (@$results) {
    my $team_name = $result->{name};
    my $goals_marked = $result->{goals_marked};
    my $goals_got = $result->{goals_got};
    my $victories = $result->{victory};
    my $defeats = $result->{defeats};

   push @{$final_results->{$result->{name}}->{marked}}, $goals_marked;
    #if $goals_marked;
   push @{$final_results->{$result->{name}}->{recived}}, $goals_got;
    #if $goals_got;
   push @{$final_results->{$result->{name}}->{victory}}, $victories;
    #if $victories;
   push @{$final_results->{$result->{name}}->{defeats}}, $defeats;
    #if $defeats;
  
    my $sum_marked_goals =
      reduce { $a + $b } @{$final_results->{$result->{name}}->{marked}};
    my $sum_recived_goals =
      reduce { $a + $b } @{$final_results->{$result->{name}}->{recived}};
    my $no_of_vicories = reduce { $a + $b } @{$final_results->{$result->{name}}->{victory}};
    my $no_of_defetats = reduce { $a + $b } @{$final_results->{$result->{name}}->{defeats}};
    $final_results->{$result->{name}}->{name} = $result->{name};
    $final_results->{$result->{name}}->{total_marked}  = $sum_marked_goals;
    $final_results->{$result->{name}}->{total_recived} = $sum_recived_goals;
    $final_results->{$result->{name}}->{total_victory} = $no_of_vicories;
    $final_results->{$result->{name}}->{total_defeats} = $no_of_defetats;

   }
  my @ready_to_print;
  debug($final_results);
  foreach my $key (keys %$final_results) {
    my $row = {};
  
      my $name = $final_results->{$key}->{name};
      my $total_marked = $final_results->{$key}->{total_marked};
      my $total_recived = $final_results->{$key}->{total_recived};
      my $total_victory = $final_results->{$key}->{total_victory};
      my $total_defeats = $final_results->{$key}->{total_defeats};
      
      $row->{name} = $name;
      $row->{total_marked} = $total_marked || 0;
      $row->{recived} = $total_recived || 0;
      $row->{total_victory} = $total_victory || 0;
      $row->{total_defeats} = $total_defeats || 0; 
    
   push @ready_to_print, $row;
  }
   # sort by victories and gols marked
   @ready_to_print = sort {$b->{total_victory} <=> $a->{total_victory} ||
    $b->{total_marked} <=> $a->{total_marked} } @ready_to_print;

    my @extreme =  sort { $b->{total_marked} <=> $a->{total_marked} } @ready_to_print;
    my $bigets_marker = $extreme[0];
    @extreme =  sort { $b->{total_recived} <=> $a->{total_recived} } @ready_to_print;
    my $bigets_reciver = $extreme[0];
    @extreme = ($bigets_marker, $bigets_reciver);
   template 'show_stats', {
    'team' => \@ready_to_print,
    'extream' => \@extreme,
   };
};
true;
