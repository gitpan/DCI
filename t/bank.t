package TEST::DCI::Banking;
use strict;
use warnings;

use Fennec;

$INC{'Log.pm'} = __FILE__;
$INC{'Account.pm'} = __FILE__;
$INC{'Transfer.pm'} = __FILE__;
$INC{'Transfer/FromAccount.pm'} = __FILE__;
$INC{'Transfer/DestAccount.pm'} = __FILE__;
$INC{'Transfer/Log.pm'} = __FILE__;

{
    package Account;
    use strict;
    use warnings;

    sub new {
        my $class = shift;
        my ($balance) = @_;

        return bless( \$balance, $class );
    }

    sub add_balance {
        my $self = shift;
        my ( $delta ) = @_;
        $$self += $delta;
    }

    sub subtract_balance {
        my $self = shift;
        my ( $delta ) = @_;
        $$self -= $delta;
    }

    sub get_balance {
        my $self = shift;
        return $$self;
    }

    package Log;
    use strict;
    use warnings;

    sub new {
        my $class = shift;
        return bless( [], $class );
    }

    sub record {
        my $self = shift;
        my ($line) = @_;
        chomp( $line );
        push @$self => $line;
    }
}

{
    package Transfer;
    use strict;
    use warnings;

    use DCI::Context;

    cast from_acct => 'Transfer::FromAccount',
         dest_acct => 'Transfer::DestAccount',
         recipt    => 'Transfer::Log';

    sub start_transaction {
        my $self = shift;
        $self->recipt->record( "Transaction started" );
        # ... Stuff to record current state in case of issue
    }

    sub rollback_transaction {
        my $self = shift;
        my ( $error ) = @_;
        $self->recipt->record( "Transaction aborted: $error" );
        # ... Stuff to restore previous state
    }

    sub commit_transaction {
        my $self = shift;
        $self->recipt->record( "Transaction completed" );
        # ... Stuff to finalize state
    }

    sub transaction {
        my $self = shift;
        my ( $transfer_ammount ) = @_;

        $self->start_transaction;

        my $success = eval {
            $self->from_acct->verify_funds( $transfer_ammount );
            $self->from_acct->withdrawl( $transfer_ammount );
            $self->dest_acct->deposit( $transfer_ammount );
            1;
        };
        
        if ( $success ) {
            $self->commit_transaction;
        }
        else {
            my $error = $@;
            $self->rollback_transaction( $error );
        }
    }
}

{
    package Transfer::FromAccount;
    use strict;
    use warnings;

    use DCI::Cast;

    # Require that core class is an Account object.
    restrict_core qw/Account/;

    sub verify_funds {
        my $self = shift;
        my ( $ammount ) = @_;
        die "Origin account has insufficient funds\n" unless $ammount <= $self->get_balance;
    }

    sub withdrawl {
        my $self = shift;
        my ($ammount) = @_;
        $self->subtract_balance( $ammount );
        $self->CONTEXT->recipt->record( "$ammount removed from origin account" );
    }

    package Transfer::DestAccount;
    use strict;
    use warnings;

    use DCI::Cast;

    restrict_core qw/Account/;

    sub deposit {
        my $self = shift;
        my ($ammount) = @_;
        $self->add_balance( $ammount );
        $self->CONTEXT->recipt->record( "$ammount added to destination account" );
    }

    package Transfer::Log;
    use strict;
    use warnings;

    use DCI::Cast;

    restrict_core qw/Log/;
}

tests successful_transfer => sub {
    my $from = Account->new( 1000 );
    my $to = Account->new( 100 );
    my $log = Log->new();

    my $context = Transfer->new(
        from_acct => $from,
        dest_acct => $to,
        recipt    => $log,
    );

    $context->transaction( 500 );

    is( $from->get_balance, 500, "500 removed from origin account" );
    is( $to->get_balance,   600, "500 added to dest account" );

    is_deeply(
        $log,
        [
            'Transaction started',
            '500 removed from origin account',
            '500 added to destination account',
            'Transaction completed'
        ],
        "Recipt is accurate"
    );
};

tests failed_transfer => sub {
    my $from = Account->new( 100 );
    my $to = Account->new( 100 );
    my $log = Log->new();

    my $context = Transfer->new(
        from_acct => $from,
        dest_acct => $to,
        recipt    => $log,
    );

    $context->transaction( 500 );

    is( $from->get_balance, 100, "Transaction failed, balance uneffected" );
    is( $to->get_balance,   100, "Transaction failed, balance uneffected" );

    is_deeply(
        $log,
        [
            'Transaction started',
            'Transaction aborted: Origin account has insufficient funds',
        ],
        "Recipt is accurate"
    );

};

1;