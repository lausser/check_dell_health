package Classes::Dell::10892::Components::EnvironmentalSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my ($self) = @_;
  #$self->{powersupply_subsystem} =
  #    Classes::Dell::10892::Components::PowersupplySubsystem->new();
  #$self->{fan_subsystem} =
  #    Classes::Dell::10892::Components::FanSubsystem->new();
  $self->{temperature_subsystem} =
      Classes::Dell::10892::Components::TemperatureSubsystem->new();
  #$self->{module_subsystem} =
  #    Classes::Dell::10892::Components::ModuleSubsystem->new();
}

sub check {
  my ($self) = @_;
  #$self->{powersupply_subsystem}->check();
  #$self->{fan_subsystem}->check();
  $self->{temperature_subsystem}->check();
  #$self->{module_subsystem}->check();
  $self->reduce_messages("hardware working fine");
}

sub dump {
  my ($self) = @_;
  #$self->{powersupply_subsystem}->dump();
  #$self->{fan_subsystem}->dump();
  $self->{temperature_subsystem}->dump();
  #$self->{module_subsystem}->dump();
}

1;
