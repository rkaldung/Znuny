# --
# Copyright (C) 2001-2017 OTRS AG, http://otrs.com/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

use strict;
use warnings;
use utf8;

use vars (qw($Self));

use Kernel::System::ObjectManager;
use Kernel::System::VariableCheck qw(:all);

# get needed objects
my $ConfigObject = $Kernel::OM->Get('Kernel::Config');

# set timezone variables
$ConfigObject->Set(
    Key   => 'TimeZone',
    Value => '+0',
);
$ConfigObject->Set(
    Key   => 'TimeZoneUser',
    Value => 1,
);

my $StatsObject               = $Kernel::OM->Get('Kernel::System::Stats');
my $QueueObject               = $Kernel::OM->Get('Kernel::System::Queue');
my $TicketObject              = $Kernel::OM->Get('Kernel::System::Ticket');
my $TimeObject                = $Kernel::OM->Get('Kernel::System::Time');
my $DynamicFieldObject        = $Kernel::OM->Get('Kernel::System::DynamicField');
my $DynamicFieldBackendObject = $Kernel::OM->Get('Kernel::System::DynamicField::Backend');

# get helper object
$Kernel::OM->ObjectParamAdd(
    'Kernel::System::UnitTest::Helper' => {
        RestoreDatabase  => 1,
        UseTmpArticleDir => 1,
    },
);
my $Helper = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');

my $RandomID = $Helper->GetRandomID();

# UTC tests
local $ENV{TZ} = 'UTC';

# create new queues
my @QueueNames;
my @QueueIDs;

for my $Count ( 1 .. 3 ) {

    my $QueueName = "Statistic-$Count-Queue-" . $RandomID;
    my $QueueID   = $QueueObject->QueueAdd(
        Name            => "Statistic-$Count-Queue-" . $RandomID,
        ValidID         => 1,
        GroupID         => 1,
        SystemAddressID => 1,
        SalutationID    => 1,
        SignatureID     => 1,
        Comment         => 'Some comment',
        UserID          => 1,
    );

    # sanity check
    $Self->True(
        $QueueID,
        "QueueAdd() successful for test - QueueID $QueueID",
    );

    push @QueueIDs,   $QueueID;
    push @QueueNames, $QueueName;
}

# create some dynamic fields
my @DynamicFieldProperties = (
    {
        Name       => "Text$RandomID",
        Label      => "Text$RandomID",
        FieldOrder => 9991,
        FieldType  => 'Text',
        Config     => {
            DefaultValue => 'Default',
        },
    },
    {
        Name       => "TextArea$RandomID",
        Label      => "TextArea$RandomID",
        FieldOrder => 9992,
        FieldType  => 'TextArea',
        Config     => {
            DefaultValue => 'Default',
        },
    },
);

my %DynamicFieldFieldConfig;

for my $DynamicFieldProperty (@DynamicFieldProperties) {
    my $FieldID = $DynamicFieldObject->DynamicFieldAdd(
        %{$DynamicFieldProperty},
        ObjectType => 'Ticket',
        ValidID    => 1,
        UserID     => 1,
        Reorder    => 0,
    );

    $DynamicFieldFieldConfig{ $DynamicFieldProperty->{Name} } = $DynamicFieldObject->DynamicFieldGet(
        ID => $FieldID,
    );
}

# define the tickets for the statistic result tests
my @Tickets = (

    # add the ticket in the first statistic queue
    # (for a time zones < '-8' this ticket was created the previous day)
    {
        TimeStamp  => '2014-10-10 08:00:00',
        TicketData => {
            Title        => 'Statistic Ticket Title',
            Queue        => $QueueNames[0],
            Lock         => 'unlock',
            Priority     => '3 normal',
            State        => 'new',
            CustomerID   => 'example + test',
            CustomerUser => 'customer@example.com',
            OwnerID      => 1,
            UserID       => 1,
        },
    },

    # add the ticket in the first statistic queue
    # (for a time zones < '-11' this ticket was created the previous day)
    {
        TimeStamp  => '2014-12-10 11:00:00',
        TicketData => {
            Title        => 'Statistic Ticket Title',
            Queue        => $QueueNames[0],
            Lock         => 'unlock',
            Priority     => '3 normal',
            State        => 'new',
            CustomerID   => '123465',
            CustomerUser => 'customer@example.com',
            OwnerID      => 1,
            UserID       => 1,
        },
    },

    # add the ticket in the first statistic queue
    # (for a time zones >= '+3' this ticket was created the next day)
    {
        TimeStamp  => '2015-07-31 21:10:00',
        TicketData => {
            Title        => 'Statistic Ticket Title',
            Queue        => $QueueNames[0],
            Lock         => 'unlock',
            Priority     => '3 normal',
            State        => 'new',
            CustomerID   => '123465',
            CustomerUser => 'customer@example.com',
            OwnerID      => 1,
            UserID       => 1,
        },
    },

    # add the ticket in the first statistic queue
    # (for a time zones >= '+5' this ticket was created the next day)
    {
        TimeStamp  => '2015-08-09 19:15:00',
        TicketData => {
            Title        => 'Statistic Ticket Title',
            Queue        => $QueueNames[0],
            Lock         => 'unlock',
            Priority     => '3 normal',
            State        => 'new',
            CustomerID   => '123465',
            CustomerUser => 'customer@example.com',
            OwnerID      => 1,
            UserID       => 1,
        },
    },

    # add the ticket in the first statistic queue
    # (for a time zones >= '+4' this ticket was created the next day)
    {
        TimeStamp  => '2015-08-10 20:00:00',
        TicketData => {
            Title        => 'Statistic Ticket Title',
            Queue        => $QueueNames[0],
            Lock         => 'unlock',
            Priority     => '3 normal',
            State        => 'new',
            CustomerID   => '123465',
            CustomerUser => 'customer@example.com',
            OwnerID      => 1,
            UserID       => 1,
        },
    },

    # add the ticket in the first statistic queue
    # (for a time zones < '-10' this ticket was created the previous day)
    {
        TimeStamp  => '2015-08-10 10:00:00',
        TicketData => {
            Title        => 'Statistic Ticket Title',
            Queue        => $QueueNames[0],
            Lock         => 'unlock',
            Priority     => '3 normal',
            State        => 'new',
            CustomerID   => '123465',
            CustomerUser => 'customer@example.com',
            OwnerID      => 1,
            UserID       => 1,
        },
    },

    # add the ticket in the third statistic queue
    # (for a time zones = '+12' this ticket was created the next day)
    {
        TimeStamp  => '2015-08-11 12:00:00',
        TicketData => {
            Title         => 'Statistic Ticket Title',
            Queue         => $QueueNames[2],
            Lock          => 'unlock',
            Priority      => '3 normal',
            State         => 'new',
            CustomerID    => '123465',
            CustomerUser  => 'customer@example.com',
            OwnerID       => 1,
            UserID        => 1,
            DynamicFields => {
                TextArea => 'Example 123',
            },
        },
    },

    # add the ticket in the second statistic queue
    # (for a time zones >= '+6' this ticket was created the next day)
    {
        TimeStamp  => '2015-09-10 18:00:00',
        TicketData => {
            Title        => 'Statistic Ticket Title',
            Queue        => $QueueNames[1],
            Lock         => 'unlock',
            Priority     => '3 normal',
            State        => 'new',
            CustomerID   => '123465',
            CustomerUser => 'customer@example.com',
            OwnerID      => 1,
            UserID       => 1,
        },
    },

    # add the ticket in the third statistic queue
    # (for a time zones = '+12' this ticket was created the next day)
    {
        TimeStamp  => '2014-09-20 12:00:00',
        TicketData => {
            Title        => 'Statistic Ticket Title',
            Queue        => $QueueNames[2],
            Lock         => 'unlock',
            Priority     => '3 normal',
            State        => 'new',
            CustomerID   => '123465',
            CustomerUser => 'customer@example.com',
            OwnerID      => 1,
            UserID       => 1,
        },
    },

    # add the ticket in the second statistic queue
    # (for a time zones >= '+2' this ticket was created the next day)
    {
        TimeStamp  => '2015-08-12 22:00:00',
        TicketData => {
            Title         => 'Statistic Ticket Title',
            Queue         => $QueueNames[1],
            Lock          => 'unlock',
            Priority      => '3 normal',
            State         => 'new',
            CustomerID    => '123465',
            CustomerUser  => 'customer@example.com',
            OwnerID       => 1,
            UserID        => 1,
            DynamicFields => {
                Text     => 'Example 123',
                TextArea => 'Example 123',
            },
        },
    },
);

my @TicketIDs;

TICKET:
for my $Ticket (@Tickets) {

    # check TicketData attribute
    if ( !$Ticket->{TicketData} || ref $Ticket->{TicketData} ne 'HASH' ) {

        $Self->True(
            0,
            "No TicketData found for this test ticket.",
        );
        next TICKET;
    }

    my $SystemTime = $TimeObject->TimeStamp2SystemTime(
        String => $Ticket->{TimeStamp},
    );

    # set the fixed time
    $Helper->FixedTimeSet($SystemTime);

    # create the ticket
    my $TicketID = $TicketObject->TicketCreate(
        %{ $Ticket->{TicketData} },
    );

    if ( IsHashRefWithData( $Ticket->{TicketData}->{DynamicFields} ) ) {

        for my $DynamicFieldName ( sort keys %{ $Ticket->{TicketData}->{DynamicFields} } ) {

            $DynamicFieldBackendObject->ValueSet(
                DynamicFieldConfig => $DynamicFieldFieldConfig{ $DynamicFieldName . $RandomID },
                ObjectID           => $TicketID,
                Value              => $Ticket->{TicketData}->{DynamicFields}->{$DynamicFieldName},
                UserID             => 1,
            );
        }
    }

    # sanity check
    $Self->True(
        $TicketID,
        "TicketCreate() successful for test - TicketID $TicketID",
    );

    my %TicketData = $TicketObject->TicketGet(
        TicketID => $TicketID,
        UserID   => 1,
    );

    push @TicketIDs, \%TicketData;
}
continue {
    $Helper->FixedTimeUnset();
}

