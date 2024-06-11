package Classes::Dell::10892;
our @ISA = qw(Classes::Device);
use strict;

sub init {
  my $self = shift;
  if ($self->mode =~ /device::hardware::health/) {
    $self->analyze_and_check_environmental_subsystem('Classes::Dell::10892::Components::EnvironmentalSubsystem');
  } else {
    $self->no_such_mode();
  }
}

