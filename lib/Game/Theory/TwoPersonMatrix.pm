package Game::Theory::TwoPersonMatrix;
our $AUTHORITY = 'cpan:GENE';

# ABSTRACT: Reduce & analyze a 2 person matrix game

use strict;
use warnings;

our $VERSION = '0.0501';

use Algorithm::Combinatorics qw( variations_with_repetition );
use List::Util qw( max );
use List::MoreUtils qw( all indexes each_array );
use Math::Calculus::Differentiate;



sub new {
    my $class = shift;
    my %args = @_;
    my $self = {
        1 => $args{1} || {
            strategy => { 1 => [1,0], 2 => [0,1] },
            play     => {},
            mixed    => undef,
        },
        2 => $args{2} || {
            strategy => { 1 => [1,0], 2 => [0,1] },
            play     => {},
            mixed    => undef,
        },
    };
    bless $self, $class;
    $self->_init;
    return $self;
}

sub _init {
    my $self = shift;
    my ( $player, $opponent ) = ( $self->{1}, $self->{2} );

    for my $p ( keys %{ $player->{strategy} } )
    {
        $player->{choice}{$p} ||= 1 / keys( %{ $player->{strategy} } );
    }
    for my $p ( keys %{ $opponent->{strategy} } )
    {
        $opponent->{choice}{$p} ||= 1 / keys( %{ $opponent->{strategy} } );
    }

}


sub player_strategy
{
    my ( $self, $player ) = @_;
    return $self->{$player}{strategy};
}



sub player_choice
{
    my ( $self, $player ) = @_;
    return $self->{$player}{choice};
}


