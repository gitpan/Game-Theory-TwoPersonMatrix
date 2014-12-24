use Test::More;
use_ok 'Game::Theory::TwoPersonMatrix';

my $g = Game::Theory::TwoPersonMatrix->new;
isa_ok $g, 'Game::Theory::TwoPersonMatrix';
is $g->expected_payoff(), undef, 'expected_payoff';

$g = Game::Theory::TwoPersonMatrix->new(
    1 => { 1 => '0.2', 2 => '0.8' },
    2 => { 1 => '0.3', 2 => '0.7' },
    payoff => [ [5,0], [-1,2] ]
);
isa_ok $g, 'Game::Theory::TwoPersonMatrix', '2x2';
is $g->expected_payoff(), 1.18, 'expected_payoff';

$g = Game::Theory::TwoPersonMatrix->new(
    1 => { 1 => '0.2', 2 => '0.3', 3 => '0.5' },
    2 => { 1 => '0.1', 2 => '0.7', 3 => '0.2' },
    payoff => [ [ 0, 1,-1],
                [-1, 0, 1],
                [ 1,-1, 0],
    ]
);
isa_ok $g, 'Game::Theory::TwoPersonMatrix', '3x3';
is $g->expected_payoff(), -0.17, 'expected_payoff';

$g = Game::Theory::TwoPersonMatrix->new(
    1 => { 1 => '0.3', 2 => '0',   3 => '0.7' },
    2 => { 1 => '0.1', 2 => '0.2', 3 => '0.3', 4 => '0.4' },
    payoff => [ [2,-1,-5, 3],
                [0,-2, 3,-3],
                [1, 0, 1,-2],
    ]
);
isa_ok $g, 'Game::Theory::TwoPersonMatrix', '3x4';
is $g->expected_payoff(), -0.37, 'expected_payoff';

$g = Game::Theory::TwoPersonMatrix->new(
    1 => { 1 => 'p', 2 => '1 - p' },
    2 => { 1 => 'q', 2 => '1 - q' },
    payoff => [ ['a','b'], ['c','d'] ]
);
isa_ok $g, 'Game::Theory::TwoPersonMatrix', 'symbolic';
is $g->s_expected_payoff(), 'p * q * a + p * 1 - q * b + 1 - p * q * c + 1 - p * 1 - q * d', 'expected_payoff';

$g = Game::Theory::TwoPersonMatrix->new(
    1 => { 1 => '0.5', 2 => '0.5' },
    2 => { 1 => 'q', 2 => '1 - q' },
    payoff => [ [1,0], [0,1] ]
);
isa_ok $g, 'Game::Theory::TwoPersonMatrix', 'symbolic';
is $g->s_expected_payoff(), '0.5 * q * 1 + 0.5 * 1 - q * 0 + 0.5 * q * 0 + 0.5 * 1 - q * 1', 'expected_payoff';

$g = Game::Theory::TwoPersonMatrix->new(
    1 => { 1 => '0.2', 2 => '0.3', 3 => '0.5' },
    2 => { 1 => '0.1', 2 => '0.7', 3 => '0.2' },
    payoff => [ [ 0, 1,-1],
                [-1, 0, 1],
                [ 1,-1, 0],
    ]
);
isa_ok $g, 'Game::Theory::TwoPersonMatrix', '3x3';
is_deeply $g->counter_strategy(2), [ 0.2, -0.3, 0.1 ], 'player 2 counter_strategy';

$g = Game::Theory::TwoPersonMatrix->new(
    payoff => [ [0,-1],
                [2, 3] ]
);
isa_ok $g, 'Game::Theory::TwoPersonMatrix', '2x2';
is_deeply $g->saddlepoint, { '1,0' => 2 }, 'saddlepoint';

$g = Game::Theory::TwoPersonMatrix->new(
    payoff => [ [ 9,-2,-5],
                [ 5, 1,-9],
                [ 3, 2, 5],
                [-5, 0, 1] ]
);
isa_ok $g, 'Game::Theory::TwoPersonMatrix', '4x3';
is_deeply $g->saddlepoint, { '2,1' => 2 }, 'saddlepoint';

