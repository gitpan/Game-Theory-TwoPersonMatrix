package Game::Theory::TwoPersonMatrix;
BEGIN {
  $Game::Theory::TwoPersonMatrix::AUTHORITY = 'cpan:GENE';
}

# ABSTRACT: Analyze a 2 person matrix game

use strict;
use warnings;

use Algorithm::Combinatorics qw( permutations );
use List::MoreUtils qw( zip );

our $VERSION = '0.0801';



sub new {
    my $class = shift;
    my %args = @_;
    my $self = {
        1 => $args{1} || { 1 => '0.5', 2 => '0.5' },
        2 => $args{2} || { 1 => '0.5', 2 => '0.5' },
        payoff => $args{payoff} || [ [1,-1], [-1,1] ],
    };
    bless $self, $class;
    return $self;
}


sub expected_payoff
{
    my ($self) = @_;

    my $expected_payoff = 0;
    # For each strategy of player 1...
    for my $i ( sort { $a <=> $b } keys %{ $self->{1} } )
    {
        # For each strategy of player 2...
        for my $j ( sort { $a <=> $b } keys %{ $self->{2} } )
        {
            # Expected value is the sum of the probabilities of each payoff
            $expected_payoff += $self->{1}{$i} * $self->{2}{$j} * $self->{payoff}[$i - 1][$j - 1];
        }
    }

    return $expected_payoff;
}


sub s_expected_payoff
{
    my ($self) = @_;

    my $expected_payoff = '';
    # For each strategy of player 1...
    for my $i ( sort { $a <=> $b } keys %{ $self->{1} } )
    {
        # For each strategy of player 2...
        for my $j ( sort { $a <=> $b } keys %{ $self->{2} } )
        {
            # Expected value is the sum of the probabilities of each payoff
            $expected_payoff .= " + $self->{1}{$i} * $self->{2}{$j} * $self->{payoff}[$i - 1][$j - 1]";
        }
    }

    $expected_payoff =~ s/^ \+ (.+)$/$1/g;

    return $expected_payoff;
}


sub counter_strategy
{
    my ( $self, $player ) = @_;

    my $counter_strategy = [];
    my %seen;

    my $opponent = $player == 1 ? 2 : 1;

    my @keys = 1 .. keys %{ $self->{$player} };
    my @pure = ( 1, (0) x ( keys( %{ $self->{$player} } ) - 1 ) );

    my $i = permutations( \@pure );
    while ( my $x = $i->next )
    {
        next if $seen{"@$x"}++;

        my $g = Game::Theory::TwoPersonMatrix->new(
            $player   => { zip @keys, @$x },
            $opponent => $self->{$opponent},
            payoff    => $self->{payoff},
        );

        push @$counter_strategy, $g->expected_payoff();
    }

    return $counter_strategy;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Game::Theory::TwoPersonMatrix - Analyze a 2 person matrix game

=head1 VERSION

version 0.0801

=head1 SYNOPSIS

 use Game::Theory::TwoPersonMatrix;
 my $g = Game::Theory::TwoPersonMatrix->new();
 $g = Game::Theory::TwoPersonMatrix->new(
    1 => { 1 => 0.2, 2 => 0.3, 3 => 0.5 },
    2 => { 1 => 0.1, 2 => 0.7, 3 => 0.2 },
    payoff => [ [ 0, 1,-1],
                [-1, 0, 1],
                [ 1,-1, 0] ]
 };
 $g->expected_payoff();
 $g->counter_strategy($player);

=head1 DESCRIPTION

A C<Game::Theory::TwoPersonMatrix> analyzes a two person matrix game
of player names, strategies and utilities.

The players must have the same number of strategies, and each strategy must have
the same size utility vectors as all the others.

Players 1 and 2 are the "row" and "column" players, respectively.  This is due
to the tabular format of a matrix game:

                  Player 2
                  --------
         Strategy 0.5  0.5
 Player |   0.5    1   -1  < Payoff
    1   |   0.5   -1    1  <

The above is the default - a symmetrical zero-sum game.

=head1 METHODS

=head2 new()

 $g = Game::Theory::TwoPersonMatrix->new();
 $g = Game::Theory::TwoPersonMatrix->new(
    1 => { 1 => '0.5', 2 => '0.5' },
    2 => { 1 => '0.5', 2 => '0.5' },
    payoff => [ [1,0],
                [0,1] ]
 );

Create a new C<Game::Theory::TwoPersonMatrix> object.

=head2 expected_payoff()

 $g->expected_payoff();

Return the expected payoff value of the game.

=head2 s_expected_payoff()

 $g = Game::Theory::TwoPersonMatrix->new(
    1 => { 1 => '(1 - p)', 2 => 'p' },
    2 => { 1 => 1, 2 => 0 },
    payoff => [ ['a','b'], ['c','d'] ]
 );
 $g->s_expected_payoff();

Return the expected payoff expression for a non-numeric game.

Using real payoff values, we solve the resulting expression for p in the F<eg/>
examples.

=head2 counter_strategy()

 $g->counter_strategy($player);

Return the counter-strategies for a given player.

=head1 SEE ALSO

"A Gentle Introduction to Game Theory"
L<http://www.amazon.com/Gentle-Introduction-Theory-Mathematical-World/dp/0821813390>

=head1 AUTHOR

Gene Boggs <gene@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Gene Boggs.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
