package DCI::Cast;
use strict;
use warnings;

use Carp qw/croak confess/;
use Exporter::Declare;
use Scalar::Util qw/blessed/;
use List::Util qw/first/;
use DCI::Cast::Base;

our $AUTOLOAD;

sub after_import {
    my $class = shift;
    my ( $importer, $specs ) = @_;
    no strict 'refs';
    push @{ "$importer\::ISA" } => 'DCI::Cast::Base';
}

gen_default_export CAST_META => sub {
    my $meta = {};
    return sub { $meta };
};

default_export depends_on => sub {
    my $class = caller;
    my $meta = $class->CAST_META;
    push @{$meta->{depends}} => @_;
    return @{$meta->{depends}};
};

default_export restrict_core => sub {
    my $class = caller;
    my $meta = $class->CAST_META;
    push @{$meta->{restrict}} => @_;
    return @{$meta->{restrict}};
};

1;

__END__

=pod

=head1 NAME

DCI::Cast - Implementation of a DCI concept of roles, named 'cast' to avoid
conflict with other concepts named 'role'.

=head1 DESCRIPTION

Most implementations of roles take the form of a mixin applied to a package at
build-time. For most cases build-time mixin is adequate. However sometimes you
want to add methods to a package which you do not control. Even worse the
instance of the object you are using may be constructed in code you don't
control making subclassing difficult. In these cases you might get a patch
applied upstream, otherwise you may need to resort to monkey patching, or your
own hacked version of the library.

DCI::Cast provides an alternate way to solve this problem. The DCI concept of
roles usually refers to method injecting at run-time. That is adding the
methods to the object when they are needed, until the task that needs them is
complete when they cease to clutter the core object. That is what a Cast object
does.

You write a cast much the same way you would write a subclass. The difference
is that you construct the cast by providing an existing instance of the object
to which you wish to apply new methods. You will then get an object that
contains the new methods you specified, as well as the original methods of the
core object. You cast can simply refer to 'self' to use the underlying core
object.

Your core object will not be contaminated by the new methods anywhere in the
code except where used under the cast. The cast will also masquerade as the
underlying object, and can be used in any code that verifies you object is of
the underlying core type. You may call any method defined in the cast, or the
core objects inheritance tree.

=head1 SYNOPSIS

See L<DCI> for a complete synopsis including Data, Context, and Cast classes.

    package MyCast;

    # This automatically adds DCI::Cast::Base to this packages @ISA.
    use DCI::Cast;

    # Require that any core object provided implement the 'foo' method
    depends_on qw/foo/;

    # Require that any core object provided be of one of these packages
    restrict_core qw/MyRoot OtherRoot/;

    # The constructor will call init with all params provided to the
    # constructor except the first argument which is the core object.
    sub init {
        my $self = shift;
        my %params = @_;
        ...
    }

    sub foobar {
        my $self = shift;
        return $self->foo() . "bar";
    }

=head1 EXPORTS

When you use DCI::Core it imports the following functions that allow you to
manipulate metadata for the Cast object.

=over 4

=item $meta = CAST_META()

Get the metadata hash for this Cast class.

=item @dependancies = depends_on( @add_dependancies )

Get/add to the methods a core object must implement for this cast.

=item @restrictions = restrict_core( @add_options )

Get/add to the classes that are allowed to act as a 'core' object.

=back

=head1 CAST CLASS/OBJECT METHODS

These are methods defined by the DCI::Cast::Base package:

=over 4

=item my $cast = $class->new( $core, %params )

Create a new instance of the cast around the core object $core. Anything in
%params will be passed to init() if a method of that name exists.

=item my $core = $cast->CORE()

Get the core object around which the cast instance is built.

=item my $context = $cast->CONTEXT()

Get the context object.

=item my $subref = $cast->can( $method_name )

Implementation of can() which will check the cast first, then the core.

=item my $bool = $cast->isa( $package_name )

Implementation of isa which will check the cast first, then the core.

=item AUTOLOAD()

Documented for completeness, do not override.

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




