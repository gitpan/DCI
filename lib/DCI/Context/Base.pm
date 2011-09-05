package DCI::Context::Base;
use strict;
use warnings;

use Scalar::Util qw/blessed/;
use Carp qw/croak/;

sub new {
    my $class = shift;
    my %actors = @_;

    my $self = bless( {}, $class );

    my $meta = $class->CONTEXT_META;
    for my $role ( keys %$meta ) {
        my $context = $meta->{$role};

        my $actor = $actors{$role} || croak "No actor provided for role '$role'";

        $self->{$role} = $context->new( $actors{$role}, $self );
    }

    $self->init if $self->can( 'init' );
    return $self;
}

1;

__END__

=pod

=head1 NAME

DCI::Context::Base - The object from which all Casts inherit.

=head1 METHODS

=over 4

=item my $context = $class->new( roleA => $data, ... )

Create a new instance of the context with the specied $data objects fulfilling
the specified roles.

=back

=head1 AUTHORS

Chad Granum L<exodist7@gmail.com>

=head1 COPYRIGHT

Copyright (C) 2011 Chad Granum

DCI is free software; Standard perl licence.

DCI is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE. See the license for more details.




