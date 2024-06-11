package Classes::Dell::IDRAC::Components::EnvironmentalSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my $self = shift;
  $self->get_snmp_objects('IDRAC-MIB-SMIv2', qw(racName racShortName
      racDescription racManufacturer racVersion racType racFirmwareVersion
      systemFQDN systemChassisSystemHeight systemNodeID
      globalSystemStatus systemLCDStatus  globalStorageStatus
      systemPowerState systemPowerUpTime 
      alertMessage alertCurrentStatus alertDeviceDisplayName alertChassisName
  ));
  $self->bulk_is_baeh(20);
  $self->get_snmp_tables('IDRAC-MIB-SMIv2', [
      ['chassisinformations', 'chassisInformationTable', 'Classes::Dell::IDRAC::Components::ChassisInformation'],
      #['eventlogs', 'eventLogTable', 'Classes::Dell::IDRAC::Components::EventLog'],
      ['systembioss', 'systemBIOSTable', 'Classes::Dell::IDRAC::Components::SystemBIOS'],
      ['firmwares', 'firmwareTable', 'Classes::Dell::IDRAC::Components::Firmware'],
      ['intrusions', 'intrusionTable', 'Classes::Dell::IDRAC::Components::Intrusion'],
      #['lclogs', 'lcLogTable', 'Classes::Dell::IDRAC::Components::LcLog'],
      ['powerunits', 'powerUnitTable', 'Classes::Dell::IDRAC::Components::PowerUnit'],
      ['powersupplys', 'powerSupplyTable', 'Classes::Dell::IDRAC::Components::PowerSupply'],
      #too much unknowns#['voltageprobes', 'voltageProbeTable', 'Classes::Dell::IDRAC::Components::VoltageProbe'],
      ['amperageprobes', 'amperageProbeTable', 'Classes::Dell::IDRAC::Components::AmperageProbe'],
      ['systembatterys', 'systemBatteryTable', 'Classes::Dell::IDRAC::Components::SystemBattery'],
      ['coolingunits', 'coolingUnitTable', 'Classes::Dell::IDRAC::Components::CoolingUnit'],
      ['coolingdevices', 'coolingDeviceTable', 'Classes::Dell::IDRAC::Components::CoolingDevice'],
      ['temperatureprobes', 'temperatureProbeTable', 'Classes::Dell::IDRAC::Components::TemperatureProbe'],
      ['processordevices', 'processorDeviceTable', 'Classes::Dell::IDRAC::Components::ProcessorDevice'],
      #['processordevicestatuss', 'processorDeviceStatusTable', 'Classes::Dell::IDRAC::Components::ProcessorDeviceStatus'],
      ['frus', 'fruTable', 'Classes::Dell::IDRAC::Components::Fru'],
      ['controllers', 'controllerTable', 'Classes::Dell::IDRAC::Components::Controller'],
      ['physicaldisks', 'physicalDiskTable', 'Classes::Dell::IDRAC::Components::PhysicalDisk'],
      ['enclosurefans', 'enclosureFanTable', 'Classes::Dell::IDRAC::Components::EnclosureFan'],
      ['enclosurepowersupplys', 'enclosurePowerSupplyTable', 'Classes::Dell::IDRAC::Components::EnclosurePowerSupply'],
      ['enclosuretemperatureprobes', 'enclosureTemperatureProbeTable', 'Classes::Dell::IDRAC::Components::EnclosureTemperatureProbe'],
      ['enclosuremanagementmodules', 'enclosureManagementModuleTable', 'Classes::Dell::IDRAC::Components::EnclosureManagementModule'],
      ['batterys', 'batteryTable', 'Classes::Dell::IDRAC::Components::Battery'],
      ['virtualdisks', 'virtualDiskTable', 'Classes::Dell::IDRAC::Components::VirtualDisk'],
  ]);
  $self->reset_snmp_max_msg_size();
  $self->bulk_is_baeh(0);
  $self->get_snmp_tables('IDRAC-MIB-SMIv2', [
      ['systemstates', 'systemStateTable', 'Classes::Dell::IDRAC::Components::SystemState'],
#      ['memorydevices', 'memoryDeviceTable', 'Classes::Dell::IDRAC::Components::MemoryDevice'],
  ]);
}

