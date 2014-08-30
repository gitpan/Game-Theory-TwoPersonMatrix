package Game::Theory::TwoPersonMatrix;
BEGIN {
  $Game::Theory::TwoPersonMatrix::AUTHORITY = 'cpan:GENE';
}

# ABSTRACT: Reduce & analyze a 2 person matrix game

use strict;
use warnings;

our $VERSION = '0.03';

use Algorithm::Combinatorics qw( variations_with_repetition );
use List::Util qw( max );
use List::MoreUtils qw( all indexes each_array );



sub new {
    my $class = shift;
    my %args = @_;
    my $self = {
        1 => $args{1} || {
            strategy => { 1 => [1,0], 2 => [0,1] },
            mixed    => undef,
            payoff   => undef,
        },
        2 => $args{2} || {
            strategy => { 1 => [1,0], 2 => [0,1] },
            mixed    => undef,
            payoff   => undef,
        },
    };
    bless $self, $class;
    $self->_init;
    return $self;
}

sub _init {
    my $self = shift;
#    my ($player, $opponent) = ($self->{1}{strategy}, $self->{2}{strategy});
}


sub reduce {
    my $self = shift;

    # Set the players.
    my ($player, $opponent) = @_;
    ($player, $opponent) = ($self->{$player}{strategy}, $self->{$opponent}{strategy});

    # Declare the bucket of "X given Y" strategy pair utilities.
    my $utility = {};
    my $metric  = {};

    # Evaluate pairs of strategies.
    my $iter = variations_with_repetition([ keys %$player ], 2);
    while (my $v = $iter->next) {
        # Skip "X|X" pairs.
        # XXX Only need to inspect combinations and flag relative utility.
        next if $v->[0] eq $v->[1];

        # Inspect each strategy utility.
        #warn join(', ', @$v), "\n";
        for my $i (0 .. @$v - 1) {
            # Only consider defined utilities.
            if (defined $player->{$v->[0]}[$i] && defined $player->{$v->[1]}[$i]) {
                #warn "$i: $player->{$v->[0]}[$i] vs $player->{$v->[1]}[$i]\n";

                # Add a relative utility indicator.
                if ($player->{$v->[0]}[$i] > $player->{$v->[1]}[$i]) {
                    # Strictly dominant utility
                    push @{ $utility->{join '|', @$v} }, 1;
                }
                elsif ($player->{$v->[0]}[$i] < $player->{$v->[1]}[$i]) {
                    # Strictly dominated utility
                    push @{ $utility->{join '|', @$v} }, -1;
                }
                else {
                    # Equivalent utility
                    push @{ $utility->{join '|', @$v} }, 0;
                }

                # Track the actual relative utility metric.
                #push @{ $metric->{join '|', @$v} }, $player->{$v->[0]}[$i] - $player->{$v->[1]}[$i];
            }
        }
    }

    # Remove a strictly dominated strategy.
    for my $strat (keys %$utility) {
        if (all { $_ == -1 } @{$utility->{$strat}}) {
            #warn "U:[@{$utility->{$strat}}]\n";

            # Capture the strategies.
            my @dominated = split /\|/, $strat;
            #warn "D:'$dominated[0]'\n";

            # Remove the S.D. strategy.
            delete $player->{$dominated[0]};

            # Remove the utilities for the deleted opponent strategy.
            for my $u (keys %$opponent) {
                splice @{$opponent->{$u}}, $dominated[0] - 1, 1;
                #warn "u:'@{$opponent->{$u}}'\n";
            }

            # Currently, we only reduce by a single strategy.
            last;
        } 
    }

    return $player, $opponent;
}


