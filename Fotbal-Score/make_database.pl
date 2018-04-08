use strict;
use warnings;

use DBI;
use Carp 'croak';


my $user = 'root';
my $pw = 1;

my $dbh = DBI->connect("DBI:mysql:host=localhost;port=3306", $user, $pw);



# $dbh->do("create database fotbal") or die "Cannot create database \n ";
#$dbh->do("drop database premier_league") or die "Cannot create database \n ";
# #using here docs to create a mysql database;

my $create_databse = <<"MySQL";
CREATE DATABASE IF NOT EXISTS fotbal;
MySQL
$dbh->do($create_databse) or die "Cannot create database \n ";
$dbh->do("use premier_leaguess");

my $teams =<<"SQL";
CREATE TABLE IF NOT EXISTS teams(
  id INTEGER  AUTO_INCREMENT,
  name varchar(10) UNIQUE,
  PRIMARY KEY ( id )
);
SQL
$dbh->do($teams);

my $games =<<"SQL";
CREATE TABLE IF NOT EXISTS games(
  id INTEGER  AUTO_INCREMENT,
  team_id_1 INTEGER NOT NULL,
  team_id_2 INTEGER NOT NULL,
  PRIMARY KEY ( id ),
  FOREIGN KEY (team_id_1) REFERENCES teams(id) ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY (team_id_2) REFERENCES teams(id) ON DELETE CASCADE ON UPDATE CASCADE
);
SQL
$dbh->do($games);

my $score =<<"SQL";
CREATE TABLE IF NOT EXISTS games(
  id INTEGER  AUTO_INCREMENT,
  goals_team_1 INTEGER NOT NULL,
  goals_team_2 INTEGER NOT NULL,
  PRIMARY KEY ( id ),
  FOREIGN KEY (id) REFERENCES games(id) ON DELETE CASCADE ON UPDATE CASCADE
);
SQL
$dbh->do($score);