sub check {
  my $self = shift;
  $self->add_info(sprintf 'global system status is %s',
      $self->{globalSystemStatus});
  if ($self->{globalSystemStatus} eq "ok") {
    $self->add_ok();
  } else {
    $self->add_critical();
  }
  $self->add_info(sprintf 'global storage status is %s',
      $self->{globalStorageStatus});
  if ($self->{globalStorageStatus} eq "ok") {
    $self->add_ok();
  } else {
    $self->add_critical();
  }
  my $memfrus = {};
  foreach my $memorydevice (@{$self->{memorydevices}}) {
    # sometimes all of the memorydevices have an "unknown" status.
    # if there are corresponding frus, thenlet's take their status' instead.
    foreach my $fru (@{$self->{frus}}) {
      if ($fru->{fruFQDD} eq $memorydevice->{memoryDeviceFQDD}) {
        foreach my $key (grep {/^fru/} keys %{$fru}) {
          $memorydevice->{$key} = $fru->{$key};
        }
        $memfrus->{$fru->{flat_indices}} = 1;
      }
    }
  }
  @{$self->{frus}} = grep {
    ! exists $memfrus->{$_->{flat_indices}}
  } @{$self->{frus}};
  my $ctlfrus = {};
  foreach my $controller (@{$self->{controllers}}) {
    foreach my $fru (@{$self->{frus}}) {
      if ($fru->{fruFQDD} eq $controller->{controllerFQDD}) {
        foreach my $key (grep {/^fru/} keys %{$fru}) {
          $controller->{$key} = $fru->{$key};
        }
        $ctlfrus->{$fru->{flat_indices}} = 1;
      }
    }
  }
  @{$self->{frus}} = grep {
    ! exists $ctlfrus->{$_->{flat_indices}}
  } @{$self->{frus}};

  $self->SUPER::check();
  if (scalar(@{$self->{physicaldisks}}) == 0) {
    $self->add_ok("I SEE NO DISKS!!");
  }
  if (! $self->check_messages()) {
    $self->clear_ok();
    $self->add_ok('hardware working fine');
  } else {
    $self->clear_ok();
  }
  $self->add_ok(sprintf 'racShortName=%s', $self->{racShortName});
  $self->add_ok(sprintf 'racFirmwareVersion=%s', $self->{racFirmwareVersion});
  $self->add_ok(sprintf '%d controllers', scalar(@{$self->{controllers}}));
  $self->add_ok(sprintf '%d pdisks', scalar(@{$self->{physicaldisks}}));
  $self->add_ok(sprintf '%d vdisks', scalar(@{$self->{virtualdisks}}));
}


package Classes::Dell::IDRAC::Components::ObjectStatusEnum;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub check {
  my $self = shift;
  if ($self->{ObjectStatus} eq "ok") {
    $self->add_ok();
  } elsif ($self->{ObjectStatus} =~ /^(critical|nonRecoverable)/) {
    $self->add_critical();
  } elsif ($self->{ObjectStatus} eq "nonCritical") {
    $self->add_warning();
  } else {
    if ($self->{ObjectStatusMitigatable}) {
      $self->add_unknown_mitigation();
    } else {
      $self->add_unknown();
    }
  }
}


package Classes::Dell::IDRAC::Components::SystemState;
our @ISA = qw(Classes::Dell::IDRAC::Components::ObjectStatusEnum);
use strict;

sub check {
  my $self = shift;
  $self->add_info(sprintf 'system state (%s) status is %s',
      $self->{systemStatechassisIndex}, $self->{systemStateChassisStatus},
  );
  $self->{ObjectStatus} = $self->{systemStateChassisStatus};
  $self->SUPER::check();
}


package Classes::Dell::IDRAC::Components::ChassisInformation;
our @ISA = qw(Classes::Dell::IDRAC::Components::ObjectStatusEnum);
use strict;

sub check {
  my $self = shift;
  $self->add_info(sprintf 'chassis (%s) status is %s',
      $self->{chassisModelTypeName}, $self->{chassisStatus},
  );
  $self->{ObjectStatus} = $self->{chassisStatus};
  $self->SUPER::check();
}


package Classes::Dell::IDRAC::Components::SystemBIOS;
our @ISA = qw(Classes::Dell::IDRAC::Components::ObjectStatusEnum);
use strict;

