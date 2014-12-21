package Game::Theory::TwoPersonMatrix;
BEGIN {
  $Game::Theory::TwoPersonMatrix::AUTHORITY = 'cpan:GENE';
}

# ABSTRACT: Analyze a 2 person matrix game

use strict;
use warnings;

use Carp;
use Algorithm::Combinatorics qw( permutations );
use List::Util qw( max min );
use List::MoreUtils qw( all zip );
use Array::Transpose;

our $VERSION = '0.1502';



sub new {
    my $class = shift;
    my %args = @_;
    my $self = {
        1 => $args{1},
        2 => $args{2},
        payoff => $args{payoff},
        payoff1 => $args{payoff1},
        payoff2 => $args{payoff2},
    };
    bless $self, $class;
    return $self;
}


sub expected_payoff
{
    my ($self) = @_;

    my $expected_payoff;
    # For each strategy of player 1...
    for my $i ( sort { $a <=> $b } keys %{ $self->{1} } )
    {
        # For each strategy of player 2...
        for my $j ( sort { $a <=> $b } keys %{ $self->{2} } )
        {
            if ( $self->{payoff1} && $self->{payoff2} )
            {
                $expected_payoff->[0] += $self->{1}{$i} * $self->{2}{$j} * $self->{payoff1}[$i - 1][$j - 1];
                $expected_payoff->[1] += $self->{1}{$i} * $self->{2}{$j} * $self->{payoff2}[$i - 1][$j - 1];
            }
            else {
                # Expected value is the sum of the probabilities of each payoff
                $expected_payoff += $self->{1}{$i} * $self->{2}{$j} * $self->{payoff}[$i - 1][$j - 1];
            }
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


sub saddlepoint
{
    my ($self) = @_;

    my $saddlepoint;
    my $size = @{ $self->{payoff}[0] } - 1;

    # Look for saddlepoints!
    POINT:
    for my $row ( 0 .. $size )
    {
        # Get the minimum value of the current row
        my $min = min @{ $self->{payoff}[$row] };

        # Inspect each column given the row
        for my $col ( 0 .. $size )
        {
            # Get the payoff
            my $val = $self->{payoff}[$row][$col];

            # Is the payoff also the row minimum?
            if ( $val == $min )
            {
                # Gather the column values for each row
                my @col;
                for my $r ( 0 .. $size )
                {
                    push @col, $self->{payoff}[$r][$col];
                }
                # Get the maximum value of the columns
                my $max = max @col;

                # Is the payoff also the column maximum?
                if ( $val == $max )
                {
                    $saddlepoint = $val;
                    last POINT;
                }
            }
        }
    }

    return $saddlepoint;
}


sub oddments
{
    my ($self) = @_;

    my $rsize = @{ $self->{payoff}[0] };
    my $csize = @{ $self->{payoff} };
    carp 'Payoff matrix must be 2x2' unless $rsize == 2 && $csize == 2;

    my ( $player, $opponent );

    my $A = $self->{payoff}[0][0];
    my $B = $self->{payoff}[0][1];
    my $C = $self->{payoff}[1][0];
    my $D = $self->{payoff}[1][1];

    my ( $x, $y );
    $x = $D - $C;
    $y = $A - $B;
    if ( $x < 0 || $y < 0 )
    {
        $x = $C - $D;
        $y = $B - $A;
    }
    my $i = $x / ( $x + $y );
    my $j = $y / ( $x + $y );
    $player = [ $i, $j ];

    $x = $D - $B;
    $y = $A - $C;
    if ( $x < 0 || $y < 0 )
    {
        $x = $B - $D;
        $y = $C - $A;
    }
    $i = $x / ( $x + $y );
    $j = $y / ( $x + $y );
    $opponent = [ $i, $j ];

    return [ $player, $opponent ];
}


sub row_reduce
{
    my ($self) = @_;

    my @spliced;

    my $rsize = @{ $self->{payoff} } - 1;
    my $csize = @{ $self->{payoff}[0] } - 1;

    for my $row ( 0 .. $rsize )
    {
#warn "R:$row = @{ $self->{payoff}[$row] }\n";
        for my $r ( 0 .. $rsize )
        {
            next if $r == $row;
#warn "\tN:$r = @{ $self->{payoff}[$r] }\n";
            my @cmp;
            for my $x ( 0 .. $csize )
            {
                push @cmp, ( $self->{payoff}[$row][$x] <= $self->{payoff}[$r][$x] ? 1 : 0 );
            }
#warn "\t\tC:@cmp\n";
            if ( all { $_ == 1 } @cmp )
            {
                push @spliced, $row;
            }
        }
    }

    $self->_reduce_game( $self->{payoff}, \@spliced, 1 );

    return $self->{payoff};
}


sub col_reduce
{
    my ($self) = @_;

    my @spliced;

    my $transposed = transpose( $self->{payoff} );

    my $rsize = @$transposed - 1;
    my $csize = @{ $transposed->[0] } - 1;

    for my $row ( 0 .. $rsize )
    {
#warn "R:$row = @{ $transposed->[$row] }\n";
        for my $r ( 0 .. $rsize )
        {
            next if $r == $row;
#warn "\tN:$r = @{ $transposed->[$r] }\n";
            my @cmp;
            for my $x ( 0 .. $csize )
            {
                push @cmp, ( $transposed->[$row][$x] >= $transposed->[$r][$x] ? 1 : 0 );
            }
#warn "\t\tC:@cmp\n";
            if ( all { $_ == 1 } @cmp )
            {
                push @spliced, $row;
            }
        }
    }

    $self->_reduce_game( $transposed, \@spliced, 2 );

    $self->{payoff} = transpose( $transposed );

    return $self->{payoff};
}

sub _reduce_game
{
    my ( $self, $payoff, $spliced, $player ) = @_;

    my $seen = 0;
    for my $row ( @$spliced )
    {
        $row -= $seen++;
        # Reduce the payoff column
        splice @$payoff, $row, 1;
        # Eliminate the strategy of the opponent
        delete $self->{$player}{$row + 1} if exists $self->{$player}{$row + 1};
    }
}


sub mm_tally
{
    my ($self) = @_;

    my $mm_tally;

    if ( $self->{payoff1} && $self->{payoff2} )
    {
        # Find maximum of row minimums for each player
        $mm_tally = $self->_tally_max( $mm_tally, 1, $self->{payoff1} );

        # Find minimum of column maximums
        my @m = ();
        my %s = ();
        my $transposed = transpose( $self->{payoff2} );
        for my $row ( 0 .. @$transposed - 1 )
        {
            $s{$row} = min @{ $transposed->[$row] };
            push @m, $s{$row};
        }
        $mm_tally->{2}{value} = max @m;
        for my $row ( sort { $a <=> $b } keys %s )
        {
            push @{ $mm_tally->{2}{strategy} }, ( $s{$row} == $mm_tally->{2}{value} ? 1 : 0 );
        }
    }
    else
    {
        # Find maximum of row minimums
        $mm_tally = $self->_tally_max( $mm_tally, 1, $self->{payoff} );

        # Find minimum of column maximums
        my @m = ();
        my %s = ();
        my $transposed = transpose( $self->{payoff} );
        for my $row ( 0 .. @$transposed - 1 )
        {
            $s{$row} = max @{ $transposed->[$row] };
            push @m, $s{$row};
        }
        $mm_tally->{2}{value} = min @m;
        for my $row ( sort { $a <=> $b } keys %s )
        {
            push @{ $mm_tally->{2}{strategy} }, ( $s{$row} == $mm_tally->{2}{value} ? 1 : 0 );
        }
    }

    return $mm_tally;
}

sub _tally_max
{
    my ( $self, $mm_tally, $player, $payoff ) = @_;

    my @m;
    my %s;

    # Find maximum of row minimums
    for my $row ( 0 .. @$payoff - 1 )
    {
        $s{$row} = min @{ $payoff->[$row] };
        push @m, $s{$row};
    }

    $mm_tally->{$player}{value} = max @m;

    for my $row ( sort { $a <=> $b } keys %s )
    {
        push @{ $mm_tally->{$player}{strategy} }, ( $s{$row} == $mm_tally->{$player}{value} ? 1 : 0 );
    }

    return $mm_tally;
}


sub pareto_optimal
{
    my ($self) = @_;

    my $pareto_optimal;

    my $rsize = @{ $self->{payoff1} } - 1;
    my $csize = @{ $self->{payoff1}[0] } - 1;

    for my $row ( 0 .. $rsize )
    {
        for my $col ( 0 .. $csize )
        {
#warn "RC:$row,$col = ($self->{payoff1}[$row][$col],$self->{payoff2}[$row][$col])\n";

            my %seen;
            for my $r ( 0 .. $rsize )
            {
                for my $c ( 0 .. $csize )
                {
                    next if ( $r == $row && $c == $col ) || $seen{"$r,$c"}++;
#warn "\trc:$r,$c = ($self->{payoff1}[$r][$c],$self->{payoff2}[$r][$c])\n";
                    if ( $self->{payoff1}[$row][$col] >= $self->{payoff1}[$r][$c]
                        && $self->{payoff2}[$row][$col] >= $self->{payoff2}[$r][$c] )
                    {
#warn "\t\t$row,$col > $r,$c at ($self->{payoff1}[$row][$col], $self->{payoff2}[$row][$col])\n";
                        $pareto_optimal->{ "$row,$col" } = [
                            $self->{payoff1}[$row][$col], $self->{payoff2}[$row][$col]
                        ];
                    }
                }
            }
        }
    }

    return $pareto_optimal;
}


sub nash
{
    my ($self) = @_;

    my $nash;

    my $rsize = @{ $self->{payoff1} } - 1;
    my $csize = @{ $self->{payoff1}[0] } - 1;

    for my $row ( 0 .. $rsize )
    {
        my $rmax = max @{ $self->{payoff2}[$row] };

        for my $col ( 0 .. $csize )
        {
#warn "RC:$row,$col = ($self->{payoff1}[$row][$col],$self->{payoff2}[$row][$col])\n";

            my @col;
            for my $r ( 0 .. $rsize )
            {
                push @col, $self->{payoff1}[$r][$col];
            }
            my $cmax = max @col;
            if ( $self->{payoff1}[$row][$col] == $cmax && $self->{payoff2}[$row][$col] == $rmax )
            {
#warn "\t$self->{payoff1}[$row][$col] == $cmax && $self->{payoff2}[$row][$col] == $rmax\n";
                $nash->{"$row,$col"} = [ $self->{payoff1}[$row][$col],$self->{payoff2}[$row][$col] ];
            }
        }
    }

    return $nash;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Game::Theory::TwoPersonMatrix - Analyze a 2 person matrix game

=head1 VERSION

version 0.1502

=head1 SYNOPSIS

 use Game::Theory::TwoPersonMatrix;
 $g = Game::Theory::TwoPersonMatrix->new(
    1 => { 1 => 0.2, 2 => 0.3, 3 => 0.5 },
    2 => { 1 => 0.1, 2 => 0.7, 3 => 0.2 },
    payoff => [ [-5, 4, 6],
                [ 3,-2, 2],
                [ 2,-3, 1] ]
 };
 $g->row_reduce();
 $g->col_reduce();
 $p = $g->saddlepoint();
 $o = $g->oddments();
 $e = $g->expected_payoff();
 $c = $g->counter_strategy($player);

 $g = Game::Theory::TwoPersonMatrix->new(
    1 => { 1 => 0.1, 2 => 0.2, 3 => 0.7 },
    2 => { 1 => 0.1, 2 => 0.2, 3 => 0.3, 4 => 0.4 },
    payoff1 => [ [5,3,8,2],[6,5,7,1],[7,4,6,0] ],
    payoff2 => [ [2,0,1,3],[3,4,4,1],[5,6,8,2] ],
 );
 $t = $g->mm_tally();
 $m = $g->pareto_optimal();
 $n = $g->nash();
 $e = $g->expected_payoff();

=head1 DESCRIPTION

A C<Game::Theory::TwoPersonMatrix> analyzes a two person matrix game
of player names, strategies and utilities ("payoffs").

The players must have the same number of strategies, and each strategy must have
the same size utility vectors as all the others.

Players 1 and 2 are the "row" and "column" players, respectively.  This is due
to the tabular format of a matrix game:

                  Player 2
                  --------
         Strategy 0.5  0.5
 Player |   0.5    1   -1  < Payoff
    1   |   0.5   -1    1  <

A non-zero sum game is represented by two payoff profiles, as above in the
SYNOPSIS.

=head1 METHODS

=head2 new()

 $g = Game::Theory::TwoPersonMatrix->new(
    1 => { 1 => '0.5', 2 => '0.5' },
    2 => { 1 => '0.5', 2 => '0.5' },
    payoff => [ [1,0],
                [0,1] ]
 );
 $g = Game::Theory::TwoPersonMatrix->new(
    payoff1 => [ [2,3],[2,1] ],
    payoff2 => [ [3,5],[2,3] ],
 );

Create a new C<Game::Theory::TwoPersonMatrix> object.

=head2 expected_payoff()

 $e = $g->expected_payoff();

Return the expected payoff value of the game.

=head2 s_expected_payoff()

 $g = Game::Theory::TwoPersonMatrix->new(
    1 => { 1 => '(1 - p)', 2 => 'p' },
    2 => { 1 => 1, 2 => 0 },
    payoff => [ ['a','b'], ['c','d'] ]
 );
 $s = $g->s_expected_payoff();

Return the expected payoff expression for a non-numeric game.

Using real payoff values, we solve the resulting expression for p in the F<eg/>
examples.

=head2 counter_strategy()

 $c = $g->counter_strategy($player);

Return the counter-strategies for a given player.

=head2 saddlepoint()

 $p = $g->saddlepoint;

If the game is strictly determined, the saddlepoint is returned.  Otherwise
C<undef> is returned.

=head2 oddments()

 $o = $g->oddments();

Return each player's "oddments" for a 2x2 game.

=head2 row_reduce()

 $g->row_reduce();

Reduce a game by identifying and eliminating strictly dominated rows and their
associated player strategies.

=head2 col_reduce()

 $g->col_reduce();

Reduce a game by identifying and eliminating strictly dominated columns and their
associated opponent strategies.

=head2 mm_tally()

 $t = $g->mm_tally();

For zero-sum games, return the maximum of row minimums and the minimum of column
maximums.  For non-zero-sum games, return the maximum of row and column minimums.

=head2 pareto_optimal()

 $m = $g->pareto_optimal();

Return the Pareto optimal outcomes.

=head2 nash()

 $n = $g->nash();

Identify the Nash equilibria.

Given payoff pair C<(a, b)> B<a> is maximum for its column and B<b> is maximum
for its row.

=head1 SEE ALSO

The F<eg/> and F<t/> scripts in this distribution.

"A Gentle Introduction to Game Theory"

L<http://www.amazon.com/Gentle-Introduction-Theory-Mathematical-World/dp/0821813390>

L<http://books.google.com/books?id=8doVBAAAQBAJ>

=head1 AUTHOR

Gene Boggs <gene@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Gene Boggs.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
