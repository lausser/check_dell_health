package Classes::Device;
our @ISA = qw(Monitoring::GLPlugin::SNMP);
use strict;

sub classify {
  my $self = shift;
  if (! ($self->opts->hostname || $self->opts->snmpwalk)) {
    $self->add_unknown('either specify a hostname or a snmpwalk file');
  } else {
    $self->check_snmp_and_model();
    if (! $self->check_messages()) {
      $self->add_ok(sprintf "I am a %s", $self->{productname}) if $self->opts->verbose > 2;
      if ($self->{productname} =~ /Dell iDRAC/) {
        $self->rebless('Classes::Dell::IDRAC');
      } elsif ($self->implements_mib('IDRAC-MIB-SMIv2')) {
        $self->rebless('Classes::Dell::IDRAC');
      } elsif ($self->implements_mib('DELL-RAC-MIB')) {
        $self->rebless('Classes::Dell::RAC');
      } else {
        if (my $class = $self->discover_suitable_class()) {
          $self->rebless($class);
        } else {
          $self->rebless('Classes::Generic');
        }
      }
    }
  }
  return $self;
}


package Classes::Generic;
our @ISA = qw(Classes::Device);
use strict;

sub init {
  my $self = shift;
  if ($self->mode =~ /something specific/) {
  } else {
    bless $self, 'Monitoring::GLPlugin::SNMP';
    $self->no_such_mode();
  }
}