sub check {
  my $self = shift;
  $self->add_info(sprintf 'bios (%s) status is %s/%s',
      $self->{systemBIOSIndex}, $self->{systemBIOSStateSettings},
      $self->{systemBIOSStatus},
  );
  $self->{ObjectStatus} = $self->{systemBIOSStatus};
  $self->SUPER::check();
}


package Classes::Dell::IDRAC::Components::Firmware;
our @ISA = qw(Classes::Dell::IDRAC::Components::ObjectStatusEnum);
use strict;

sub check {
  my $self = shift;
  $self->add_info(sprintf 'firmware (%s) status is %s',
      $self->{firmwareTypeName}, $self->{firmwareStatus},
  );
  $self->{ObjectStatus} = $self->{firmwareStatus};
  $self->SUPER::check();
}


package Classes::Dell::IDRAC::Components::Intrusion;
our @ISA = qw(Classes::Dell::IDRAC::Components::ObjectStatusEnum);
use strict;

sub check {
  my $self = shift;
  $self->add_info(sprintf 'intrusion (%s) status is %s, saying %s',
      $self->{intrusionLocationName}, $self->{intrusionStatus},
      $self->{intrusionReading},
  );
  $self->{ObjectStatus} = $self->{intrusionStatus};
  $self->SUPER::check();
  if ($self->{intrusionReading} ne "chassisNotBreached") {
    $self->add_warning();
  }
}


package Classes::Dell::IDRAC::Components::PowerUnit;
our @ISA = qw(Classes::Dell::IDRAC::Components::ObjectStatusEnum);
use strict;

sub check {
  my $self = shift;
  $self->add_info(sprintf 'power unit (%s) status is %s, redundancy %s',
      $self->{powerUnitName}, $self->{powerUnitStatus},
      $self->{powerUnitRedundancyStatus},
  );
  $self->{ObjectStatus} = $self->{powerUnitStatus};
  $self->SUPER::check();
  if ($self->{powerSupplyCountForRedundancy} == 0) {
    # This attribute defines the total number of power supplies
    # required for this power unit to have full redundancy
    # IMHO a value of 0 means that redundancy is not an issue at all
    $self->add_ok();
  } elsif ($self->{powerUnitRedundancyStatus} ne "full") {
    $self->add_warning();
  }
}


package Classes::Dell::IDRAC::Components::PowerSupply;
our @ISA = qw(Classes::Dell::IDRAC::Components::ObjectStatusEnum);
use strict;

sub check {
  my $self = shift;
  $self->add_info(sprintf 'power supply (%s) status is %s',
      $self->{powerSupplyLocationName}, $self->{powerSupplyStatus},
  );
  $self->{ObjectStatus} = $self->{powerSupplyStatus};
  $self->SUPER::check();
}


package Classes::Dell::IDRAC::Components::VoltageProbe;
our @ISA = qw(Classes::Dell::IDRAC::Components::ObjectStatusEnum);
use strict;

sub check {
  my $self = shift;
  $self->add_info(sprintf 'voltage probe (%s) status is %s/%s',
      $self->{voltageProbeLocationName}, $self->{voltageProbeStateSettings},
      $self->{voltageProbeStatus},
  );
  $self->{ObjectStatus} = $self->{voltageProbeStatus};
  $self->SUPER::check();
}


package Classes::Dell::IDRAC::Components::AmperageProbe;
our @ISA = qw(Classes::Dell::IDRAC::Components::ObjectStatusEnum);
use strict;

sub check {
  my $self = shift;
  $self->add_info(sprintf 'amperage probe (%s) status is %s/%s',
      $self->{amperageProbeLocationName}, $self->{amperageProbeStateSettings},
      $self->{amperageProbeStatus},
  );
  $self->{ObjectStatus} = $self->{amperageProbeStatus};
  $self->SUPER::check();
}


package Classes::Dell::IDRAC::Components::SystemBattery;
our @ISA = qw(Classes::Dell::IDRAC::Components::ObjectStatusEnum);
use strict;

sub check {
  my $self = shift;
  $self->add_info(sprintf 'system battery (%s) status is %s/%s',
      $self->{systemBatteryLocationName}, $self->{systemBatteryStateSettings},
      $self->{systemBatteryStatus},
  );
  $self->{ObjectStatus} = $self->{systemBatteryStatus};
  $self->SUPER::check();
  if ($self->{systemBatteryReading} =~ /failed/) {
    $self->add_critical();
  } elsif ($self->{systemBatteryReading} =~ /predictiveFailure/) {
    $self->add_warning_mitigation();
  }
}


