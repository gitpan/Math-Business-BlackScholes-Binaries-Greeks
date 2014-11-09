package Math::Business::BlackScholes::Binaries::Greeks::Vega;
use strict; use warnings;

our $VERSION = '0.02';

=head1 NAME 

Math::Business::BlackScholes::Binaries::Greeks::Vega

=head1 DESCRIPTION

Gets the Vega for different options, Vanilla and Foreign for all our bet types

=cut

=head1 SUBROUTINES

See L<Math::Business::BlackScholes::Binaries::Greeks>

=cut

use Math::CDF qw( pnorm );
use Math::Trig;
use Math::Business::BlackScholes::Binaries;
use Math::Business::BlackScholes::Binaries::Greeks::Math qw( dgauss );

sub vanilla_call {
    my ( $S, $K, $t, $r_q, $mu, $vol ) = @_;

    my $d1 =
      ( log( $S / $K ) + ( $mu + $vol * $vol / 2.0 ) * $t ) /
      ( $vol * sqrt($t) );
    my $vega = $S * sqrt($t) * exp( ( $mu - $r_q ) * $t ) * dgauss($d1);
    return $vega;
}

sub vanilla_put {
    my ( $S, $K, $t, $r_q, $mu, $vol ) = @_;

    # Same as vega of vanilla call
    return vanilla_call( $S, $K, $t, $r_q, $mu, $vol );
}

sub call {
    my ( $S, $U, $t, $r_q, $mu, $vol ) = @_;

    my $d1 =
      ( log( $S / $U ) + ( $mu + $vol * $vol / 2.0 ) * $t ) /
      ( $vol * sqrt($t) );
    my $d2   = $d1 - $vol * sqrt($t);
    my $vega = -exp( -$r_q * $t ) * dgauss($d2) * $d1 / $vol;
    return $vega;
}

sub put {
    my ( $S, $D, $t, $r_q, $mu, $vol ) = @_;

    my $d1 =
      ( log( $S / $D ) + ( $mu + $vol * $vol / 2.0 ) * $t ) /
      ( $vol * sqrt($t) );
    my $d2   = $d1 - $vol * sqrt($t);
    my $vega = exp( -$r_q * $t ) * dgauss($d2) * $d1 / $vol;
    return $vega;
}

sub expirymiss {
    my ( $S, $U, $D, $t, $r_q, $mu, $vol ) = @_;

    return call( $S, $U, $t, $r_q, $mu, $vol ) +
      put( $S, $D, $t, $r_q, $mu, $vol );
}

sub expiryrange {
    my ( $S, $U, $D, $t, $r_q, $mu, $vol ) = @_;

    return -1 * expirymiss( $S, $U, $D, $t, $r_q, $mu, $vol );
}

sub onetouch {
    my ( $S, $U, $t, $r_q, $mu, $vol, $w ) = @_;

    if ( not defined $w ) {
        $w = 0;
    }

    my $sqrt_t = sqrt($t);

    my $theta = ( $mu / $vol ) + ( 0.5 * $vol );

    my $theta_ = ( $mu / $vol ) - ( 0.5 * $vol );

    my $v_ = sqrt( ( $theta_ * $theta_ ) + ( 2 * ( 1 - $w ) * $r_q ) );

    my $e = ( log( $S / $U ) - ( $vol * $v_ * $t ) ) / ( $vol * $sqrt_t );

    my $e_ = ( -log( $S / $U ) - ( $vol * $v_ * $t ) ) / ( $vol * $sqrt_t );

    my $eta = ( $S > $U ) ? 1 : -1;

    my $pa_e =
      ( log( $U / $S ) / ( $vol * $vol * $sqrt_t ) ) +
      ( ( $theta_ * $theta ) / ( $vol * $v_ ) * $sqrt_t );
    my $pa_e_ =
      ( -log( $U / $S ) / ( $vol * $vol * $sqrt_t ) ) +
      ( ( $theta_ * $theta ) / ( $vol * $v_ ) * $sqrt_t );
    my $A =
      -( $theta + $theta_ + ( $theta_ * $theta / $v_ ) + $v_ ) /
      ( $vol * $vol );
    my $A_ =
      -( $theta + $theta_ - ( $theta_ * $theta / $v_ ) - $v_ ) /
      ( $vol * $vol );

    my $part1 =
      pnorm( -$eta * $e ) * $A * log( $U / $S ) - $eta * dgauss($e) * $pa_e;
    my $part2 =
      pnorm( $eta * $e_ ) * $A_ * log( $U / $S ) + $eta * dgauss($e_) * $pa_e_;
    my $vega =
      ( ( $U / $S )**( ( $theta_ + $v_ ) / $vol ) ) * $part1 +
      ( ( $U / $S )**( ( $theta_ - $v_ ) / $vol ) ) * $part2;

    return $vega * exp( -$w * $r_q * $t );
}