# set the language to 'en' before the StatsRun
$Kernel::OM->ObjectParamAdd(
    'Kernel::Language' => {
        UserLanguage => 'en',
    },
);

# generate a dynamic matrix test statistic
my $DynamicMatrixStatID = $StatsObject->StatsAdd(
    UserID => 1,
);

# sanity check
$Self->True(
    $DynamicMatrixStatID,
    'StatsAdd() DynamicMatrix successful - StatID $DynamicMatrixStatID',
);

my $UpdateSuccess = $StatsObject->StatsUpdate(
    StatID => $DynamicMatrixStatID,
    Hash   => {
        Title        => 'Title for result tests',
        Description  => 'some Description',
        Object       => 'Ticket',
        Format       => 'CSV',
        ObjectModule => 'Kernel::System::Stats::Dynamic::Ticket',
        StatType     => 'dynamic',
        Cache        => 1,
        Valid        => 1,
    },
    UserID => 1,
);

# sanity check
$Self->True(
    $UpdateSuccess,
    'StatsUpdate() DynamicMatrix successful - StatID $DynamicMatrixStatID',
);

# generate a dynamic list test statistic
my $DynamicListStatID = $StatsObject->StatsAdd(
    UserID => 1,
);

# sanity check
$Self->True(
    $DynamicListStatID,
    'StatsAdd() for DynamicList successful - StatID $DynamicListStatID',
);

$UpdateSuccess = $StatsObject->StatsUpdate(
    StatID => $DynamicListStatID,
    Hash   => {
        Title        => 'Title for result tests',
        Description  => 'some Description',
        Object       => 'TicketList',
        Format       => 'CSV',
        ObjectModule => 'Kernel::System::Stats::Dynamic::TicketList',
        StatType     => 'dynamic',
        Cache        => 1,
        Valid        => 1,
    },
    UserID => 1,
);

# sanity check
$Self->True(
    $UpdateSuccess,
    'StatsUpdate() DynamicList successful - StatID $DynamicListStatID',
);

