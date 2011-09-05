package DCI;
use strict;
use warnings;

our $VERSION = "0.002";

1;

__END__

=pod

=head1 NAME

DCI - Collection of utilities for writing perl code that fits the DCI
methodology.

=head1 DESCRIPTION

Defines the DCI concepts of B<Context> L<DCI::Context> and B<Role> L<DCI::Cast>.

The DCI concept of a 'role' differs from the concept of roles as defined by
Moose. Because of this the term 'Cast' is used by DCI to refer to DCI Roles.
This will hopefulyl avoid some confusion.

=head1 SYNOPSYS

Here we will implement a complete algorthm including Data classes, a Context
class, and Casts. We will implement a banking transfer as that is a common
example used to explain DCI.

This example is implemented in the C<t/bank.t> test if you wish to see it in
action.

=head2 THE DATA CLASSES

=head3 Account

This is an implementation of a bank account that follows the DCI principal that
Data objects should be fairly dumb.

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

=head3 Log

This is a package for a log or recipt class, also dumb.

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


=head2 THE CONTEXT (Use-Case)

This is the package for our use case, a transfer between accounts.

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


=head2 THE ROLES (CAST)

We define 3 roles, from_acct, dest_acct, and recipt.

=head3 Transfer::FromAccount

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

=head3 Transfer::DestAccount

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

=head3 Transfer::Log

    package Transfer::Log;
    use strict;
    use warnings;

    use DCI::Cast;

    restrict_core qw/Log/;

=head2 PUTTING IT ALL TOGETHER

=head3 SUCCESSFUL TRANSFER

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

=head3 FAILED TRANSFER

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

=head1 SEE ALSO

=over 4

=item L<DCI::Context>

=item L<DCI::Cast>

=back

=head1 DCI Overview

DCI Stands for Data, Context, Interactions. It attempts to solve the problems
of OOP. DCI was designed and proposed by the same guy that created the MVC
concept that has become hugely successful. The key to DCI is a seperation of
concepts:

=over 4

=item Data, what the system is.

=item Context, A use case.

=item Interactions, How objects behave within a context.

=back

The idea is to create data objects that have no algorithm or business logic at
all. These would be very simple "dumb" objects. A good example would be ORM
objects that get used in many contexts. The key is to only add methods which
make sence without any knowledge of the business logic or use cases in which
they will participate.

Once you have your data objects you then move on to a context. A context
itself can be thought of as an object. A context implements a use case, which
could be an encapsulated bit of business logic, or an algorithm. The use case
object would keep track of objects necessary to complete the task. The context
keeps track of these items by the concept of what role they will play.

In DCI the concept of a role only superficially resembles roles as they are
implemented by Moose. In Moose a role is essentially a mixin with methods that
get injected into a class as soon as the role is used, and then they remain
present for the life of the class. In DCI roles can also be thought of as
mixins, however the methods they contain should only be present in your data
object when it is used in context.

To wrap up:

=over 4

=item Data objects

Such as objects in an ORM, should not contain business or algorithm logic. Only
methods that make sence without any context belong in the data objects.

=item Context objects

Implement an algorithm by defining roles, assigning data objects to roles, and
then kicking off the interactions between the roles.

=item Roles

Collections of methods used for interactions between objects in a specific
use-case (context)

=back

=head1 DCI RESOURCES

=over 4

=item L<http://www.artima.com/articles/dci_vision.html>

=item L<http://en.wikipedia.org/wiki/Data,_Context_and_Interaction>

=item L<https://sites.google.com/a/gertrudandcope.com/www/thedciarchitecture>

=back

=head1 AUTHORS

Chad Granum L<exodist7@gmail.com>

=head1 COPYRIGHT

Copyright (C) 2011 Chad Granum

DCI is free software; Standard perl licence.

DCI is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE. See the license for more details.