sub nash {
    my $self = shift;

    # Convenience:
    my ($player, $opponent) = ($self->{1}{strategy}, $self->{2}{strategy});

    # Inspect each player item for best strategy.
    my %x; # Max utility indexes.

    # Get the best strategies of the player.
    for my $u ( sort { $a <=> $b } keys %$player ) {
        # Find the maximum utility for the strategy.
        my $max = max @{ $player->{$u} };

        # Get the "strategically most desirable" indexes.
        $x{$u} = [ indexes { $_ >= $max } @{ $player->{$u} } ];
    }

    # Inspect each opponent item for best strategy...
    my %y;
    for my $u ( sort { $a <=> $b } keys %$opponent ) {
        my $max = max @{ $opponent->{$u} };
        $y{$u} = [ indexes { $_ >= $max } @{ $opponent->{$u} } ];
    }
    #warn 'X:',Data::Dumper->new([\%x])->Indent(1)->Terse(1)->Quotekeys(0)->Sortkeys(1)->Dump;
    #warn 'Y:',Data::Dumper->new([\%y])->Indent(1)->Terse(1)->Quotekeys(0)->Sortkeys(1)->Dump;

    # Identify the Nash equilibria.
    my $nash = {};

    # Inspect index pairs of strategies.
    my @xstrat = sort { $a <=> $b } keys %x;
    my @ystrat = sort { $a <=> $b } keys %y;
    my $estrat = each_array(@xstrat, @ystrat);
    while ( my ($xs, $ys) = $estrat->() ) {
        #warn "xs:'@{$x{$xs}}'\n";
        #warn "ys:'@{$y{$ys}}'\n";

        # Inspect index pairs of utilities.
        my $eutil = each_array(@{$x{$xs}}, @{$y{$ys}});
        while ( my ( $i, $j ) = $eutil->() ) {
            # Are the best strategies for both players on the same coordinate?
            if ( defined $i && defined $j && $i == $j ) {
                #warn "$xs,$ys: $i == $j\n";

                # Save the strategy coordinate and utilities.
                $nash->{"$xs,$ys"} = [ $player->{$xs}[$i], $opponent->{$ys}->[$j] ];
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

Game::Theory::TwoPersonMatrix - Reduce & analyze a 2 person matrix game

=head1 VERSION

version 0.03

=head1 SYNOPSIS

  use Game::Theory::TwoPersonMatrix;
  my $g = Game::Theory::TwoPersonMatrix->new(
    1 => { strategy => { 1 => \@s1, 2 => \@s2, } },
    2 => { strategy => { 1 => \@t1, 2 => \@t2, } },
  );
  $g->reduce(2, 1);
  $g->reduce(1, 2);
  my $n = $g->nash;
  print Dumper $n;

=head1 DESCRIPTION

A C<Game::Theory::TwoPersonMatrix> reduces and analyzes a two person matrix game
of player names, strategies and numerical utilities.

The players must have the same number of strategies, and each strategy must have
the same size utility vectors as all the others.

Player strategies are given by a 2D matrix of utilities such that,

  [ [ u1, u2 .. un] .. [ v1, v2 .. vn ] ]

Where each "B<u>i" is a utility measure for the strategy "B<U>."

Player 1 and 2 are the "row" and "column" players, respectively.  This is due to
the tabular format of a matrix game:

                  Player 2
                  --------
         Strategy  1    2
 Player |    1    1,0  1,3
    1   |    3    0,2  2,4

The same game in "linear form" is:

 P1: { 1: [1,1], 3: [0,2] }
 P2: { 1: [0,2], 2: [3,4] }

In "bimatrix" form, the game is:

      | 1 1 |       | 0 2 |
 P1 = | 0 2 |  P2 = | 3 4 |

=head1 METHODS

=head2 new()

  my $g = Game::Theory::TwoPersonMatrix->new(%args);

Create a new C<Game::Theory::TwoPersonMatrix> object.

Player defaults:

  1 => { 1 => [1,0], 2 => [0,1] }, # The "row player"
  2 => { 1 => [1,0], 2 => [0,1] }  # The "column player"

=head2 reduce()

  $g->reduce_game(1, 2); # Player 1 given opponent 2
  print Dumper $g->{1}, $g->{2};
  $g->reduce_game(2, 1); # Player 2 given opponent 1
  print Dumper $g->{1}, $g->{2};

Reduce the game by elimination of a single strictly dominated strategy of the
player.

Use repeated application of this method to solve a game, or verify that it is
insoluble.

=head2 nash()

  my $equilibria = $g->nash;
  print Dumper $equilibria;

Find the Nash equilibria.

=head1 TO DO

Find or make an algebraic solver...

Figure out how to re-enable mixed().

=head1 SEE ALSO

The game theory sections and exercises of "Games and Decision Making"
L<http://www.amazon.com/Games-Decision-Making-Charalambos-Aliprantis/dp/019530022X/>

=head1 AUTHOR

Gene Boggs <gene@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Gene Boggs.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
