package Classes::Dell::RAC::Components::EnvironmentalSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my $self = shift;
  $self->get_snmp_objects('DELL-RAC-MIB', qw(drsProductName drsProductDescription
      drsProductManufacturer drsProductVersion drsProductChassisName
      drsProductType drsProductChassisModel
      drsGlobalSystemStatus drsGlobalCurrStatus drsIOMCurrStatus
      drsKVMCurrStatus drsRedCurrStatus drsPowerCurrStatus drsFanCurrStatus
      drsBladeCurrStatus drsTempCurrStatus drsCMCCurrStatus
      drsChassisFrontPanelAmbientTemperature drsCMCAmbientTemperature drsCMCProcessorTemperature
      drsGlobalPrevStatus drsIOMPrevStatus drsKVMPrevStatus drsRedPrevStatus drsPowerPrevStatus
      drsFanPrevStatus drsBladePrevStatus drsTempPrevStatus drsCMCPrevStatus 
  ));
  $self->get_snmp_tables('DELL-RAC-MIB', [
      ['cmcpowers', 'drsCMCPowerTable', 'Classes::Dell::RAC::Components::drsCMCPower'],
      ['cmcpsus', 'drsCMCPSUTable', 'Classes::Dell::RAC::Components::drsCMCPSU'],
      ['cmcservers', 'drsCMCServerTable', 'Classes::Dell::RAC::Components::drsCMCServer'],
  ]);
}

sub check {
  my $self = shift;
  foreach my $status (qw(drsBladeCurrStatus drsCMCCurrStatus drsFanCurrStatus
      drsGlobalCurrStatus drsGlobalSystemStatus drsIOMCurrStatus
      drsKVMCurrStatus drsPowerCurrStatus drsRedCurrStatus drsTempCurrStatus)) {
    next if ! $self->{$status};
    $self->add_info(sprintf '%s is %s', $status, $self->{$status});
    if ($self->{$status} ne 'ok') {
      $self->add_critical();
    } else {
      $self->add_ok();
    }
  }
  if (! $self->check_messages()) {
    $self->clear_ok();
    $self->add_ok('hardware working fine');
  } else {
    $self->clear_ok();
  }
  $self->add_ok(sprintf 'drsProductChassisModel=%s', $self->{drsProductChassisModel})
      if $self->{drsProductChassisModel};
  $self->add_ok(sprintf 'drsProductType=%s', $self->{drsProductType})
      if $self->{drsProductType};
  $self->add_ok(sprintf 'drsProductVersion=%s', $self->{drsProductVersion})
      if $self->{drsProductVersion};
}


package Classes::Dell::RAC::Components::drsCMCPower;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

package Classes::Dell::RAC::Components::drsCMCPSU;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

package Classes::Dell::RAC::Components::drsCMCServer;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

