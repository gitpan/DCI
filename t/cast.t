package TEST::DCI::Cast;
use strict;
use warnings;

use Fennec;

our $CLASS;
BEGIN {
    $CLASS = 'DCI::Cast';
    require_ok( $CLASS );
}

{
    package MyCast;
    use strict;
    use warnings;

    use DCI::Cast;

    depends_on qw/foo bar/;

    sub baz { 'baz' }

    sub render {
        my $self = shift;
        return join( ', ', $self->foo, $self->bar, $self->baz );
    }

    package MyCastB;
    use strict;
    use warnings;

    use DCI::Cast;
    restrict_core qw/ MyBaseA /;
}

{
    package MyBaseA;
    use strict;
    use warnings;

    sub foo { 'foo' };
}

{
    package MyBaseB;
    use strict;
    use warnings;

    our @ISA =( 'MyBaseA' );

    sub bar { 'bar' };
}

tests construction => sub {
    throws_ok {
        MyCast->new( 'foo', {} );
    } qr/Core object must be a blessed reference not 'foo'/, "Need correct core";

    throws_ok {
        MyCast->new( bless( {}, 'foo' ), {} );
    } qr/Core object for cast 'MyCast' missing these methods: bar, foo/, "Dependancies";

    throws_ok {
        MyCast->new( bless( {}, 'MyBaseA' ), {} );
    } qr/Core object for cast 'MyCast' missing these methods: bar/, "Some dependancies";

    lives_ok {
        my $one = MyCast->new( bless( {}, 'MyBaseB' ), {} );
        isa_ok( $one, 'MyCast' );
        isa_ok( $one, 'DCI::Cast::Base' );
    } "Dependancies met";

    throws_ok {
        my $one = MyCastB->new( bless( {}, 'foo' ), {} );
    } qr/Core class must be one of \(MyBaseA\) not 'foo'/, "Restrict";

    lives_ok {
        my $one = MyCastB->new( bless( {}, 'MyBaseA' ), {} );
    } "Restriction ok";

    lives_ok {
        my $one = MyCastB->new( bless( {}, 'MyBaseB' ), {} );
    } "Restriction ok inherited";
};

tests use_core => sub {
    my $one = MyCast->new( bless( {}, 'MyBaseB' ), {} );
    is( $one->render, "foo, bar, baz", "Found all methods" );
    isa_ok( $one->CAST_META, 'HASH' );
    isa_ok( $one->CORE, 'MyBaseB' );

    is( $one->foo, 'foo', 'Used method from core->SUPER' );
    is( $one->bar, 'bar', 'Used method from core' );
    is( $one->baz, 'baz', 'Used method from cast' );

    throws_ok {
        $one->foobarbaz();
    } qr/Neither cast 'MyCast', nor core class 'MyBaseB' implement method 'foobarbaz'/,
        "Invalid method";

    can_ok( $one, qw/CORE foo bar baz/ );
    isa_ok( $one, 'MyCast' );
    isa_ok( $one, 'MyBaseA' );
    isa_ok( $one, 'MyBaseB' );
};