sub notouch {
    my ( $S, $U, $t, $r_q, $mu, $vol, $w ) = @_;

    # No touch bet always pay out at end
    $w = 1;

    return -1 * onetouch( $S, $U, $t, $r_q, $mu, $vol, $w );
}

sub upordown {
    my ( $S, $U, $D, $t, $r_q, $mu, $vol, $w ) = @_;

    # $w = 0, paid at hit
    # $w = 1, paid at end
    if ( not defined $w ) { $w = 0; }

    return ot_up_ko_down_pelsser_1997( $S, $U, $D, $t, $r_q, $mu, $vol, $w ) +
      ot_down_ko_up_pelsser_1997( $S, $U, $D, $t, $r_q, $mu, $vol, $w );
}

sub w_common_function_pelsser_1997 {
    my ( $S, $U, $D, $t, $r_q, $mu, $vol, $w, $eta ) = @_;

    my $pi = Math::Trig::pi;

    my $h = log( $U / $D );
    my $x = log( $S / $D );

    # $eta = 1, onetouch up knockout down
    # $eta = 0, onetouch down knockout up
    # This variable used to check stability
    if ( not defined $eta ) {
        die
"$0: (w_common_function_pelsser_1997) Wrong usage of this function for S=$S, U=$U, D=$D, t=$t, r_q=$r_q, mu=$mu, vol=$vol, w=$w. eta not defined.";
    }
    if ( $eta == 0 ) { $x = $h - $x; }

    my $r_dash = $r_q * ( 1 - $w );
    my $mu_new = $mu - ( 0.5 * $vol * $vol );
    my $mu_dash = sqrt( ( $mu_new * $mu_new ) + ( 2 * $vol * $vol * $r_dash ) );

    my $omega = ( $vol * $vol );

    my $series_part = 0;
    my $hyp_part    = 0;

    my $stability_constant =
      Math::Business::BlackScholes::Binaries::get_stability_constant_pelsser_1997(
        $S, $U, $D, $t, $r_q, $mu, $vol, $w, $eta, 1 );

    my $iterations_required =
      Math::Business::BlackScholes::Binaries::get_min_iterations_pelsser_1997(
        $S, $U, $D, $t, $r_q, $mu, $vol, $w );

    for ( my $k = 1 ; $k < $iterations_required ; $k++ ) {
        my $lambda_k_dash = (
            0.5 * (
                ( $mu_dash * $mu_dash ) / $omega +
                  ( $k * $k * $pi * $pi * $vol * $vol ) / ( $h * $h )
            )
        );

        # d{lambda_k}/dw
        my $dlambdak_domega =
          0.5 *
          ( -( $mu_new / $omega ) -
              ( ( $mu_new * $mu_new ) / ( $omega * $omega ) ) +
              ( ( $k * $k * $pi * $pi ) / ( $h * $h ) ) );

        my $beta_k = exp( -$lambda_k_dash * $t ) / $lambda_k_dash;

        # d{beta_k}/d{lambda_k}
        my $dbetak_dlambdak =
          -exp( -$lambda_k_dash * $t ) *
          ( ( $t * $lambda_k_dash + 1 ) / ( $lambda_k_dash**2 ) );

        # d{beta_k}/dw
        my $dbetak_domega = $dlambdak_domega * $dbetak_dlambdak;

        my $phi =
          ( 1.0 / ( $h * $h ) ) * ( $omega * $dbetak_domega + $beta_k ) * $k;

        $series_part += $phi * $pi * sin( $k * $pi * ( $h - $x ) / $h );

#
# For vega, the stability function is 2* $vol * $phi, for volga/vanna it is different,
# but we shall ignore for now.
#
        if ( $k == 1
            and ( not( abs( 2 * $vol * $phi ) < $stability_constant ) ) )
        {
            die
"$0: PELSSER VEGA formula for S=$S, U=$U, D=$D, t=$t, r_q=$r_q, mu=$mu, vol=$vol, w=$w, eta=$eta cannot be evaluated because PELSSER VEGA stability conditions (2 * $vol * $phi less than $stability_constant) not met. This could be due to barriers too big, volatilities too low, interest/dividend rates too high, or machine accuracy too low.";
        }
    }

    my $alpha = $mu_dash / ( $vol * $vol );
    my $dalpha_domega =
      -( ( $mu_new * $omega ) +
          ( 2 * $mu_new * $mu_new ) +
          ( 2 * $r_dash * $omega ) ) /
      ( 2 * $alpha * $omega * $omega * $omega );

# We have to handle the special case where the denominator approaches 0, see our documentation in
# quant/Documents/Breakout_bet.tex under the SVN "quant" module.
    if ( ( Math::Trig::sinh( $alpha * $h )**2 ) == 0 ) {
        $hyp_part = 0;
    }
    else {
        $hyp_part =
          ( $dalpha_domega / ( 2 * ( Math::Trig::sinh( $alpha * $h )**2 ) ) ) *
          ( ( $h + $x ) * Math::Trig::sinh( $alpha * ( $h - $x ) ) -
              ( $h - $x ) * Math::Trig::sinh( $alpha * ( $h + $x ) ) );
    }

    my $dc_domega = ( $hyp_part - $series_part ) * exp( -$r_q * $w * $t );

    return $dc_domega;
}

