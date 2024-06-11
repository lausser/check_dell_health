package Classes::Dell::10892::Components::TemperatureSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my ($self) = @_;
  my $temp = 0;
  #$self->get_snmp_objects('MIB-DELL-10892', (qw(
  #)));
  $self->get_snmp_tables('MIB-DELL-10892', [
      ['temperatureprobes', 'temperatureProbeTable', 'Classes::Dell::10892::Components::TemperatureSubsystem::TemperatureProbe'],
  ]);
}


package Classes::Dell::10892::Components::TemperatureSubsystem::TemperatureProbe;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub finish {
  my ($self) = @_;
  $self->{temperatureProbeReading} /= 10;
  $self->{temperatureProbeLowerCriticalThreshold} /= 10;
  $self->{temperatureProbeLowerNonCriticalThreshold} /= 10;
  $self->{temperatureProbeUpperCriticalThreshold} /= 10;
  $self->{temperatureProbeUpperNonCriticalThreshold} /= 10;
}

sub check {
  my ($self) = @_;
  $self->add_info(sprintf '%s temperature is %.2fC', 
      $self->{temperatureProbeLocationName},
      $self->{temperatureProbeReading});
  $self->set_thresholds(metric => $self->{temperatureProbeLocationName}.'_temp',
      warning => $self->{temperatureProbeLowerNonCriticalThreshold}.':'.$self->{temperatureProbeUpperNonCriticalThreshold},
      critical => $self->{temperatureProbeLowerCriticalThreshold}.':'.$self->{temperatureProbeUpperCriticalThreshold},
  );
  $self->add_message($self->check_thresholds(
      metric => $self->{temperatureProbeLocationName}.'_temp',
      value => $self->{temperatureProbeReading}
  ));
  $self->add_perfdata(
      label => $self->{temperatureProbeLocationName}.'_temp',
      value => $self->{temperatureProbeReading},
  );
}