$g = Game::Theory::TwoPersonMatrix->new(
    payoff => [ [2,2],
                [0,4],
                [1,6],
                [3,7] ]
);
isa_ok $g, 'Game::Theory::TwoPersonMatrix', '4x2';
is_deeply $g->saddlepoint, { '3,0' => 3 }, 'saddlepoint';

$g = Game::Theory::TwoPersonMatrix->new(
    payoff => [ [4,6,4,12],
                [-8,-9,3,2] ]
);
isa_ok $g, 'Game::Theory::TwoPersonMatrix', '4x2';
is_deeply $g->saddlepoint, { '0,0' => 4, '0,2' => 4 }, 'saddlepoint';

$g = Game::Theory::TwoPersonMatrix->new(
    payoff => [ [5,-2],
                [1, 4] ]
);
isa_ok $g, 'Game::Theory::TwoPersonMatrix', '2x2';
is_deeply $g->oddments, [ [ 0.3, 0.7 ], [ 0.6, 0.4 ] ], 'oddments';

$g = Game::Theory::TwoPersonMatrix->new(
    1 => { 1 => .1, 2 => .2, 3 => .3 },
    2 => { 1 => .1, 2 => .2, 3 => .3 },
    payoff => [ [-5, 4, 6],
                [ 3,-2, 2],
                [ 2,-3, 1] ]
);
isa_ok $g, 'Game::Theory::TwoPersonMatrix', '3x3';
is_deeply $g->row_reduce, [ [-5,4,6],[3,-2,2] ], 'row_reduce';
is_deeply $g->col_reduce, [ [-5,4],[3,-2] ], 'col_reduce';

$g = Game::Theory::TwoPersonMatrix->new(
    1 => { 1 => .1, 2 => .2, 3 => .3, 4 => .4 },
    2 => { 1 => .1, 2 => .2, 3 => .3, 4 => .4 },
    payoff => [ [ 3,-2, 2, 1],
                [ 1,-2, 2, 0],
                [ 0, 6, 0, 7],
                [-1, 5, 0, 8] ]
);
isa_ok $g, 'Game::Theory::TwoPersonMatrix', '4x4';
is_deeply $g->col_reduce, [ [3,-2,2 ],[1,-2,2],[0,6,0],[-1,5,0] ], 'col_reduce';
is_deeply $g->row_reduce, [ [3,-2,2],[0,6,0] ], 'row_reduce';
is_deeply $g->col_reduce, [ [-2,2],[6,0] ], 'col_reduce';

$g = Game::Theory::TwoPersonMatrix->new(
    payoff => [ [3,2,6,2],
                [5,4,3,4],
                [1,2,3,1] ]
);
isa_ok $g, 'Game::Theory::TwoPersonMatrix', '3x4';
is_deeply $g->mm_tally, {
    1 => { strategy => [0,1,0], value => 3 },
    2 => { strategy => [0,1,0,1], value => 4 }
}, 'mm_tally';

$g = Game::Theory::TwoPersonMatrix->new(
    payoff1 => [ [2,3],[2,1] ],
    payoff2 => [ [3,5],[2,3] ],
);
isa_ok $g, 'Game::Theory::TwoPersonMatrix', '2x2';
is_deeply $g->mm_tally, {
    1 => { strategy => [1,0], value => 2 },
    2 => { strategy => [0,1], value => 3 }
}, 'mm_tally';

# Prisoners' dilemma
$g = Game::Theory::TwoPersonMatrix->new(
    payoff1 => [ [-5,-15],[0,-10] ],
    payoff2 => [ [-5,0],[-15,-10] ],
);
isa_ok $g, 'Game::Theory::TwoPersonMatrix', '2x2';
is_deeply $g->pareto_optimal, { "0,0" => [-5,-5] }, 'pareto_optimal';

$g = Game::Theory::TwoPersonMatrix->new(
    payoff1 => [ [2,3],[2,1] ],
    payoff2 => [ [3,5],[2,3] ],
);
isa_ok $g, 'Game::Theory::TwoPersonMatrix', '2x2';
is_deeply $g->pareto_optimal, { "0,0" => [2,3], "0,1" => [3,5] }, 'pareto_optimal';