sub ot_up_ko_down_pelsser_1997 {
    my ( $S, $U, $D, $t, $r_q, $mu, $vol, $w ) = @_;

    my $mu_new = $mu - ( 0.5 * $vol * $vol );
    my $h      = log( $U / $D );
    my $x      = log( $S / $D );
    my $omega  = ( $vol * $vol );

    my $c =
      Math::Business::BlackScholes::Binaries::common_function_pelsser_1997( $S,
        $U, $D, $t, $r_q, $mu, $vol, $w, 1 );
    my $dc_domega =
      w_common_function_pelsser_1997( $S, $U, $D, $t, $r_q, $mu, $vol, $w, 1 );

    my $dVu_domega =
      -( ( 0.5 * $omega + $mu_new ) * ( $h - $x ) / ( $omega * $omega ) ) * $c;
    $dVu_domega += $dc_domega;
    $dVu_domega *= exp( $mu_new * ( $h - $x ) / $omega );

    return $dVu_domega * ( 2 * $vol );
}

sub ot_down_ko_up_pelsser_1997 {
    my ( $S, $U, $D, $t, $r_q, $mu, $vol, $w ) = @_;

    my $mu_new = $mu - ( 0.5 * $vol * $vol );
    my $h      = log( $U / $D );
    my $x      = log( $S / $D );
    my $omega  = ( $vol * $vol );

    my $c =
      Math::Business::BlackScholes::Binaries::common_function_pelsser_1997( $S,
        $U, $D, $t, $r_q, $mu, $vol, $w, 0 );
    my $dc_domega =
      w_common_function_pelsser_1997( $S, $U, $D, $t, $r_q, $mu, $vol, $w, 0 );

    my $dVl_domega =
      ( ( 0.5 * $omega + $mu_new ) * $x / ( $omega * $omega ) ) * $c;
    $dVl_domega += $dc_domega;
    $dVl_domega *= exp( -$mu_new * $x / $omega );

    return $dVl_domega * ( 2 * $vol );
}

sub range {
    my ( $S, $U, $D, $t, $r_q, $mu, $vol, $w ) = @_;

    # Range always pay out at end
    $w = 1;

    return -1 * upordown( $S, $U, $D, $t, $r_q, $mu, $vol, $w );
}

1;

