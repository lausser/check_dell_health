package Classes::Dell::IDRAC;
our @ISA = qw(Classes::Device);
use strict;

sub init {
  my $self = shift;
  if ($self->mode =~ /device::hardware::health/) {
    $self->analyze_and_check_environmental_subsystem('Classes::Dell::IDRAC::Components::EnvironmentalSubsystem');
#    if ($self->implements_mib('DELL-RAC-MIB')) {
#      $self->analyze_and_check_environmental_subsystem('Classes::Dell::RAC::Components::EnvironmentalSubsystem');
#    }
  } else {
    $self->no_such_mode();
  }
}

