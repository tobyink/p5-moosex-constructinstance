use strict;
use warnings;
use Test::More;

{
	package Local::Other;
	use Moo;
	has param => (is => 'rw');
}

{
	package Local::Class1;
	use Moo;
	use aliased::MxCI qw( Local::Other );
	has xxx => (is => 'ro');
	sub make_other1 {
		my $self = shift;
		return Other[ param => $self->xxx ];
	}
	sub make_other2 {
		my $self = shift;
		return Other->( param => $self->xxx );
	}
	sub make_other3 {
		my $self = shift;
		return Other->new( param => $self->xxx );
	}
}

{
	package Local::Class2;
	use Moo;
	use aliased::MxCI qw( &other_class Other );
	has xxx => (is => 'ro');
	has other_class => (is => 'ro', default => sub { 'Local::Other' });
	sub make_other1 {
		my $self = shift;
		return Other[ param => $self->xxx ];
	}
	sub make_other2 {
		my $self = shift;
		return Other->( param => $self->xxx );
	}
	sub make_other3 {
		my $self = shift;
		return Other->new( param => $self->xxx );
	}
}

for my $k (qw/ Local::Class1 Local::Class2 /)
{
	for my $n (qw/ 1 2 3 /)
	{
		my $fun = "make_other$n";
		my $obj = $k->new(xxx => $n);
		my $oth = $obj->$fun;
		is($oth->param, $n, "$k\->new(...)->$fun");
	}
}

done_testing;
