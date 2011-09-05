package DCI::Context;
use strict;
use warnings;

use DCI::Context::Base;
use Exporter::Declare;

sub after_import {
    my $class = shift;
    my ( $importer, $specs ) = @_;
    no strict 'refs';
    push @{ "$importer\::ISA" } => 'DCI::Context::Base';
}

default_export cast => sub {
    my $class = caller;
    my $meta = $class->CONTEXT_META;
    my %roles = @_;
    for my $role ( keys %roles ) {
        my $cast = $roles{$role};
        eval "require $cast; 1" || die $@;
        no strict 'refs';
        *{"$class\::$role"} = sub { shift->{$role} };
    }
    %$meta = ( %$meta, %roles );
    return %$meta;
};

gen_default_export CONTEXT_META => sub {
    my $meta = {};
    return sub { $meta };
};

1;

__END__

=pod

=head1 NAME

DCI::Context - Implementation of the DCI concept of a context, also known as a
use-case. 

=head1 DESCRIPTION

In DCI a context defines an encapsulation of business logic, or of an
algorithm. A context should define a set of 'roles' (See L<DCI::Cast>), casts
data objects to "play" those roles, and kick off a set of interactions between
the roles that accomplishes a given task.

=head1 SYNOPSIS

This is a very trivial example. See L<DCI> for a complete example including
data, Context, and Cast classes.

    package MyContext::Divide;
    use strict;
    use warnings;

    # This will add DCI::Context::Base to @ISA for us.
    use DCI::Context;

    cast numerator   => MyContext::Divide::Numerator,
         denominator => MyContext::Divide::Denominator;

    # If we want to hook into construction, this will be called just before
    # new() returns.
    sub init {
        my $self = shift;
        ...
    }

    sub do_divide {
        my $self = shift;
        return $self->numerator->value / $self->denominator->value;
    }

=head1 EXPORTS

When you use DCI::Context it imports the following functions that allow you to
manipulate metadata for the Context object.

=over 4

=item $meta = CONTEXT_META()

Get the metadata hash for this Context class.

=item $current_roles = cast( role => $cast_package, ... )

Define roles for the context object, specifying what Cast package should be
used for the role. Any number of roles may be defined, and C<cast(...)> may be called
any number of times.

C<cast()> also returns all currently defined roles.

=back

=head1 CAST CLASS/OBJECT METHODS

These are methods defined by the DCI::Context::Base package:

=over 4

=item my $context = $class->new( roleA => $data, ... )

Create a new instance of the context with the specied $data objects fulfilling
the specified roles.

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