my @Tests = (

    # Test with a relative time period and without a defined time zone
    # Fixed TimeStamp: '2015-08-15 20:00:00'
    # TimeZone: -
    # X-Axis: 'CreateTime' with a relative period 'the last complete 7 days' and 'scale 1 day'.
    # Y-Axis: 'QueueIDs' to select only the created tickets for the test.
    # Restrictions: -
    {
        Description => 'Test stat without a time zone (last complete 7 days and scale 1 day)',
        TimeStamp   => '2015-08-15 20:00:00',
        StatsUpdate => {
            StatID => $DynamicMatrixStatID,
            Hash   => {
                UseAsXvalue => [
                    {
                        Element                   => 'CreateTime',
                        Block                     => 'Time',
                        Fixed                     => 1,
                        Selected                  => 1,
                        TimeRelativeCount         => 7,
                        TimeRelativeUpcomingCount => 0,
                        TimeRelativeUnit          => 'Day',
                        TimeScaleCount            => 1,
                        SelectedValues            => [
                            'Day',
                        ],
                    },
                ],
                UseAsValueSeries => [
                    {
                        'Element'        => 'QueueIDs',
                        'Block'          => 'MultiSelectField',
                        'Selected'       => 1,
                        'Fixed'          => 1,
                        'SelectedValues' => \@QueueIDs,
                    },
                ],
                UseAsRestriction => [],
            },
            UserID => 1,
        },
        ReferenceResultData => [
            [
                'Title for result tests 2015-08-08 00:00:00-2015-08-14 23:59:59',
            ],
            [
                'Queue',
                'Sat 8',
                'Sun 9',
                'Mon 10',
                'Tue 11',
                'Wed 12',
                'Thu 13',
                'Fri 14',
            ],
            [
                $QueueNames[0],
                0,
                1,
                2,
                0,
                0,
                0,
                0,
            ],
            [
                $QueueNames[1],
                0,
                0,
                0,
                0,
                1,
                0,
                0,
            ],
            [
                $QueueNames[2],
                0,
                0,
                0,
                1,
                0,
                0,
                0,
            ],
        ],
    },

    # Test with a relative time period (with current+upcoming) and without a defined time zone
    # Fixed TimeStamp: '2015-08-15 20:00:00'
    # TimeZone: -
    # X-Axis: 'CreateTime' with a relative period 'the last complete 7 and current+upcoming 2 days' and 'scale 1 day'.
    # Y-Axis: 'QueueIDs' to select only the created tickets for the test.
    # Restrictions: -
    {
        Description => 'Test stat without a time zone (last complete 7 and current+upcoming 2 days and scale 1 day)',
        TimeStamp   => '2015-08-15 20:00:00',
        StatsUpdate => {
            StatID => $DynamicMatrixStatID,
            Hash   => {
                UseAsXvalue => [
                    {
                        Element                   => 'CreateTime',
                        Block                     => 'Time',
                        Fixed                     => 1,
                        Selected                  => 1,
                        TimeRelativeCount         => 7,
                        TimeRelativeUpcomingCount => 2,
                        TimeRelativeUnit          => 'Day',
                        TimeScaleCount            => 1,
                        SelectedValues            => [
                            'Day',
                        ],
                    },
                ],
                UseAsValueSeries => [
                    {
                        'Element'        => 'QueueIDs',
                        'Block'          => 'MultiSelectField',
                        'Selected'       => 1,
                        'Fixed'          => 1,
                        'SelectedValues' => \@QueueIDs,
                    },
                ],
                UseAsRestriction => [],
            },
            UserID => 1,
        },
        ReferenceResultData => [
            [
                'Title for result tests 2015-08-08 00:00:00-2015-08-16 23:59:59',
            ],
            [
                'Queue',
                'Sat 8',
                'Sun 9',
                'Mon 10',
                'Tue 11',
                'Wed 12',
                'Thu 13',
                'Fri 14',
                'Sat 15',
                'Sun 16',
            ],
            [
                $QueueNames[0],
                0,
                1,
                2,
                0,
                0,
                0,
                0,
                0,
                0,
            ],
            [
                $QueueNames[1],
                0,
                0,
                0,
                0,
                1,
                0,
                0,
                0,
                0,
            ],
            [
                $QueueNames[2],
                0,
                0,
                0,
                1,
                0,
                0,
                0,
                0,
                0,
            ],
        ],
    },

    # Test with a relative time period and a time zone to get a switch in the next day
    # Fixed TimeStamp: '2015-08-15 20:00:00'
    # TimeZone: '+10'
    # X-Axis: 'CreateTime' with a relative period 'the last complete 7 days' and 'scale 1 day'.
    # Y-Axis: 'QueueIDs' to select only the created tickets for the test.
    # Restrictions: -
    {
        Description => 'Test stat with time zone +10 (last complete 7 days and scale 1 day)',
        TimeStamp   => '2015-08-15 20:00:00',
        StatsUpdate => {
            StatID => $DynamicMatrixStatID,
            Hash   => {
                TimeZone    => '+10',
                UseAsXvalue => [
                    {
                        Element                   => 'CreateTime',
                        Block                     => 'Time',
                        Fixed                     => 1,
                        Selected                  => 1,
                        TimeRelativeCount         => 7,
                        TimeRelativeUpcomingCount => 0,
                        TimeRelativeUnit          => 'Day',
                        TimeScaleCount            => 1,
                        SelectedValues            => [
                            'Day',
                        ],
                    },
                ],
                UseAsValueSeries => [
                    {
                        'Element'        => 'QueueIDs',
                        'Block'          => 'MultiSelectField',
                        'Selected'       => 1,
                        'Fixed'          => 1,
                        'SelectedValues' => \@QueueIDs,
                    },
                ],
                UseAsRestriction => [],
            },
            UserID => 1,
        },
        ReferenceResultData => [
            [
                'Title for result tests 2015-08-09 00:00:00-2015-08-15 23:59:59',
            ],
            [
                'Queue',
                'Sun 9',
                'Mon 10',
                'Tue 11',
                'Wed 12',
                'Thu 13',
                'Fri 14',
                'Sat 15',
            ],
            [
                $QueueNames[0],
                0,
                2,
                1,
                0,
                0,
                0,
                0,
            ],
            [
                $QueueNames[1],
                0,
                0,
                0,
                0,
                1,
                0,
                0,
            ],
            [
                $QueueNames[2],
                0,
                0,
                1,
                0,
                0,
                0,
                0,
            ],
        ],
    },

    # Test with a relative time period and a time zone
    # Fixed TimeStamp: '2015-08-11 08:00:00'
    # TimeZone: '+2'
    # X-Axis: 'CreateTime' with a relative period 'the last complete 24 hours' and 'scale 1 hour'.
    # Y-Axis: 'QueueIDs' to select only the created tickets in the first test queue.
    # Restrictions: -
    {
        Description => 'Test stat with time zone +2 (last complete 24 hours and scale 1 hour)',
        TimeStamp   => '2015-08-11 08:00:00',
        StatsUpdate => {
            StatID => $DynamicMatrixStatID,
            Hash   => {
                TimeZone    => '+2',
                UseAsXvalue => [
                    {
                        Element                   => 'CreateTime',
                        Block                     => 'Time',
                        Fixed                     => 1,
                        Selected                  => 1,
                        TimeRelativeCount         => 24,
                        TimeRelativeUpcomingCount => 0,
                        TimeRelativeUnit          => 'Hour',
                        TimeScaleCount            => 1,
                        SelectedValues            => [
                            'Hour',
                        ],
                    },
                ],
                UseAsValueSeries => [
                    {
                        'Element'        => 'QueueIDs',
                        'Block'          => 'MultiSelectField',
                        'Selected'       => 1,
                        'Fixed'          => 1,
                        'SelectedValues' => [
                            $QueueIDs[0],
                        ],
                    },
                ],
                UseAsRestriction => [],
            },
            UserID => 1,
        },
        ReferenceResultData => [
            [
                'Title for result tests 2015-08-10 10:00:00-2015-08-11 09:59:59',
            ],
            [
                'Queue',
                '10:00:00-10:59:59',
                '11:00:00-11:59:59',
                '12:00:00-12:59:59',
                '13:00:00-13:59:59',
                '14:00:00-14:59:59',
                '15:00:00-15:59:59',
                '16:00:00-16:59:59',
                '17:00:00-17:59:59',
                '18:00:00-18:59:59',
                '19:00:00-19:59:59',
                '20:00:00-20:59:59',
                '21:00:00-21:59:59',
                '22:00:00-22:59:59',
                '23:00:00-23:59:59',
                '00:00:00-00:59:59',
                '01:00:00-01:59:59',
                '02:00:00-02:59:59',
                '03:00:00-03:59:59',
                '04:00:00-04:59:59',
                '05:00:00-05:59:59',
                '06:00:00-06:59:59',
                '07:00:00-07:59:59',
                '08:00:00-08:59:59',
                '09:00:00-09:59:59',
            ],
            [
                $QueueNames[0],
                0,
                0,
                1,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                1,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
            ],
        ],
    },

    # Test with a relative time period and a time zone to get a switch in the previous day
    # Fixed TimeStamp: '2015-08-11 06:00:00'
    # TimeZone: '-10'
    # X-Axis: 'CreateTime' with a relative period 'the last complete 24 hours' and 'scale 1 hour'.
    # Y-Axis: 'QueueIDs' to select only the created tickets in the first test queue.
    # Restrictions: -
    {
        Description => 'Test stat with time zone -10 (last complete 24 hours and scale 1 hour)',
        TimeStamp   => '2015-08-11 06:00:00',
        StatsUpdate => {
            StatID => $DynamicMatrixStatID,
            Hash   => {
                TimeZone    => '-10',
                UseAsXvalue => [
                    {
                        Element                   => 'CreateTime',
                        Block                     => 'Time',
                        Fixed                     => 1,
                        Selected                  => 1,
                        TimeRelativeCount         => 24,
                        TimeRelativeUpcomingCount => 0,
                        TimeRelativeUnit          => 'Hour',
                        TimeScaleCount            => 1,
                        SelectedValues            => [
                            'Hour',
                        ],
                    },
                ],
                UseAsValueSeries => [
                    {
                        'Element'        => 'QueueIDs',
                        'Block'          => 'MultiSelectField',
                        'Selected'       => 1,
                        'Fixed'          => 1,
                        'SelectedValues' => [
                            $QueueIDs[0],
                        ],
                    },
                ],
                UseAsRestriction => [],
            },
            UserID => 1,
        },
        ReferenceResultData => [
            [
                'Title for result tests 2015-08-09 20:00:00-2015-08-10 19:59:59',
            ],
            [
                'Queue',
                '20:00:00-20:59:59',
                '21:00:00-21:59:59',
                '22:00:00-22:59:59',
                '23:00:00-23:59:59',
                '00:00:00-00:59:59',
                '01:00:00-01:59:59',
                '02:00:00-02:59:59',
                '03:00:00-03:59:59',
                '04:00:00-04:59:59',
                '05:00:00-05:59:59',
                '06:00:00-06:59:59',
                '07:00:00-07:59:59',
                '08:00:00-08:59:59',
                '09:00:00-09:59:59',
                '10:00:00-10:59:59',
                '11:00:00-11:59:59',
                '12:00:00-12:59:59',
                '13:00:00-13:59:59',
                '14:00:00-14:59:59',
                '15:00:00-15:59:59',
                '16:00:00-16:59:59',
                '17:00:00-17:59:59',
                '18:00:00-18:59:59',
                '19:00:00-19:59:59',
            ],
            [
                $QueueNames[0],
                0,
                0,
                0,
                0,
                1,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                1,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
            ],
        ],
    },

    # Test with a relative time period and a time zone
    # Fixed TimeStamp: '2015-08-10 12:00:00'
    # TimeZone: '-2'
    # X-Axis: 'CreateTime' with a relative period 'the last complete 120 minutes' and 'scale 1 hour'.
    # Y-Axis: 'QueueIDs' to select only the created tickets in the first test queue.
    # Restrictions: -
    {
        Description => 'Test stat with time zone -2 (last complete 120 minutes and scale 1 hour)',
        TimeStamp   => '2015-08-10 12:00:00',
        StatsUpdate => {
            StatID => $DynamicMatrixStatID,
            Hash   => {
                TimeZone    => '-2',
                UseAsXvalue => [
                    {
                        Element                   => 'CreateTime',
                        Block                     => 'Time',
                        Fixed                     => 1,
                        Selected                  => 1,
                        TimeRelativeCount         => 120,
                        TimeRelativeUpcomingCount => 0,
                        TimeRelativeUnit          => 'Minute',
                        TimeScaleCount            => 1,
                        SelectedValues            => [
                            'Hour',
                        ],
                    },
                ],
                UseAsValueSeries => [
                    {
                        'Element'        => 'QueueIDs',
                        'Block'          => 'MultiSelectField',
                        'Selected'       => 1,
                        'Fixed'          => 1,
                        'SelectedValues' => [
                            $QueueIDs[0],
                        ],
                    },
                ],
                UseAsRestriction => [],
            },
            UserID => 1,
        },
        ReferenceResultData => [
            [
                'Title for result tests 2015-08-10 08:00:00-2015-08-10 09:59:59',
            ],
            [
                'Queue',
                '08:00:00-08:59:59',
                '09:00:00-09:59:59',
            ],
            [
                $QueueNames[0],
                1,
                0,
            ],
        ],
    },

    # Test with a relative time period and a time zone
    # Fixed TimeStamp: '2015-08-09 20:00:00'
    # TimeZone: '+2'
    # X-Axis: 'CreateTime' with a relative period 'the last complete 1 hours' and 'scale 10 minutes'.
    # Y-Axis: 'QueueIDs' to select only the created tickets in the first test queue.
    # Restrictions: -
    {
        Description => 'Test stat with time zone +2 (last complete 1 hours and scale 10 minutes)',
        TimeStamp   => '2015-08-09 20:00:00',
        StatsUpdate => {
            StatID => $DynamicMatrixStatID,
            Hash   => {
                TimeZone    => '+2',
                UseAsXvalue => [
                    {
                        Element                   => 'CreateTime',
                        Block                     => 'Time',
                        Fixed                     => 1,
                        Selected                  => 1,
                        TimeRelativeCount         => 1,
                        TimeRelativeUpcomingCount => 0,
                        TimeRelativeUnit          => 'Hour',
                        TimeScaleCount            => 10,
                        SelectedValues            => [
                            'Minute',
                        ],
                    },
                ],
                UseAsValueSeries => [
                    {
                        'Element'        => 'QueueIDs',
                        'Block'          => 'MultiSelectField',
                        'Selected'       => 1,
                        'Fixed'          => 1,
                        'SelectedValues' => [
                            $QueueIDs[0],
                        ],
                    },
                ],
                UseAsRestriction => [],
            },
            UserID => 1,
        },
        ReferenceResultData => [
            [
                'Title for result tests 2015-08-09 21:00:00-2015-08-09 21:59:59',
            ],
            [
                'Queue',
                '21:00:00-21:09:59',
                '21:10:00-21:19:59',
                '21:20:00-21:29:59',
                '21:30:00-21:39:59',
                '21:40:00-21:49:59',
                '21:50:00-21:59:59',
            ],
            [
                $QueueNames[0],
                0,
                1,
                0,
                0,
                0,
                0,
            ],
        ],
    },

    # Test with a relative time period (with current+upcoming) and a time zone to get a switch in the next day
    # Fixed TimeStamp: '2015-08-12 20:00:00'
    # TimeZone: '+6'
    # X-Axis: 'CreateTime' with a relative period 'the last complete 5 and current+upcoming 1 days' and 'scale 1 day'.
    # Y-Axis: 'QueueIDs' to select only the created tickets for the test.
    # Restrictions: -
    {
        Description => 'Test stat with time zone +6 (last complete 5 and current+upcoming 1 days and scale 1 day)',
        TimeStamp   => '2015-08-12 20:00:00',
        StatsUpdate => {
            StatID => $DynamicMatrixStatID,
            Hash   => {
                TimeZone    => '+6',
                UseAsXvalue => [
                    {
                        Element                   => 'CreateTime',
                        Block                     => 'Time',
                        Fixed                     => 1,
                        Selected                  => 1,
                        TimeRelativeCount         => 5,
                        TimeRelativeUpcomingCount => 1,
                        TimeRelativeUnit          => 'Day',
                        TimeScaleCount            => 1,
                        SelectedValues            => [
                            'Day',
                        ],
                    },
                ],
                UseAsValueSeries => [
                    {
                        'Element'        => 'QueueIDs',
                        'Block'          => 'MultiSelectField',
                        'Selected'       => 1,
                        'Fixed'          => 1,
                        'SelectedValues' => \@QueueIDs,
                    },
                ],
                UseAsRestriction => [],
            },
            UserID => 1,
        },
        ReferenceResultData => [
            [
                'Title for result tests 2015-08-08 00:00:00-2015-08-13 23:59:59',
            ],
            [
                'Queue',
                'Sat 8',
                'Sun 9',
                'Mon 10',
                'Tue 11',
                'Wed 12',
                'Thu 13',
            ],
            [
                $QueueNames[0],
                0,
                0,
                2,
                1,
                0,
                0,
            ],
            [
                $QueueNames[1],
                0,
                0,
                0,
                0,
                0,
                1,
            ],
            [
                $QueueNames[2],
                0,
                0,
                0,
                1,
                0,
                0,
            ],
        ],
    },

    # Test with a relative time period and without a time zone
    # Fixed TimeStamp: '2015-08-12 20:00:00'
    # TimeZone: '0'
    # X-Axis: 'CreateTime' with a relative period 'the last complete 12 months' and 'scale 1 month'.
    # Y-Axis: 'QueueIDs' to select only the created tickets for the test.
    # Restrictions: -
    {
        Description => 'Test stat without a time zone (last complete 12 months and scale 1 month)',
        TimeStamp   => '2015-09-01 12:00:00',
        StatsUpdate => {
            StatID => $DynamicMatrixStatID,
            Hash   => {
                TimeZone    => '0',
                UseAsXvalue => [
                    {
                        Element                   => 'CreateTime',
                        Block                     => 'Time',
                        Fixed                     => 1,
                        Selected                  => 1,
                        TimeRelativeCount         => 12,
                        TimeRelativeUpcomingCount => 0,
                        TimeRelativeUnit          => 'Month',
                        TimeScaleCount            => 1,
                        SelectedValues            => [
                            'Month',
                        ],
                    },
                ],
                UseAsValueSeries => [
                    {
                        'Element'        => 'QueueIDs',
                        'Block'          => 'MultiSelectField',
                        'Selected'       => 1,
                        'Fixed'          => 1,
                        'SelectedValues' => \@QueueIDs,
                    },
                ],
                UseAsRestriction => [],
            },
            UserID => 1,
        },
        ReferenceResultData => [
            [
                'Title for result tests 2014-09-01 00:00:00-2015-08-31 23:59:59',
            ],
            [
                'Queue',
                'Sep 9',
                'Oct 10',
                'Nov 11',
                'Dec 12',
                'Jan 1',
                'Feb 2',
                'Mar 3',
                'Apr 4',
                'May 5',
                'Jun 6',
                'Jul 7',
                'Aug 8',
            ],
            [
                $QueueNames[0],
                0,
                1,
                0,
                1,
                0,
                0,
                0,
                0,
                0,
                0,
                1,
                3,
            ],
            [
                $QueueNames[1],
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                1,
            ],
            [
                $QueueNames[2],
                1,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                1,
            ],
        ],
    },

    # Test with a relative time period and a tim zone
    # Fixed TimeStamp: '2015-08-12 20:00:00'
    # TimeZone: '+3'
    # X-Axis: 'CreateTime' with a relative period 'the last complete 12 months' and 'scale 1 month'.
    # Y-Axis: 'QueueIDs' to select only the created tickets for the test.
    # Restrictions: -
    {
        Description =>
            'Test stat without a time zone (last complete 12 and current+upcoming 1 months and scale 1 month)',
        TimeStamp   => '2015-09-14 12:00:00',
        StatsUpdate => {
            StatID => $DynamicMatrixStatID,
            Hash   => {
                TimeZone    => '+3',
                UseAsXvalue => [
                    {
                        Element                   => 'CreateTime',
                        Block                     => 'Time',
                        Fixed                     => 1,
                        Selected                  => 1,
                        TimeRelativeCount         => 12,
                        TimeRelativeUpcomingCount => 1,
                        TimeRelativeUnit          => 'Month',
                        TimeScaleCount            => 1,
                        SelectedValues            => [
                            'Month',
                        ],
                    },
                ],
                UseAsValueSeries => [
                    {
                        'Element'        => 'QueueIDs',
                        'Block'          => 'MultiSelectField',
                        'Selected'       => 1,
                        'Fixed'          => 1,
                        'SelectedValues' => \@QueueIDs,
                    },
                ],
                UseAsRestriction => [],
            },
            UserID => 1,
        },
        ReferenceResultData => [
            [
                'Title for result tests 2014-09-01 00:00:00-2015-09-30 23:59:59',
            ],
            [
                'Queue',
                'Sep 9',
                'Oct 10',
                'Nov 11',
                'Dec 12',
                'Jan 1',
                'Feb 2',
                'Mar 3',
                'Apr 4',
                'May 5',
                'Jun 6',
                'Jul 7',
                'Aug 8',
                'Sep 9',
            ],
            [
                $QueueNames[0],
                0,
                1,
                0,
                1,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                4,
                0,
            ],
            [
                $QueueNames[1],
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                1,
                1,
            ],
            [
                $QueueNames[2],
                1,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                1,
                0,
            ],
        ],
    },

    # Test with a absolute time period and a time zone
    # Fixed TimeStamp: '2015-08-15 20:00:00'
    # TimeZone: '-8'
    # X-Axis: 'CreateTime' with a absolute period '2015-08-10 00:00:00 - 2015-08-15 23:59:59' and 'scale 1 day'.
    # Y-Axis: 'QueueIDs' to select only the created tickets for the test.
    # Restrictions: -
    {
        Description => 'Test stat with time zone -8 (time period 2015-08-10 00:00:00 - 2015-08-15 23:59:59)',
        TimeStamp   => '2015-08-15 20:00:00',
        StatsUpdate => {
            StatID => $DynamicMatrixStatID,
            Hash   => {
                TimeZone    => '-8',
                UseAsXvalue => [
                    {
                        Element        => 'CreateTime',
                        Block          => 'Time',
                        Fixed          => 1,
                        Selected       => 1,
                        TimeStart      => '2015-08-10 00:00:00',
                        TimeStop       => '2015-08-15 23:59:59',
                        TimeScaleCount => 1,
                        SelectedValues => [
                            'Day',
                        ],
                    },
                ],
                UseAsValueSeries => [
                    {
                        'Element'        => 'QueueIDs',
                        'Block'          => 'MultiSelectField',
                        'Selected'       => 1,
                        'Fixed'          => 1,
                        'SelectedValues' => \@QueueIDs,
                    },
                ],
                UseAsRestriction => [],
            },
            UserID => 1,
        },
        ReferenceResultData => [
            [
                'Title for result tests 2015-08-10 00:00:00-2015-08-15 23:59:59',
            ],
            [
                'Queue',
                'Mon 10',
                'Tue 11',
                'Wed 12',
                'Thu 13',
                'Fri 14',
                'Sat 15',
            ],
            [
                $QueueNames[0],
                2,
                0,
                0,
                0,
                0,
                0,
            ],
            [
                $QueueNames[1],
                0,
                0,
                1,
                0,
                0,
                0,
            ],
            [
                $QueueNames[2],
                0,
                1,
                0,
                0,
                0,
                0,
            ],
        ],
    },

    # Test with a relative time period and without a defined time zone
    # Fixed TimeStamp: '2015-08-15 20:00:00'
    # TimeZone: 0
    # X-Axis: 'CreateTime' with a relative period 'the last complete 7 days' and 'scale 1 day'.
    # Y-Axis: 'QueueIDs' to select only the created tickets for the test.
    # Restrictions: -
    # Language: de
    {
        Description => "Test stat without a time zone (last complete 7 days and scale 1 day) and language 'de'",
        TimeStamp   => '2015-08-15 20:00:00',
        Language    => 'de',
        StatsUpdate => {
            StatID => $DynamicMatrixStatID,
            Hash   => {
                TimeZone    => '0',
                UseAsXvalue => [
                    {
                        Element                   => 'CreateTime',
                        Block                     => 'Time',
                        Fixed                     => 1,
                        Selected                  => 1,
                        TimeRelativeCount         => 7,
                        TimeRelativeUpcomingCount => 0,
                        TimeRelativeUnit          => 'Day',
                        TimeScaleCount            => 1,
                        SelectedValues            => [
                            'Day',
                        ],
                    },
                ],
                UseAsValueSeries => [
                    {
                        'Element'        => 'QueueIDs',
                        'Block'          => 'MultiSelectField',
                        'Selected'       => 1,
                        'Fixed'          => 1,
                        'SelectedValues' => \@QueueIDs,
                    },
                ],
                UseAsRestriction => [],
            },
            UserID => 1,
        },
        ReferenceResultData => [
            [
                'Title for result tests 2015-08-08 00:00:00-2015-08-14 23:59:59',
            ],
            [
                'Queue',
                'Sa 8',
                'So 9',
                'Mo 10',
                'Di 11',
                'Mi 12',
                'Do 13',
                'Fr 14',
            ],
            [
                $QueueNames[0],
                0,
                1,
                2,
                0,
                0,
                0,
                0,
            ],
            [
                $QueueNames[1],
                0,
                0,
                0,
                0,
                1,
                0,
                0,
            ],
            [
                $QueueNames[2],
                0,
                0,
                0,
                1,
                0,
                0,
                0,
            ],
        ],
    },

    # Test with a relative time period and without a defined time zone
    # Fixed TimeStamp: '2015-08-15 20:00:00'
    # TimeZone: 0
    # X-Axis: 'CreateTime' with a relative period 'the last complete 7 days' and 'scale 1 day'.
    # Y-Axis: 'QueueIDs' to select only the created tickets for the test.
    # Restrictions: -
    # Language: es
    {
        Description => "Test stat without a time zone (last complete 7 days and scale 1 day) and language 'es'",
        TimeStamp   => '2015-08-15 20:00:00',
        Language    => 'es',
        StatsUpdate => {
            StatID => $DynamicMatrixStatID,
            Hash   => {
                TimeZone    => '0',
                UseAsXvalue => [
                    {
                        Element                   => 'CreateTime',
                        Block                     => 'Time',
                        Fixed                     => 1,
                        Selected                  => 1,
                        TimeRelativeCount         => 7,
                        TimeRelativeUpcomingCount => 0,
                        TimeRelativeUnit          => 'Day',
                        TimeScaleCount            => 1,
                        SelectedValues            => [
                            'Day',
                        ],
                    },
                ],
                UseAsValueSeries => [
                    {
                        'Element'        => 'QueueIDs',
                        'Block'          => 'MultiSelectField',
                        'Selected'       => 1,
                        'Fixed'          => 1,
                        'SelectedValues' => \@QueueIDs,
                    },
                ],
                UseAsRestriction => [],
            },
            UserID => 1,
        },
        ReferenceResultData => [
            [
                'Title for result tests 2015-08-08 00:00:00-2015-08-14 23:59:59',
            ],
            [
                'Cola',
                'Sáb 8',
                'Dom 9',
                'Lun 10',
                'Mar 11',
                'Mié 12',
                'Jue 13',
                'Vie 14',
            ],
            [
                $QueueNames[0],
                0,
                1,
                2,
                0,
                0,
                0,
                0,
            ],
            [
                $QueueNames[1],
                0,
                0,
                0,
                0,
                1,
                0,
                0,
            ],
            [
                $QueueNames[2],
                0,
                0,
                0,
                1,
                0,
                0,
                0,
            ],
        ],
    },

    # Test with a relative time period and a other language
    # Fixed TimeStamp: '2015-08-15 20:00:00'
    # TimeZone: 0
    # X-Axis: 'CreateTime' with a relative period 'the last complete 7 days' and 'scale 1 day'.
    # Y-Axis: 'QueueIDs' to select only the created tickets for the test.
    # Restrictions: -
    # Language: es_MX
    {
        Description => "Test stat without a time zone (last complete 7 days and scale 1 day) and language 'es_MX'",
        TimeStamp   => '2015-08-15 20:00:00',
        Language    => 'es_MX',
        StatsUpdate => {
            StatID => $DynamicMatrixStatID,
            Hash   => {
                UseAsXvalue => [
                    {
                        Element                   => 'CreateTime',
                        Block                     => 'Time',
                        Fixed                     => 1,
                        Selected                  => 1,
                        TimeRelativeCount         => 7,
                        TimeRelativeUpcomingCount => 0,
                        TimeRelativeUnit          => 'Day',
                        TimeScaleCount            => 1,
                        SelectedValues            => [
                            'Day',
                        ],
                    },
                ],
                UseAsValueSeries => [
                    {
                        'Element'        => 'QueueIDs',
                        'Block'          => 'MultiSelectField',
                        'Selected'       => 1,
                        'Fixed'          => 1,
                        'SelectedValues' => \@QueueIDs,
                    },
                ],
                UseAsRestriction => [],
            },
            UserID => 1,
        },
        ReferenceResultData => [
            [
                'Title for result tests 2015-08-08 00:00:00-2015-08-14 23:59:59',
            ],
            [
                'Fila',
                'Sáb 8',
                'Dom 9',
                'Lun 10',
                'Mar 11',
                'Mié 12',
                'Jue 13',
                'Vie 14',
            ],
            [
                $QueueNames[0],
                0,
                1,
                2,
                0,
                0,
                0,
                0,
            ],
            [
                $QueueNames[1],
                0,
                0,
                0,
                0,
                1,
                0,
                0,
            ],
            [
                $QueueNames[2],
                0,
                0,
                0,
                1,
                0,
                0,
                0,
            ],
        ],
    },

# Test with a relative time period and without a defined time zone
# Fixed TimeStamp: '2015-08-20 20:00:00'
# TimeZone: 0
# X-Axis: 'CreateTime' with a relative period 'the last complete 24 months and current+upcoming 1 months' and 'scale 1 month'.
# Y-Axis: 'CreateTime' with 'scale 1 year'
# Restrictions: 'QueueIDs' to select only the created tickets for the test.
    {
        Description =>
            'Test stat without a time zone (last complete 24 months and scale 1 month) and time element on Y-Axis',
        TimeStamp   => '2015-08-20 14:00:00',
        Language    => 'en',
        StatsUpdate => {
            StatID => $DynamicMatrixStatID,
            Hash   => {
                TimeZone    => '0',
                UseAsXvalue => [
                    {
                        Element                   => 'CreateTime',
                        Block                     => 'Time',
                        Fixed                     => 1,
                        Selected                  => 1,
                        TimeRelativeCount         => 24,
                        TimeRelativeUpcomingCount => 1,
                        TimeRelativeUnit          => 'Month',
                        TimeScaleCount            => 1,
                        SelectedValues            => [
                            'Month',
                        ],
                    },
                ],
                UseAsValueSeries => [
                    {
                        Element        => 'CreateTime',
                        Block          => 'Time',
                        Fixed          => 1,
                        Selected       => 1,
                        TimeScaleCount => 1,
                        SelectedValues => [
                            'Year',
                        ],
                    },
                ],
                UseAsRestriction => [
                    {
                        'Element'        => 'QueueIDs',
                        'Block'          => 'MultiSelectField',
                        'Selected'       => 1,
                        'Fixed'          => 1,
                        'SelectedValues' => \@QueueIDs,
                    },
                ],
            },
            UserID => 1,
        },
        ReferenceResultData => [
            [
                'Title for result tests',
            ],
            [
                'Year',
                'Jan 1',
                'Feb 2',
                'Mar 3',
                'Apr 4',
                'May 5',
                'Jun 6',
                'Jul 7',
                'Aug 8',
                'Sep 9',
                'Oct 10',
                'Nov 11',
                'Dec 12',
            ],
            [
                '2013',
                '',
                '',
                '',
                '',
                '',
                '',
                '',
                0,
                0,
                0,
                0,
                0,
            ],
            [
                '2014',
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                1,
                1,
                0,
                1,
            ],
            [
                '2015',
                0,
                0,
                0,
                0,
                0,
                0,
                1,
                5,
                '',
                '',
                '',
                '',
            ],
        ],
    },

# Test with a relative time period and without a defined time zone
# Fixed TimeStamp: '2015-08-20 20:00:00'
# TimeZone: 0
# X-Axis: 'CreateTime' with a relative period 'the last complete 3 months and current+upcoming 1 months' and 'scale 1 month'.
# Y-Axis: 'CreateTime' with 'scale 1 year'
# Restrictions: 'QueueIDs' to select only the created tickets for the test.
    {
        Description =>
            'Test stat without a time zone (last complete 3 months and scale 1 month) and time element on Y-Axis',
        TimeStamp   => '2015-08-20 14:00:00',
        Language    => 'en',
        StatsUpdate => {
            StatID => $DynamicMatrixStatID,
            Hash   => {
                TimeZone    => '0',
                UseAsXvalue => [
                    {
                        Element                   => 'CreateTime',
                        Block                     => 'Time',
                        Fixed                     => 1,
                        Selected                  => 1,
                        TimeRelativeCount         => 3,
                        TimeRelativeUpcomingCount => 1,
                        TimeRelativeUnit          => 'Month',
                        TimeScaleCount            => 1,
                        SelectedValues            => [
                            'Month',
                        ],
                    },
                ],
                UseAsValueSeries => [
                    {
                        Element        => 'CreateTime',
                        Block          => 'Time',
                        Fixed          => 1,
                        Selected       => 1,
                        TimeScaleCount => 1,
                        SelectedValues => [
                            'Year',
                        ],
                    },
                ],
                UseAsRestriction => [
                    {
                        'Element'        => 'QueueIDs',
                        'Block'          => 'MultiSelectField',
                        'Selected'       => 1,
                        'Fixed'          => 1,
                        'SelectedValues' => \@QueueIDs,
                    },
                ],
            },
            UserID => 1,
        },
        ReferenceResultData => [
            [
                'Title for result tests',
            ],
            [
                'Year',
                'Jan 1',
                'Feb 2',
                'Mar 3',
                'Apr 4',
                'May 5',
                'Jun 6',
                'Jul 7',
                'Aug 8',
                'Sep 9',
                'Oct 10',
                'Nov 11',
                'Dec 12',
            ],
            [
                '2015',
                '',
                '',
                '',
                '',
                0,
                0,
                1,
                5,
                '',
                '',
                '',
                '',
            ],
        ],
    },

# Test with a relative time period and without a defined time zone
# Fixed TimeStamp: '2015-08-20 20:00:00'
# TimeZone: 0
# X-Axis: 'CreateTime' with a relative period 'the last complete 24 months and current+upcoming 1 months' and 'scale 1 quarter'.
# Y-Axis: 'CreateTime' with 'scale 1 year'
# Restrictions: 'QueueIDs' to select only the created tickets for the test.
    {
        Description =>
            'Test stat without a time zone (last complete 24 months and scale 1 quarter) and time element on Y-Axis',
        TimeStamp   => '2015-08-20 14:00:00',
        Language    => 'en',
        StatsUpdate => {
            StatID => $DynamicMatrixStatID,
            Hash   => {
                TimeZone    => '0',
                UseAsXvalue => [
                    {
                        Element                   => 'CreateTime',
                        Block                     => 'Time',
                        Fixed                     => 1,
                        Selected                  => 1,
                        TimeRelativeCount         => 24,
                        TimeRelativeUpcomingCount => 1,
                        TimeRelativeUnit          => 'Month',
                        TimeScaleCount            => 1,
                        SelectedValues            => [
                            'Quarter',
                        ],
                    },
                ],
                UseAsValueSeries => [
                    {
                        Element        => 'CreateTime',
                        Block          => 'Time',
                        Fixed          => 1,
                        Selected       => 1,
                        TimeScaleCount => 1,
                        SelectedValues => [
                            'Year',
                        ],
                    },
                ],
                UseAsRestriction => [
                    {
                        'Element'        => 'QueueIDs',
                        'Block'          => 'MultiSelectField',
                        'Selected'       => 1,
                        'Fixed'          => 1,
                        'SelectedValues' => \@QueueIDs,
                    },
                ],
            },
            UserID => 1,
        },
        ReferenceResultData => [
            [
                'Title for result tests',
            ],
            [
                'Year',
                'quarter 1',
                'quarter 2',
                'quarter 3',
                'quarter 4',
            ],
            [
                '2013',
                '',
                '',
                0,
                0,
            ],
            [
                '2014',
                0,
                0,
                1,
                2,
            ],
            [
                '2015',
                0,
                0,
                7,
                '',
            ],
        ],
    },

    # Test with a relative time period and with selected SumRow
    # Fixed TimeStamp: '2015-08-15 20:00:00'
    # TimeZone: -
    # X-Axis: 'CreateTime' with a relative period 'the last complete 7 days' and 'scale 1 day'.
    # Y-Axis: 'QueueIDs' to select only the created tickets for the test.
    # Restrictions: -
    # SumRow: 'Yes'
    # SumCol: 'No'
    {
        Description => 'Test stat with selected SumRow (last complete 7 days and scale 1 day)',
        TimeStamp   => '2015-08-15 20:00:00',
        Language    => 'en',
        StatsUpdate => {
            StatID => $DynamicMatrixStatID,
            Hash   => {
                SumRow      => 1,
                SumCol      => 0,
                UseAsXvalue => [
                    {
                        Element                   => 'CreateTime',
                        Block                     => 'Time',
                        Fixed                     => 1,
                        Selected                  => 1,
                        TimeRelativeCount         => 7,
                        TimeRelativeUpcomingCount => 0,
                        TimeRelativeUnit          => 'Day',
                        TimeScaleCount            => 1,
                        SelectedValues            => [
                            'Day',
                        ],
                    },
                ],
                UseAsValueSeries => [
                    {
                        'Element'        => 'QueueIDs',
                        'Block'          => 'MultiSelectField',
                        'Selected'       => 1,
                        'Fixed'          => 1,
                        'SelectedValues' => \@QueueIDs,
                    },
                ],
                UseAsRestriction => [],
            },
            UserID => 1,
        },
        ReferenceResultData => [
            [
                'Title for result tests 2015-08-08 00:00:00-2015-08-14 23:59:59',
            ],
            [
                'Queue',
                'Sat 8',
                'Sun 9',
                'Mon 10',
                'Tue 11',
                'Wed 12',
                'Thu 13',
                'Fri 14',
            ],
            [
                $QueueNames[0],
                0,
                1,
                2,
                0,
                0,
                0,
                0,
            ],
            [
                $QueueNames[1],
                0,
                0,
                0,
                0,
                1,
                0,
                0,
            ],
            [
                $QueueNames[2],
                0,
                0,
                0,
                1,
                0,
                0,
                0,
            ],
            [
                'Sum',
                0,
                1,
                2,
                1,
                1,
                0,
                0,
            ],
        ],
    },

    # Test with a relative time period and with selected SumCol
    # Fixed TimeStamp: '2015-08-15 20:00:00'
    # TimeZone: -
    # X-Axis: 'CreateTime' with a relative period 'the last complete 7 days' and 'scale 1 day'.
    # Y-Axis: 'QueueIDs' to select only the created tickets for the test.
    # Restrictions: -
    # SumRow: 'No'
    # SumCol: 'Yes'
    {
        Description => 'Test stat with selected SumCol (last complete 7 days and scale 1 day)',
        TimeStamp   => '2015-08-15 20:00:00',
        Language    => 'en',
        StatsUpdate => {
            StatID => $DynamicMatrixStatID,
            Hash   => {
                SumRow      => 0,
                SumCol      => 1,
                UseAsXvalue => [
                    {
                        Element                   => 'CreateTime',
                        Block                     => 'Time',
                        Fixed                     => 1,
                        Selected                  => 1,
                        TimeRelativeCount         => 7,
                        TimeRelativeUpcomingCount => 0,
                        TimeRelativeUnit          => 'Day',
                        TimeScaleCount            => 1,
                        SelectedValues            => [
                            'Day',
                        ],
                    },
                ],
                UseAsValueSeries => [
                    {
                        'Element'        => 'QueueIDs',
                        'Block'          => 'MultiSelectField',
                        'Selected'       => 1,
                        'Fixed'          => 1,
                        'SelectedValues' => \@QueueIDs,
                    },
                ],
                UseAsRestriction => [],
            },
            UserID => 1,
        },
        ReferenceResultData => [
            [
                'Title for result tests 2015-08-08 00:00:00-2015-08-14 23:59:59',
            ],
            [
                'Queue',
                'Sat 8',
                'Sun 9',
                'Mon 10',
                'Tue 11',
                'Wed 12',
                'Thu 13',
                'Fri 14',
                'Sum',
            ],
            [
                $QueueNames[0],
                0,
                1,
                2,
                0,
                0,
                0,
                0,
                3,
            ],
            [
                $QueueNames[1],
                0,
                0,
                0,
                0,
                1,
                0,
                0,
                1,
            ],
            [
                $QueueNames[2],
                0,
                0,
                0,
                1,
                0,
                0,
                0,
                1,
            ],
        ],
    },

    # Test with a relative time period and with selected SumRow and SumCol
    # Fixed TimeStamp: '2015-08-15 20:00:00'
    # TimeZone: -
    # X-Axis: 'CreateTime' with a relative period 'the last complete 7 days' and 'scale 1 day'.
    # Y-Axis: 'QueueIDs' to select only the created tickets for the test.
    # Restrictions: -
    # SumRow: 'No'
    # SumCol: 'Yes'
    {
        Description => 'Test stat with selected SumRow and SumCol (last complete 7 days and scale 1 day)',
        TimeStamp   => '2015-08-15 20:00:00',
        Language    => 'en',
        StatsUpdate => {
            StatID => $DynamicMatrixStatID,
            Hash   => {
                SumRow      => 1,
                SumCol      => 1,
                UseAsXvalue => [
                    {
                        Element                   => 'CreateTime',
                        Block                     => 'Time',
                        Fixed                     => 1,
                        Selected                  => 1,
                        TimeRelativeCount         => 7,
                        TimeRelativeUpcomingCount => 0,
                        TimeRelativeUnit          => 'Day',
                        TimeScaleCount            => 1,
                        SelectedValues            => [
                            'Day',
                        ],
                    },
                ],
                UseAsValueSeries => [
                    {
                        'Element'        => 'QueueIDs',
                        'Block'          => 'MultiSelectField',
                        'Selected'       => 1,
                        'Fixed'          => 1,
                        'SelectedValues' => \@QueueIDs,
                    },
                ],
                UseAsRestriction => [],
            },
            UserID => 1,
        },
        ReferenceResultData => [
            [
                'Title for result tests 2015-08-08 00:00:00-2015-08-14 23:59:59',
            ],
            [
                'Queue',
                'Sat 8',
                'Sun 9',
                'Mon 10',
                'Tue 11',
                'Wed 12',
                'Thu 13',
                'Fri 14',
                'Sum',
            ],
            [
                $QueueNames[0],
                0,
                1,
                2,
                0,
                0,
                0,
                0,
                3,
            ],
            [
                $QueueNames[1],
                0,
                0,
                0,
                0,
                1,
                0,
                0,
                1,
            ],
            [
                $QueueNames[2],
                0,
                0,
                0,
                1,
                0,
                0,
                0,
                1,
            ],
            [
                'Sum',
                0,
                1,
                2,
                1,
                1,
                0,
                0,
                5,
            ],
        ],
    },

    # ------------------------------------------------------------ #
    # some special tests for dynamic fields text and textarea
    # ------------------------------------------------------------ #

    # Test with a relative time period and a restriction for a dynamic field textarea
    # Fixed TimeStamp: '2015-08-15 20:00:00'
    # TimeZone: -
    # X-Axis: 'CreateTime' with a relative period 'the last complete 7 days' and 'scale 1 day'.
    # Y-Axis: 'QueueIDs' to select only the created tickets for the test.
    # Restrictions: 'TextArea' => 'Example*',
    {
        Description =>
            'Test stat with a restriction for a dynamic field textarea (last complete 7 days and scale 1 day)',
        TimeStamp   => '2015-08-15 20:00:00',
        Language    => 'en',
        StatsUpdate => {
            StatID => $DynamicMatrixStatID,
            Hash   => {
                SumRow      => 0,
                SumCol      => 0,
                UseAsXvalue => [
                    {
                        Element                   => 'CreateTime',
                        Block                     => 'Time',
                        Fixed                     => 1,
                        Selected                  => 1,
                        TimeRelativeCount         => 7,
                        TimeRelativeUpcomingCount => 0,
                        TimeRelativeUnit          => 'Day',
                        TimeScaleCount            => 1,
                        SelectedValues            => [
                            'Day',
                        ],
                    },
                ],
                UseAsValueSeries => [
                    {
                        'Element'        => 'QueueIDs',
                        'Block'          => 'MultiSelectField',
                        'Selected'       => 1,
                        'Fixed'          => 1,
                        'SelectedValues' => \@QueueIDs,
                    },
                ],
                UseAsRestriction => [
                    {
                        'Element'        => 'DynamicField_TextArea' . $RandomID,
                        'Block'          => 'InputField',
                        'Selected'       => 1,
                        'Fixed'          => 1,
                        'SelectedValues' => [
                            'Example*',
                        ],
                    },
                ],
            },
            UserID => 1,
        },
        ReferenceResultData => [
            [
                'Title for result tests 2015-08-08 00:00:00-2015-08-14 23:59:59',
            ],
            [
                'Queue',
                'Sat 8',
                'Sun 9',
                'Mon 10',
                'Tue 11',
                'Wed 12',
                'Thu 13',
                'Fri 14',
            ],
            [
                $QueueNames[0],
                0,
                0,
                0,
                0,
                0,
                0,
                0,
            ],
            [
                $QueueNames[1],
                0,
                0,
                0,
                0,
                1,
                0,
                0,
            ],
            [
                $QueueNames[2],
                0,
                0,
                0,
                1,
                0,
                0,
                0,
            ],
        ],
    },

    # Test with a relative time period and a restriction for a dynamic field text
    # Fixed TimeStamp: '2015-08-15 20:00:00'
    # TimeZone: -
    # X-Axis: 'CreateTime' with a relative period 'the last complete 7 days' and 'scale 1 day'.
    # Y-Axis: 'QueueIDs' to select only the created tickets for the test.
    # Restrictions: 'Text' => 'Example*',
    {
        Description => 'Test stat with a restriction for a dynamic field text (last complete 7 days and scale 1 day)',
        TimeStamp   => '2015-08-15 20:00:00',
        Language    => 'en',
        StatsUpdate => {
            StatID => $DynamicMatrixStatID,
            Hash   => {
                SumRow      => 0,
                SumCol      => 0,
                UseAsXvalue => [
                    {
                        Element                   => 'CreateTime',
                        Block                     => 'Time',
                        Fixed                     => 1,
                        Selected                  => 1,
                        TimeRelativeCount         => 7,
                        TimeRelativeUpcomingCount => 0,
                        TimeRelativeUnit          => 'Day',
                        TimeScaleCount            => 1,
                        SelectedValues            => [
                            'Day',
                        ],
                    },
                ],
                UseAsValueSeries => [
                    {
                        'Element'        => 'QueueIDs',
                        'Block'          => 'MultiSelectField',
                        'Selected'       => 1,
                        'Fixed'          => 1,
                        'SelectedValues' => \@QueueIDs,
                    },
                ],
                UseAsRestriction => [
                    {
                        'Element'        => 'DynamicField_Text' . $RandomID,
                        'Block'          => 'InputField',
                        'Selected'       => 1,
                        'Fixed'          => 1,
                        'SelectedValues' => [
                            'Example*',
                        ],
                    },
                ],
            },
            UserID => 1,
        },
        ReferenceResultData => [
            [
                'Title for result tests 2015-08-08 00:00:00-2015-08-14 23:59:59',
            ],
            [
                'Queue',
                'Sat 8',
                'Sun 9',
                'Mon 10',
                'Tue 11',
                'Wed 12',
                'Thu 13',
                'Fri 14',
            ],
            [
                $QueueNames[0],
                0,
                0,
                0,
                0,
                0,
                0,
                0,
            ],
            [
                $QueueNames[1],
                0,
                0,
                0,
                0,
                1,
                0,
                0,
            ],
            [
                $QueueNames[2],
                0,
                0,
                0,
                0,
                0,
                0,
                0,
            ],
        ],
    },

    # Test with a relative time period and a restriction for a dynamic field text and textarea
    # Fixed TimeStamp: '2015-08-15 20:00:00'
    # TimeZone: -
    # X-Axis: 'CreateTime' with a relative period 'the last complete 7 days' and 'scale 1 day'.
    # Y-Axis: 'QueueIDs' to select only the created tickets for the test.
    # Restrictions: 'Text' => 'Example*' & 'TextArea' => 'Example*',
    {
        Description =>
            'Test stat with a restriction for a dynamic field text and textarea (last complete 7 days and scale 1 day)',
        TimeStamp   => '2015-08-15 20:00:00',
        Language    => 'en',
        StatsUpdate => {
            StatID => $DynamicMatrixStatID,
            Hash   => {
                SumRow      => 0,
                SumCol      => 0,
                UseAsXvalue => [
                    {
                        Element                   => 'CreateTime',
                        Block                     => 'Time',
                        Fixed                     => 1,
                        Selected                  => 1,
                        TimeRelativeCount         => 7,
                        TimeRelativeUpcomingCount => 0,
                        TimeRelativeUnit          => 'Day',
                        TimeScaleCount            => 1,
                        SelectedValues            => [
                            'Day',
                        ],
                    },
                ],
                UseAsValueSeries => [
                    {
                        'Element'        => 'QueueIDs',
                        'Block'          => 'MultiSelectField',
                        'Selected'       => 1,
                        'Fixed'          => 1,
                        'SelectedValues' => \@QueueIDs,
                    },
                ],
                UseAsRestriction => [
                    {
                        'Element'        => 'DynamicField_Text' . $RandomID,
                        'Block'          => 'InputField',
                        'Selected'       => 1,
                        'Fixed'          => 1,
                        'SelectedValues' => [
                            'Example*',
                        ],
                    },
                    {
                        'Element'        => 'DynamicField_TextArea' . $RandomID,
                        'Block'          => 'InputField',
                        'Selected'       => 1,
                        'Fixed'          => 1,
                        'SelectedValues' => [
                            'Example*',
                        ],
                    },
                ],
            },
            UserID => 1,
        },
        ReferenceResultData => [
            [
                'Title for result tests 2015-08-08 00:00:00-2015-08-14 23:59:59',
            ],
            [
                'Queue',
                'Sat 8',
                'Sun 9',
                'Mon 10',
                'Tue 11',
                'Wed 12',
                'Thu 13',
                'Fri 14',
            ],
            [
                $QueueNames[0],
                0,
                0,
                0,
                0,
                0,
                0,
                0,
            ],
            [
                $QueueNames[1],
                0,
                0,
                0,
                0,
                1,
                0,
                0,
            ],
            [
                $QueueNames[2],
                0,
                0,
                0,
                0,
                0,
                0,
                0,
            ],
        ],
    },

    # Test with a relative time period and a restriction for a dynamic field text and textarea
    # Fixed TimeStamp: '2014-10-12 20:00:00'
    # TimeZone: -
    # X-Axis: 'CreateTime' with a relative period 'the last complete 7 days' and 'scale 1 day'.
    # Y-Axis: 'QueueIDs' to select only the created tickets for the test.
    # Restrictions: 'CustomerID' => 'example + test' (exact match),
    {
        Description => 'Test stat with a restriction for a special customer id (last complete 7 days and scale 1 day)',
        TimeStamp   => '2014-10-12 20:00:00',
        Language    => 'en',
        StatsUpdate => {
            StatID => $DynamicMatrixStatID,
            Hash   => {
                SumRow      => 0,
                SumCol      => 0,
                UseAsXvalue => [
                    {
                        Element                   => 'CreateTime',
                        Block                     => 'Time',
                        Fixed                     => 1,
                        Selected                  => 1,
                        TimeRelativeCount         => 7,
                        TimeRelativeUpcomingCount => 0,
                        TimeRelativeUnit          => 'Day',
                        TimeScaleCount            => 1,
                        SelectedValues            => [
                            'Day',
                        ],
                    },
                ],
                UseAsValueSeries => [
                    {
                        'Element'        => 'QueueIDs',
                        'Block'          => 'MultiSelectField',
                        'Selected'       => 1,
                        'Fixed'          => 1,
                        'SelectedValues' => \@QueueIDs,
                    },
                ],
                UseAsRestriction => [
                    {
                        'Element'        => 'CustomerID',
                        'Block'          => 'MultiSelectField',
                        'Selected'       => 1,
                        'Fixed'          => 1,
                        'SelectedValues' => [
                            'example + test',
                        ],
                    },
                ],
            },
            UserID => 1,
        },
        ReferenceResultData => [
            [
                'Title for result tests 2014-10-05 00:00:00-2014-10-11 23:59:59',
            ],
            [
                'Queue',
                'Sun 5',
                'Mon 6',
                'Tue 7',
                'Wed 8',
                'Thu 9',
                'Fri 10',
                'Sat 11',
            ],
            [
                $QueueNames[0],
                0,
                0,
                0,
                0,
                0,
                1,
                0,
            ],
            [
                $QueueNames[1],
                0,
                0,
                0,
                0,
                0,
                0,
                0,
            ],
            [
                $QueueNames[2],
                0,
                0,
                0,
                0,
                0,
                0,
                0,
            ],
        ],
    },

    # Test for a dynamic list with some selected columns and restrictions (special CustomerID value with '+')
    # Fixed TimeStamp: '2015-08-15 20:00:00'
    # TimeZone: -
    # X-Axis: 'TicketAttributes' - Number, TicketNumber, Title, Created, Queue
    # Y-Axis: 'OrderBy' - TicketNumber, 'SortSequence' - Up
    # Restrictions: 'QueueIDs' to select only the created tickets for the test,
    #               'CreateTime' with a relative period 'the last complete 7 days'
    #               'CustomerID' with a selected customer id 'example + test'
    {
        Description =>
            "Test dynamic list stat with some selected columns and a restriction for the create time and a selected customer id with a '+'",
        TimeStamp   => '2014-10-12 20:00:00',
        Language    => 'en',
        StatsUpdate => {
            StatID => $DynamicListStatID,
            Hash   => {
                UseAsXvalue => [
                    {
                        'Element'        => 'TicketAttributes',
                        'Block'          => 'MultiSelectField',
                        'Selected'       => 1,
                        'Fixed'          => 1,
                        'SelectedValues' => [
                            'Number',
                            'TicketNumber',
                            'Title',
                            'Created',
                            'Queue',
                        ],
                    },
                ],
                UseAsValueSeries => [
                    {
                        'Element'        => 'OrderBy',
                        'Block'          => 'SelectField',
                        'Selected'       => 1,
                        'Fixed'          => 1,
                        'SelectedValues' => [
                            'TicketNumber',
                        ],
                    },
                    {
                        'Element'        => 'SortSequence',
                        'Block'          => 'SelectField',
                        'Selected'       => 1,
                        'Fixed'          => 1,
                        'SelectedValues' => [
                            'Up',
                        ],
                    },
                ],
                UseAsRestriction => [
                    {
                        'Element'        => 'QueueIDs',
                        'Block'          => 'MultiSelectField',
                        'Selected'       => 1,
                        'Fixed'          => 1,
                        'SelectedValues' => \@QueueIDs,
                    },
                    {
                        Element                   => 'CreateTime',
                        Block                     => 'Time',
                        Fixed                     => 1,
                        Selected                  => 1,
                        TimeRelativeCount         => 7,
                        TimeRelativeUpcomingCount => 0,
                        TimeRelativeUnit          => 'Day',
                        SelectedValues            => [],
                    },
                    {
                        'Element'        => 'CustomerID',
                        'Block'          => 'MultiSelectField',
                        'Selected'       => 1,
                        'Fixed'          => 1,
                        'SelectedValues' => [
                            'example + test',
                        ],
                    },
                ],
            },
            UserID => 1,
        },
        ReferenceResultData => [
            [
                'Title for result tests 2014-10-05 00:00:00-2014-10-11 23:59:59',
            ],
            [
                'Number',
                'Ticket#',
                'Title',
                'Created',
                'Queue',
            ],
            [
                1,
                $TicketIDs[0]->{TicketNumber},
                $TicketIDs[0]->{Title},
                $TicketIDs[0]->{Created},
                $TicketIDs[0]->{Queue},
            ],
        ],
    },

    # Test for a dynamic list with some selected columns and restrictions
    # Fixed TimeStamp: '2015-08-15 20:00:00'
    # TimeZone: -
    # X-Axis: 'TicketAttributes' - Number, TicketNumber, Title, Created, Queue
    # Y-Axis: 'OrderBy' - TicketNumber, 'SortSequence' - Up
    # Restrictions: 'QueueIDs' to select only the created tickets for the test,
    #               'CreateTime' with a relative period 'the last complete 7 days'
    {
        Description => 'Test dynamic list stat with some selected columns and a restriction for the create time',
        TimeStamp   => '2015-08-15 20:00:00',
        Language    => 'en',
        StatsUpdate => {
            StatID => $DynamicListStatID,
            Hash   => {
                UseAsXvalue => [
                    {
                        'Element'        => 'TicketAttributes',
                        'Block'          => 'MultiSelectField',
                        'Selected'       => 1,
                        'Fixed'          => 1,
                        'SelectedValues' => [
                            'Number',
                            'TicketNumber',
                            'Title',
                            'Created',
                            'Queue',
                        ],
                    },
                ],
                UseAsValueSeries => [
                    {
                        'Element'        => 'OrderBy',
                        'Block'          => 'SelectField',
                        'Selected'       => 1,
                        'Fixed'          => 1,
                        'SelectedValues' => [
                            'TicketNumber',
                        ],
                    },
                    {
                        'Element'        => 'SortSequence',
                        'Block'          => 'SelectField',
                        'Selected'       => 1,
                        'Fixed'          => 1,
                        'SelectedValues' => [
                            'Up',
                        ],
                    },
                ],
                UseAsRestriction => [
                    {
                        'Element'        => 'QueueIDs',
                        'Block'          => 'MultiSelectField',
                        'Selected'       => 1,
                        'Fixed'          => 1,
                        'SelectedValues' => \@QueueIDs,
                    },
                    {
                        Element                   => 'CreateTime',
                        Block                     => 'Time',
                        Fixed                     => 1,
                        Selected                  => 1,
                        TimeRelativeCount         => 7,
                        TimeRelativeUpcomingCount => 0,
                        TimeRelativeUnit          => 'Day',
                        SelectedValues            => [],
                    },
                ],
            },
            UserID => 1,
        },
        ReferenceResultData => [
            [
                'Title for result tests 2015-08-08 00:00:00-2015-08-14 23:59:59',
            ],
            [
                'Number',
                'Ticket#',
                'Title',
                'Created',
                'Queue',
            ],
            [
                1,
                $TicketIDs[3]->{TicketNumber},
                $TicketIDs[3]->{Title},
                $TicketIDs[3]->{Created},
                $TicketIDs[3]->{Queue},
            ],
            [
                2,
                $TicketIDs[4]->{TicketNumber},
                $TicketIDs[4]->{Title},
                $TicketIDs[4]->{Created},
                $TicketIDs[4]->{Queue},
            ],
            [
                3,
                $TicketIDs[5]->{TicketNumber},
                $TicketIDs[5]->{Title},
                $TicketIDs[5]->{Created},
                $TicketIDs[5]->{Queue},
            ],
            [
                4,
                $TicketIDs[6]->{TicketNumber},
                $TicketIDs[6]->{Title},
                $TicketIDs[6]->{Created},
                $TicketIDs[6]->{Queue},
            ],
            [
                5,
                $TicketIDs[9]->{TicketNumber},
                $TicketIDs[9]->{Title},
                $TicketIDs[9]->{Created},
                $TicketIDs[9]->{Queue},
            ],
        ],
    },

    # Test for a dynamic list with some selected columns and restrictions with other Language
    # Fixed TimeStamp: '2015-08-15 20:00:00'
    # TimeZone: -
    # X-Axis: 'TicketAttributes' - Number, TicketNumber, Title, Created, Queue
    # Y-Axis: 'OrderBy' - TicketNumber, 'SortSequence' - Up
    # Restrictions: 'QueueIDs' to select only the created tickets for the test,
    #               'CreateTime' with a relative period 'the last complete 7 days'
    # Language: de
    {
        Description =>
            "Test dynamic list stat with some selected columns and a restriction for the create time and language 'de'",
        TimeStamp   => '2015-08-15 20:00:00',
        Language    => 'de',
        StatsUpdate => {
            StatID => $DynamicListStatID,
            Hash   => {
                UseAsXvalue => [
                    {
                        'Element'        => 'TicketAttributes',
                        'Block'          => 'MultiSelectField',
                        'Selected'       => 1,
                        'Fixed'          => 1,
                        'SelectedValues' => [
                            'Number',
                            'TicketNumber',
                            'Title',
                            'Created',
                            'Queue',
                        ],
                    },
                ],
                UseAsValueSeries => [
                    {
                        'Element'        => 'OrderBy',
                        'Block'          => 'SelectField',
                        'Selected'       => 1,
                        'Fixed'          => 1,
                        'SelectedValues' => [
                            'TicketNumber',
                        ],
                    },
                    {
                        'Element'        => 'SortSequence',
                        'Block'          => 'SelectField',
                        'Selected'       => 1,
                        'Fixed'          => 1,
                        'SelectedValues' => [
                            'Up',
                        ],
                    },
                ],
                UseAsRestriction => [
                    {
                        'Element'        => 'QueueIDs',
                        'Block'          => 'MultiSelectField',
                        'Selected'       => 1,
                        'Fixed'          => 1,
                        'SelectedValues' => \@QueueIDs,
                    },
                    {
                        Element                   => 'CreateTime',
                        Block                     => 'Time',
                        Fixed                     => 1,
                        Selected                  => 1,
                        TimeRelativeCount         => 7,
                        TimeRelativeUpcomingCount => 0,
                        TimeRelativeUnit          => 'Day',
                        SelectedValues            => [],
                    },
                ],
            },
            UserID => 1,
        },
        ReferenceResultData => [
            [
                'Title for result tests 2015-08-08 00:00:00-2015-08-14 23:59:59',
            ],
            [
                'Nummer',
                'Ticket#',
                'Titel',
                'Erstellt',
                'Queue',
            ],
            [
                1,
                $TicketIDs[3]->{TicketNumber},
                $TicketIDs[3]->{Title},
                $TicketIDs[3]->{Created},
                $TicketIDs[3]->{Queue},
            ],
            [
                2,
                $TicketIDs[4]->{TicketNumber},
                $TicketIDs[4]->{Title},
                $TicketIDs[4]->{Created},
                $TicketIDs[4]->{Queue},
            ],
            [
                3,
                $TicketIDs[5]->{TicketNumber},
                $TicketIDs[5]->{Title},
                $TicketIDs[5]->{Created},
                $TicketIDs[5]->{Queue},
            ],
            [
                4,
                $TicketIDs[6]->{TicketNumber},
                $TicketIDs[6]->{Title},
                $TicketIDs[6]->{Created},
                $TicketIDs[6]->{Queue},
            ],
            [
                5,
                $TicketIDs[9]->{TicketNumber},
                $TicketIDs[9]->{Title},
                $TicketIDs[9]->{Created},
                $TicketIDs[9]->{Queue},
            ],
        ],
    },
);