package Classes::Dell::IDRAC::Components::CoolingUnit;
our @ISA = qw(Classes::Dell::IDRAC::Components::ObjectStatusEnum);
use strict;

sub check {
  my $self = shift;
  $self->add_info(sprintf 'cooling unit (%s) status is %s',
      $self->{coolingUnitName}, $self->{coolingUnitStatus},
  );
  $self->{ObjectStatus} = $self->{coolingUnitStatus};
  $self->SUPER::check();
  if ($self->{coolingUnitRedundancyStatus} ne "full") {
    $self->add_warning();
  }
}


package Classes::Dell::IDRAC::Components::CoolingDevice;
our @ISA = qw(Classes::Dell::IDRAC::Components::ObjectStatusEnum);
use strict;

sub finish {
  my $self = shift;
  if (! exists $self->{coolingDeviceLocationName}) {
    # at least once i found a table entry with just coolingDeviceFQDD
    # and nothing else
    $self->{coolingDeviceLocationName} = $self->{coolingDeviceFQDD};
    # let's hope the best
    $self->{coolingDeviceStatus} = "ok";
  }
}

sub check {
  my $self = shift;
  $self->add_info(sprintf 'cooling device (%s) status is %s',
      $self->{coolingDeviceLocationName}, $self->{coolingDeviceStatus},
  );
  $self->{ObjectStatus} = $self->{coolingDeviceStatus};
  $self->SUPER::check();
}


package Classes::Dell::IDRAC::Components::TemperatureProbe;
our @ISA = qw(Classes::Dell::IDRAC::Components::ObjectStatusEnum);
use strict;

sub check {
  my $self = shift;
  $self->add_info(sprintf 'temperature probe (%s) status is %s/%s',
      $self->{temperatureProbeLocationName}, $self->{temperatureProbeStateSettings},
      $self->{temperatureProbeStatus},
  );
  $self->{ObjectStatus} = $self->{temperatureProbeStatus};
  $self->SUPER::check();
}


package Classes::Dell::IDRAC::Components::ProcessorDevice;
our @ISA = qw(Classes::Dell::IDRAC::Components::ObjectStatusEnum);
use strict;

sub check {
  my $self = shift;
  $self->add_info(sprintf 'processor (%s) status is %s/%s',
      $self->{processorDeviceFQDD}, $self->{processorDeviceStatusState},
      $self->{processorDeviceStatus},
  );
  $self->{ObjectStatus} = $self->{processorDeviceStatus};
  $self->SUPER::check();
}


package Classes::Dell::IDRAC::Components::ProcessorDeviceStatus;
our @ISA = qw(Classes::Dell::IDRAC::Components::ObjectStatusEnum);
use strict;

package Classes::Dell::IDRAC::Components::MemoryDevice;
our @ISA = qw(Classes::Dell::IDRAC::Components::ObjectStatusEnum);
use strict;

sub check {
  my $self = shift;
  my $repaired = "";
  if ($self->{memoryDeviceStatus} eq 'unknown' &&
      exists $self->{fruInformationStatus} &&
      $self->{fruInformationStatus} eq 'ok') {
    $self->{memoryDeviceStatus} = 'ok';
    $repaired = ' (mem unknown, but fru ok)';
  }
  $self->add_info(sprintf 'memory (%s) status is %s%s',
      $self->{memoryDeviceLocationName}, $self->{memoryDeviceStatus}, $repaired,
  );
  $self->{ObjectStatus} = $self->{memoryDeviceStatus};
  $self->SUPER::check();
}


package Classes::Dell::IDRAC::Components::Fru;
our @ISA = qw(Classes::Dell::IDRAC::Components::ObjectStatusEnum);
use strict;

sub check {
  my $self = shift;
  $self->add_info(sprintf 'fru (%s) status is %s',
      $self->{fruFQDD}, $self->{fruInformationStatus},
  );
  $self->{ObjectStatus} = $self->{fruInformationStatus};
  $self->SUPER::check();
}


package Classes::Dell::IDRAC::Components::Controller;
our @ISA = qw(Classes::Dell::IDRAC::Components::ObjectStatusEnum);
use strict;

