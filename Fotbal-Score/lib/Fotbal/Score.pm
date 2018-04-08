package Fotbal::Score;
use Dancer2;

use Dancer2::Plugin::Database;

use Fotbal::Utils::Sqlib qw (make_stats_sql);
use Fotbal::Utils::MakeStats;

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
  my $sth_hosts    = database->prepare( &make_stats_sql(1) );
  my $sth_visitors = database->prepare( &make_stats_sql() );
  my $hosts        = [];
  my $visitors     = [];

  $sth_hosts->execute();
  $sth_visitors->execute();

  while ( my $row = $sth_hosts->fetchrow_hashref ) {
    push @$hosts, $row;
  }

  while ( my $row = $sth_visitors->fetchrow_hashref ) {
    push @$visitors, $row;
  }
  my $teams = { hosts => $hosts, visitors => $visitors };
  my $game_result = Fotbal::Utils::MakeStats->new( data => $teams );
  my $results = $game_result->get_data()->make_stats()->make_array_of_hashes();

  my @ready_to_print = @$results;

  # sort by victories and gols marked
  @ready_to_print = sort {
         $b->{total_victory} <=> $a->{total_victory}
      || $b->{total_marked} <=> $a->{total_marked}
  } @ready_to_print;

  my @extreme =
    sort { $b->{total_marked} <=> $a->{total_marked} } @ready_to_print;
  my $bigets_marker = $extreme[0];
  @extreme = sort { $b->{recived} <=> $a->{recived} } @ready_to_print;

  my $bigets_reciver = $extreme[0];
  @extreme = ( $bigets_marker, $bigets_reciver );
  template 'show_stats',
    {
    'team'    => \@ready_to_print,
    'extream' => \@extreme,
    };
};
true;
