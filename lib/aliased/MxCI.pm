package aliased::MxCI;

use strict;
use warnings;

use Carp;
use Devel::Caller qw( caller_args called_as_method );

sub import
{
	my ($me, $pkg, $alias) = @_;
	my $caller = caller;
	my $method;
	if ($pkg =~ /^[&](.+)/)
	{
		$method = $1;
		$pkg    = undef;
	}
	
	unless ($alias)
	{
		croak("'use aliased::MxCI q(&$method)' missing explicit alias")
			if defined $method;
		$pkg =~ /(\w+)$/ and $alias = $1;
	}
	
	my $sub = defined $method
		? sub (;$) {
			my $proto = called_as_method(1)
				? (caller_args(1))[0]
				: confess("'$alias' cannot find invocant");
			my $want = $proto->$method;
			if (ref $_[0] eq 'ARRAY') {
				return $proto->construct_instance($want, @{$_[0]});
			}
			return bless [$proto, $want], 'aliased::MxCI::Construction';
		}
		: sub (;$) {
			my $proto = called_as_method(1)
				? (caller_args(1))[0]
				: $caller;
			my $want = $pkg;
			if (ref $_[0] eq 'ARRAY') {
				return $proto->construct_instance($want, @{$_[0]});
			}
			return bless [$proto, $want], 'aliased::MxCI::Construction';
		};
	
	INSTALL: {
		no strict 'refs';
		*{"$caller\::$alias"} = $sub;
	}
	
	# Ensure that the caller provides a construct_instance method
	unless ($caller->can('construct_instance')) {
		require MooseX::ConstructInstance;
		my $import = MooseX::ConstructInstance->can('import');
		@_ = qw( MooseX::ConstructInstance -with );
		goto $import;
	}
}

{
	package aliased::MxCI::Construction;
	use overload
		q[""]  => sub { $_[0][1] },
		q[&{}] => sub { my $self = shift; sub { $self->new(@_) } },
	;
	sub new {
		my ($parent, $class) = @{+shift};
		$parent->construct_instance($class, @_);
	}
	our $AUTOLOAD;
	sub AUTOLOAD {
		my ($parent, $class) = @{+shift};
		my ($method) = ($AUTOLOAD =~ /::(\w+)$/);
		$class->$method(@_);
	}
	sub DESTROY { +return }
}

1;


__END__

=head1 NAME

aliased::MxCI - the spawn of aliased and MxCI

=head1 SYNOPSIS

   package My::Class {
      use Moose;
      use aliased::MxCI 'LWP::UserAgent';
      sub get_ua {
         return UserAgent->new;
      }
      after construct_instance => sub {
         my ($orig, $self, @args) = @_;
         my $inst = $self->$orig(@args);
         if ($inst->DOES("LWP::UserAgent")) {
            $inst->credentials("", "", "username", "password");
         }
         return $inst;
      };
   }

=head1 DESCRIPTION

This module works like L<aliased> except that it uses a bit of magic to
pass the constructor call via your object's C<construct_instance> method,
giving your object (and potentially any roles applied to your object) an
opportunity to intervene in the construction of helper objects.

The syntax for creating aliases is the same as L<aliased>'s class name
interface.

As an alternative to hard-coding class names like "LWP::UserAgent" in the
synopsis.

   package My::Class {
      use Moose;
      use aliased::MxCI '&ua_class', 'UserAgent';
      has ua_class => (is => 'ro', default => 'LWP::UserAgent');
      sub get_ua {
         return UserAgent->new;
      }
   }
   
   # LWP::UserAgent
   My::Class->new()->get_ua;
   
   # WWW::Mechanize
   My::Class->new(ua_class => 'WWW::Mechanize')->get_ua;

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=MooseX-ConstructInstance>.

=head1 SEE ALSO

L<Moose>,
L<aliased>,
L<MooseX::ConstructInstance>,
L<MooseX::RelatedClasses>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2012 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

