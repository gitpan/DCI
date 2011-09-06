package TEST::DCI::Context;
use strict;
use warnings;

use Fennec;

our $CLASS;

BEGIN {
    $CLASS = 'DCI::Context';
    require_ok $CLASS;

    $INC{'MyData.pm'}    = __FILE__;
    $INC{'CastA.pm'}     = __FILE__;
    $INC{'CastB.pm'}     = __FILE__;
    $INC{'MyContext.pm'} = __FILE__;
}

{
    package MyData;
    use strict;
    use warnings;
    sub new {
        my $class = shift;
        my ($text) = @_;
        return bless( \$text, $class );
    }

    sub text {
        my $self = shift;
        return $$self;
    }

    package CastA;
    use strict;
    use warnings;
    use DCI::Cast;
    depends_on qw/text/;

    package CastB;
    use strict;
    use warnings;
    use DCI::Cast;
    depends_on qw/text/;

    sub cat {
        my $self = shift;
        return $self->CONTEXT->foo->text . $self->text;
    }
}

{
    package MyContext;
    use strict;
    use warnings;

    use DCI::Context;

    cast foo => 'CastA', bar => 'CastB';

    sub run {
        my $self = shift;
        $self->bar->cat();
    }

    sugar 'my_context';
}

tests main => sub {
    my $data_foo = MyData->new( "foo" );
    my $data_bar = MyData->new( "bar" );
    my $context = MyContext->new(
        foo => $data_foo,
        bar => $data_bar
    );

    isa_ok( $context, 'MyContext' );
    isa_ok( $context, 'DCI::Context::Base' );
    isa_ok( $context->foo, 'MyData' );
    isa_ok( $context->foo, 'CastA' );
    isa_ok( $context->bar, 'MyData' );
    isa_ok( $context->bar, 'CastB' );

    is( $context->run, "foobar", "Interactions occured properly" );
};

tests sugar => sub {
    MyContext->import();

    my $data_foo = MyData->new( "foo" );
    my $data_bar = MyData->new( "bar" );

    is(
        my_context( foo => $data_foo, bar => $data_bar ),
        "foobar",
        "Interactions occured properly (sugar)"
    );
};