sub expected_value
{
    my ( $self, $player ) = @_;
    my $expected_value = 0;
    for my $strategy ( keys %{ $self->{$player}{strategy} } )
    {
        my $choice = $self->{$player}{choice}{$strategy};
        for my $utility ( @{ $self->{$player}{strategy}{$strategy} } )
        {
            $expected_value += $choice * $utility;
        }
    }
    return $expected_value;
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


sub mixed {
    my $self = shift;

    my @mixed;

    for my $player (sort keys %$self) {
        my @equation;
        my @pinverse;
        my @qinverse;

        # Compute the payoff equation components.
        for my $strat (sort keys %{ $self->{$player}{strategy} }) {
            my $pinverse = '(1';
            my $qinverse = '(1';
            my $i = 0;
            for my $util (@{ $self->{$player}{strategy}{$strat} }) {
                $i++;
                push @equation, "$util*p$strat*q$i";
                $pinverse .= ' - p' . $i if $i <= $strat;
                $qinverse .= ' - q' . $i if $i <= $strat;
            }
            $pinverse .= ')';
            $qinverse .= ')';
            push @pinverse, $pinverse;
            push @qinverse, $qinverse;
        }
#warn "Player $player mixed: ", join(' + ', @equation), "\n\n";

        # The last is unused. TODO Fix this with a correct condition, above.
        pop @pinverse;
        pop @qinverse;

        # Substitute all the non-initial vars with (1 - ...
        my $i = @pinverse + 1;
        for my $inv (reverse @pinverse) {
            @equation = grep { /p$i/ ? s/p$i/$inv/ : $_ } @equation;
            $i--;
        }
        $i = @qinverse + 1;
        for my $inv (reverse @qinverse) {
            @equation = grep { /q$i/ ? s/q$i/$inv/ : $_ } @equation;
            $i--;
        }

        # Remove the 1-suffix from the equation.
        @equation = grep { /p1/ ? s/p1/p/g : $_ } @equation;
        @equation = grep { /q1/ ? s/q1/q/g : $_ } @equation;

        # 
        my $mixed = join ' + ', @equation;

        # Create the expression.
        my $exp = Math::Calculus::Differentiate->new;
        $exp->addVariable('p');
        $exp->addVariable('q');
        $exp->setExpression($mixed) or die $exp->getError;
        $exp->simplify or die $exp->getError;
#warn "E: ",$exp->getExpression, "\n";
        $exp->differentiate( $player eq 1 ? 'p' : 'q' ) or die $exp->getError;
        $exp->simplify or die $exp->getError;
#warn "D: ",$exp->getExpression, "\n";

        # Set the player payoff strategy equation.
        $self->{$player}{mixed} = $exp->getExpression;
        push @mixed, $exp->getExpression;
    }

    return \@mixed;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Game::Theory::TwoPersonMatrix - Reduce & analyze a 2 person matrix game

=head1 VERSION

version 0.0501

=head1 SYNOPSIS

  use Game::Theory::TwoPersonMatrix;
  my $g = Game::Theory::TwoPersonMatrix->new(
    1 => { strategy => { 1 => \@u11, 2 => \@u12, } },
    2 => { strategy => { 1 => \@u21, 2 => \@u22, } },
  );
  $g->player_strategy(1);
  $g->player_strategy(2);
  $g->reduce(2, 1); # Player 2 given player 1
  $g->reduce(1, 2); # Player 1 given player 2
  my $m = $g->mixed;
  print Dumper $m;
  my $n = $g->nash;
  print Dumper $n;

=head1 DESCRIPTION

A C<Game::Theory::TwoPersonMatrix> reduces and analyzes a two person matrix game
of player names, strategies and numerical utilities.

* This module depends on C<Math::Calculus::Differentiate>, which in turn depends
on C<Math::Calculus::Expression> - a module not present on metacpan.org.  These
must be downloaded and built by hand.  The latter may be obtained at
L<http://search.cpan.org/~jonathan/Math-Calculus-Expression-0.2.2>.

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

  $g = Game::Theory::TwoPersonMatrix->new();
  $g = Game::Theory::TwoPersonMatrix->new(%args);
  $g = Game::Theory::TwoPersonMatrix->new(
    1 => { strategy => { 1 => [1,1,3], 2 => [0,0,3], 3 => [0,2,5] }, choice => { 1 => 0.2, 2 => 0.3, 3 => 0.5}, },
    2 => { strategy => { 1 => [0,2,2], 2 => [3,1,4], 3 => [0,0,3] }, choice => { 1 => 0.2, 2 => 0.3, 3 => 0.5}, },
  );

Create a new C<Game::Theory::TwoPersonMatrix> object.

Player defaults:

  1 => { 1 => [1,0], 2 => [0,1] }, # The "row player"
  2 => { 1 => [1,0], 2 => [0,1] }  # The "column player"

If not provided, the strategic choices are computed equally from the number of
strategies.

=head2 player_strategy()

Return the given player's strategy.

=head2 player_choice()

Return the given player's strategic choice value.

=head2 expected_value()

Return a player's expected payoff value for the entire game.

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

=head2 mixed()

  my $p = $g->mixed;
  print Dumper $p;

Example:

      | 0 3 |      | 3 0 |
  A = | 2 1 |  B = | 1 2 |

Where B<A> is the "row player" and B<B> is the "column player."

The payoff probabilities for their mixed strategies are,

  PA = 0*p1*q1 + 3*p1*q2 + 2*p2*q1 + 1*p2*q2
  PB = 3*p1*q1 + 0*p1*q2 + 1*p2*q1 + 2*p2*q2

Through substitution, simplification and differentiation, these equations become,

  PA' = 3*(1 - q) - 2*q - 1*(1 - q)
  PB' = 3*p + 1 - p - 2*(1 - p)

Which can be further simplified (by hand) to,

  PA' = -4*p + 2
  PB' = 4*p - 1

When set equal to zero and solved (by hand) for B<p> (and B<q>), to find the
optimum probabilities for each strategy when playing "mixed strategies."

For a description of mixed strategies and deriving probability profiles, please
see the relevant literature.

=head1 TO DO

Find or make an algebraic solver...

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
