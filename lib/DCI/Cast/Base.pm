package DCI::Cast::Base;
use strict;
use warnings;

use Carp qw/croak confess/;
use Scalar::Util qw/blessed weaken/;
use List::Util qw/first/;

our $AUTOLOAD;

sub CORE { shift->{CORE} }

sub CONTEXT { shift->{CONTEXT} }

sub new {
    my $class = shift;
    my ( $core, $context, %params ) = @_;

    croak "You must provide a core object for the cast" unless $core;
    croak "You must provide a context object for the cast" unless $context;

    my $core_class = blessed( $core );
    croak "Core object must be a blessed reference not '$core'" unless $core_class;

    my %need;
    for my $dep ( @{$class->CAST_META->{depends}} ) {
        $need{$dep}++ unless $core->can( $dep );
    }

    croak "Core object for cast '$class' missing these methods: " . join ', ', keys %need
        if keys %need;

    if ( my $restricts = $class->CAST_META->{restrict}) {
        croak "Core class must be one of (" . join( ', ', @$restricts) . ") not '$core_class'"
            unless first { $core->isa( $_ ) } @$restricts;
    }

    my $self = bless( { CORE => $core, CONTEXT => $context }, $class );
    weaken $self->{CONTEXT} if blessed $self->{CONTEXT} && $self->{CONTEXT}->isa( 'DCI::Context::Base' );
    $self->init( %params ) if $self->can( 'init' );

    return $self;
}

sub can {
    my $self = shift;
    return $self->SUPER::can( @_ ) || $self->CORE->can( @_ );
}

sub isa {
    my $self = shift;
    return $self->SUPER::isa( @_ ) || $self->CORE->isa( @_ );
}

sub DESTROY {
    my $self = shift;
    delete $self->{core};
    delete $self->{context};
}

sub AUTOLOAD {
    my $self = shift;
    my ( $package, $sub ) = ( $AUTOLOAD =~ m/^(.+)::([^:]+)$/ );
    $AUTOLOAD = undef;

    my $class = blessed $self;
    my $core_class = blessed $self->CORE;

    my $method = $self->CORE->can( $sub );

    croak "Neither cast '$class', nor core class '$core_class' implement method '$sub'"
        unless $method;

    # We are calling a method ont eh core object
    unshift @_ => $self->CORE;
    goto &$method;
}

1;

__END__

=pod

=head1 NAME

DCI::Cast::Base - The object from which all Casts inherit.

=head1 METHODS

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

=head1 AUTHORS

Chad Granum L<exodist7@gmail.com>

=head1 COPYRIGHT

Copyright (C) 2011 Chad Granum

DCI is free software; Standard perl licence.

DCI is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE. See the license for more details.




