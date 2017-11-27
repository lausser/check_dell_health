package Classes::Dell::IDRAC;
our @ISA = qw(Classes::Device);
use strict;

sub init {
  my $self = shift;
  if ($self->mode =~ /device::hardware::health/) {
    $self->analyze_and_check_environmental_subsystem('Classes::Dell::IDRAC::Components::EnvironmentalSubsystem');
  } else {
    $self->no_such_mode();
  }
}

sub pretty_sysdesc {
  my ($self) = @_;
  $self->get_snmp_objects('IDRAC-MIB-SMIv2', qw(racShortName
      racFirmwareVersion systemModelName));
  return sprintf "%s@%s (FW: %s)", $self->{racShortName},
      $self->{systemModelName}, $self->{racFirmwareVersion};
}
