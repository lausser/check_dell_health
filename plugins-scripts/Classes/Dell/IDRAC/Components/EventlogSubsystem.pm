package Classes::Dell::IDRAC::Components::EventlogSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;
use Date::Manip::Date;

sub init {
  my $self = shift;
  $self->opts->override_opt('lookback', 18000) if ! $self->opts->lookback;
  $self->get_snmp_objects('IDRAC-MIB-SMIv2', qw(numEventLogEntries numLCLogEntries));
  $self->bulk_is_baeh(20);
  my $lookback = time - $self->opts->lookback;
  $self->get_snmp_tables('IDRAC-MIB-SMIv2', [
      ['eventlogs', 'eventLogTable', 'Classes::Dell::IDRAC::Components::EventLog', sub { my ($o) = @_; return ($o->{eventLogDate} >= $lookback && $o->{eventLogSeverityStatus} ne "ok") ? 1 : 0 } ],
      #['lclogs', 'lcLogTable', 'Classes::Dell::IDRAC::Components::LcLog'],
  ]);
  $self->reset_snmp_max_msg_size();
  $self->bulk_is_baeh(0);
}


package Classes::Dell::IDRAC::Components::EventLog;
our @ISA = qw(Classes::Dell::IDRAC::Components::ObjectStatusEnum);
use strict;

sub finish {
  my $self = shift;
  # eventLogDateName: 20170925072315.000000+060
  my $date = new Date::Manip::Date;
  $date->parse_format("%Y%m%d%H%M%S", $self->{eventLogDateName});
  $self->{eventLogDate} = $date->printf("%s");
  $self->{eventLogDateLocal} = scalar localtime $self->{eventLogDate};
}

sub check {
  my $self = shift;
  $self->add_info(sprintf '%s event log [%s] %s',
      $self->{eventLogSeverityStatus},
      $self->{eventLogDateLocal}, $self->{eventLogRecord}
  );
  $self->{ObjectStatus} = $self->{eventLogSeverityStatus};
  $self->SUPER::check();
}


package Classes::Dell::IDRAC::Components::LcLog;
our @ISA = qw(Classes::Dell::IDRAC::Components::ObjectStatusEnum);
use strict;
# live cycle. keine ahnung, was das soll.