sub check {
  my $self = shift;
  my $repaired = "";
  if ($self->{controllerRollUpStatus} eq 'unknown' &&
      exists $self->{fruInformationStatus} &&
      $self->{fruInformationStatus} eq 'ok') {
    $self->{controllerRollUpStatus} = 'ok';
    $repaired = ' (ctrl unknown, but fru ok)';
  }
  $self->add_info(sprintf 'controller (%s) rollup status is %s%s',
      $self->{controllerDisplayName}, $self->{controllerRollUpStatus}, $repaired,
  );
  $self->{ObjectStatus} = $self->{controllerRollUpStatus};
  $self->{ObjectStatusMitigatable} = 1;
  $self->SUPER::check();
}


package Classes::Dell::IDRAC::Components::PhysicalDisk;
our @ISA = qw(Classes::Dell::IDRAC::Components::ObjectStatusEnum);
use strict;

sub check {
  my $self = shift;
  $self->add_info(sprintf 'physical disk (%s) status is %s/%s/%s',
      $self->{physicalDiskFQDD}, $self->{physicalDiskPowerState},
      $self->{physicalDiskState},
      $self->{physicalDiskComponentStatus},
  );
  if ($self->{physicalDiskSpareState} eq "notASpare" &&
      $self->{physicalDiskState} =~ /^(unknown|failed|offline|blocked|nonraid)$/) {
    $self->add_critical();
  } elsif ($self->{physicalDiskState} =~ /^(unknown|failed|offline|blocked|nonraid)$/) {
    $self->add_warning_mitigation();
  }
  if ($self->{physicalDiskSmartAlertIndication}) {
    $self->add_info(sprintf 'physical disk (%s) indicates s.m.a.r.t problems',
        $self->{physicalDiskFQDD},
    );
    $self->add_warning();
  }
}


package Classes::Dell::IDRAC::Components::EnclosureFan;
our @ISA = qw(Classes::Dell::IDRAC::Components::ObjectStatusEnum);
use strict;

package Classes::Dell::IDRAC::Components::EnclosurePowerSupply;
our @ISA = qw(Classes::Dell::IDRAC::Components::ObjectStatusEnum);
use strict;

package Classes::Dell::IDRAC::Components::EnclosureTemperatureProbe;
our @ISA = qw(Classes::Dell::IDRAC::Components::ObjectStatusEnum);
use strict;

package Classes::Dell::IDRAC::Components::EnclosureManagementModule;
our @ISA = qw(Classes::Dell::IDRAC::Components::ObjectStatusEnum);
use strict;

package Classes::Dell::IDRAC::Components::Battery;
our @ISA = qw(Classes::Dell::IDRAC::Components::ObjectStatusEnum);
use strict;

sub check {
  my $self = shift;
  $self->add_info(sprintf 'battery %d (%s) status is %s/%s',
      $self->{batteryNumber}, $self->{batteryDisplayName},
      $self->{batteryState}, $self->{batteryComponentStatus},
  );
  if ($self->{batteryState} eq "ready") {
    $self->add_ok();
  } elsif ($self->{batteryState} =~ /(degraded|charging|belowThreshold)/) {
    $self->add_warning();
  } elsif ($self->{batteryState} =~ /(unknown|missing)/) {
    $self->add_unknown();
  } else {
    $self->add_critical();
  }
}

package Classes::Dell::IDRAC::Components::VirtualDisk;
our @ISA = qw(Classes::Dell::IDRAC::Components::ObjectStatusEnum);
use strict;

sub check {
  my $self = shift;
  $self->add_info(sprintf 'virtual disk (%s) status is %s/%s',
      $self->{virtualDiskFQDD},
      $self->{virtualDiskState},
      $self->{virtualDiskComponentStatus},
  );
  if ($self->{virtualDiskState} eq "online") {
    $self->add_ok();
  } elsif ($self->{virtualDiskState} =~ /(degraded)/) {
    $self->add_warning();
  } elsif ($self->{virtualDiskState} =~ /(failed)/) {
    $self->add_critical();
  } else {
    $self->add_unknown();
  }
  if (defined $self->{virtualDiskRemainingRedundancy} &&
      ! $self->{virtualDiskRemainingRedundancy} &&
      $self->{virtualDiskLayout} ne "r0") {
    $self->add_warning_mitigation(sprintf '%s lost redundancy',
        $self->{virtualDiskFQDD});
  }
}

