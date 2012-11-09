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
	use MooseX::ConstructInstance -with;
	sub new {
		bless \@_, shift;
	}
	sub make_other {
		my $self = shift;
		$self->construct_instance('Local::Other', param => $self->[0]);
	}
}

{
	package Local::Class2;
	use Moo;
	extends qw( Local::Class1 );
	around make_other => sub {
		my ($orig, $self, $class, @args) = @_;
		my $inst = $self->$orig($class, @args);
		$inst->param(2) if $inst->DOES('Local::Other');
		return $inst;
	}
}

can_ok 'Local::Class1', 'construct_instance';
ok !Local::Class1->can('import');

{
	my $obj = Local::Class1->new(3);
	my $oth = $obj->make_other;
	is($oth->param, 3);
}

{
	my $obj = Local::Class2->new(3);
	my $oth = $obj->make_other;
	is($oth->param, 2);
}

done_testing;