$g = Game::Theory::TwoPersonMatrix->new(
    payoff1 => [ [5,3,8,2],[6,5,7,1],[7,4,6,0] ],
    payoff2 => [ [2,0,1,3],[3,4,4,1],[5,6,8,2] ],
);
isa_ok $g, 'Game::Theory::TwoPersonMatrix', '4x3';
is_deeply $g->nash, { "0,3" => [2,3], "1,1" => [5,4] }, 'nash';

$g = Game::Theory::TwoPersonMatrix->new(
    payoff1 => [ [2,1],[1,2] ],
    payoff2 => [ [1,2],[2,1] ],
);
isa_ok $g, 'Game::Theory::TwoPersonMatrix', '2x2';
is_deeply $g->nash, undef, 'nash';

$g = Game::Theory::TwoPersonMatrix->new(
    payoff1 => [ [-1,0],[0,0] ],
    payoff2 => [ [-1,-1],[-1,-1] ],
);
isa_ok $g, 'Game::Theory::TwoPersonMatrix', '2x2';
is_deeply $g->nash, { "0,1" => [0,-1], "1,0" => [0,-1], "1,1" => [0,-1] }, 'nash';

# Prisoners' dilemma
$g = Game::Theory::TwoPersonMatrix->new(
    payoff1 => [ [3,0],[5,1] ],
    payoff2 => [ [3,5],[0,1] ],
);
isa_ok $g, 'Game::Theory::TwoPersonMatrix', '2x2';
is_deeply $g->nash, { "1,1" => [1,1] }, 'nash';

# Battle of the sexes
$g = Game::Theory::TwoPersonMatrix->new(
    payoff1 => [ [1,0],[0,2] ],
    payoff2 => [ [2,0],[0,1] ],
);
isa_ok $g, 'Game::Theory::TwoPersonMatrix', '2x2';
is_deeply $g->nash, { "0,0" => [1,2], "1,1" => [2,1] }, 'nash';

$g = Game::Theory::TwoPersonMatrix->new(
    1 => { 1 => '0.2', 2 => '0.8' },
    2 => { 1 => '0.3', 2 => '0.7' },
    payoff1 => [ [5,0], [-1,2] ],
    payoff2 => [ [5,0], [-1,2] ],
);
isa_ok $g, 'Game::Theory::TwoPersonMatrix', '2x2';
is_deeply $g->expected_payoff(), [1.18, 1.18], 'expected_payoff';

$g = Game::Theory::TwoPersonMatrix->new(
    1 => { 1 => '0.5', 2 => '0.5' },
    2 => { 1 => '0.4', 2 => '0.6' },
    payoff1 => [ [3,2],[0,4] ],
    payoff2 => [ [2,1],[3,4] ],
);
isa_ok $g, 'Game::Theory::TwoPersonMatrix', '2x2';
is_deeply $g->expected_payoff(), [2.4, 2.5], 'expected_payoff';

$g = Game::Theory::TwoPersonMatrix->new(
    1 => { 1 => '0.2', 2 => '0.8' },
    2 => { 1 => '0.7', 2 => '0.3' },
    payoff1 => [ [3,2],[0,4] ],
    payoff2 => [ [2,1],[3,4] ],
);
isa_ok $g, 'Game::Theory::TwoPersonMatrix', '2x2';
is_deeply $g->counter_strategy(1), [2.7, 1.2], 'player 1 counter_strategy';
is_deeply $g->counter_strategy(2), [2.8, 3.4], 'player 2 counter_strategy';

$g = Game::Theory::TwoPersonMatrix->new(
    1 => { 1 => 0.5, 2 => 0.5 },
    2 => { 1 => 0.5, 2 => 0.5 },
    payoff => [ [1,2],[3,4] ],
);
isa_ok $g, 'Game::Theory::TwoPersonMatrix', '2x2';
like $g->play, qr/^\d$/, 'play';

$g = Game::Theory::TwoPersonMatrix->new(
    1 => { 1 => 0.5, 2 => 0.5 },
    2 => { 1 => 0.5, 2 => 0.5 },
    payoff1 => [ [0,1],[2,3] ],
    payoff2 => [ [4,5],[6,7] ],
);
isa_ok $g, 'Game::Theory::TwoPersonMatrix', '2x2';
like $g->play, qr/^\d,\d$/, 'play';

done_testing();