# ------------------------------------------------------------ #
# run general result statistic tests
# ------------------------------------------------------------ #

# define test counter
my $TestCount = 1;

TEST:
for my $Test (@Tests) {

    # set the language for the test (for the translatable content)
    if ( $Test->{Language} ) {

        $Kernel::OM->ObjectsDiscard(
            Objects => ['Kernel::Language'],
        );

        $Kernel::OM->ObjectParamAdd(
            'Kernel::Language' => {
                UserLanguage => $Test->{Language},
            },
        );
    }

    # check ContractAdd attribute
    if ( !$Test->{StatsUpdate} || ref $Test->{StatsUpdate} ne 'HASH' ) {

        $Self->True(
            0,
            "Test $TestCount: No StatsUpdate found for this test.",
        );

        next TEST;
    }

    # set the fixed time
    my $SystemTime = $TimeObject->TimeStamp2SystemTime(
        String => $Test->{TimeStamp},
    );
    $Helper->FixedTimeSet($SystemTime);

    # print test case description
    if ( $Test->{Description} ) {
        $Self->True(
            1,
            "Test $TestCount: $Test->{Description}",
        );
    }

    my $UpdateSuccess = $StatsObject->StatsUpdate(
        %{ $Test->{StatsUpdate} },
    );

    $Self->True(
        $UpdateSuccess,
        "Test $TestCount: StatsUpdate() - Update stat - success.",
    );

    my $Stat = $StatsObject->StatsGet( StatID => $Test->{StatsUpdate}->{StatID} );

    $Self->True(
        $Stat->{Title},
        "Test $TestCount: StatsGet() - Get the stat data - success.",
    );

    my $ResultData = $StatsObject->StatsRun(
        StatID   => $Test->{StatsUpdate}->{StatID},
        GetParam => $Stat,
        UserID   => 1,
    );

    $Self->IsDeeply(
        $ResultData,
        $Test->{ReferenceResultData},
        "Test $TestCount: StatsRun() - test the result",
    );
}
continue {

    $Helper->FixedTimeUnset();

    $TestCount++;
}

# to get the system default language in the next test
$Kernel::OM->ObjectsDiscard(
    Objects => ['Kernel::Language'],
);

# cleanup is done by RestoreDatabase.

1;
