# --
# Copyright (C) 2001-2016 OTRS AG, http://otrs.com/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

use strict;
use warnings;
use utf8;

use vars (qw($Self));

# get selenium object
my $Selenium = $Kernel::OM->Get('Kernel::System::UnitTest::Selenium');

$Selenium->RunTest(
    sub {

        # get needed objects
        my $Helper          = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');
        my $SysConfigObject = $Kernel::OM->Get('Kernel::System::SysConfig');

        # set generic agent run limit
        $Helper->ConfigSettingChange(
            Valid => 1,
            Key   => 'Ticket::GenericAgentRunLimit',
            Value => 10
        );

        # enable extended condition search for generic agent ticket search
        $Helper->ConfigSettingChange(
            Valid => 1,
            Key   => 'Ticket::GenericAgentTicketSearch###ExtendedSearchCondition',
            Value => 1,
        );

        # create test user and login
        my $TestUserLogin = $Helper->TestUserCreate(
            Groups => [ 'admin', 'users' ],
        ) || die "Did not get test user";

        $Selenium->Login(
            Type     => 'Agent',
            User     => $TestUserLogin,
            Password => $TestUserLogin,
        );

        # get test user ID
        my $UserID = $Kernel::OM->Get('Kernel::System::User')->UserLookup(
            UserLogin => $TestUserLogin,
        );

        # get ticket object
        my $TicketObject = $Kernel::OM->Get('Kernel::System::Ticket');

        # create test tickets
        my $TestTicketRandomID = $Helper->GetRandomID();
        my $TestTicketTitle    = "Test Ticket $TestTicketRandomID Generic Agent";
        my @TicketNumbers;
        for ( 1 .. 20 ) {

            # create Ticket to test AdminGenericAgent frontend
            my $TicketID = $TicketObject->TicketCreate(
                Title        => $TestTicketTitle,
                Queue        => 'Raw',
                Lock         => 'unlock',
                PriorityID   => 1,
                StateID      => 1,
                CustomerNo   => 'SeleniumTestCustomer',
                CustomerUser => 'customerUnitTest@example.com',
                OwnerID      => $UserID,
                UserID       => $UserID,
            );
            $Self->True(
                $TicketID,
                "Ticket is created - $TicketID",
            );

            my $TicketNumber = $TicketObject->TicketNumberLookup(
                TicketID => $TicketID,
                UserID   => 1,
            );

            push @TicketNumbers, $TicketNumber;

        }

        # get script alias
        my $ScriptAlias = $Kernel::OM->Get('Kernel::Config')->Get('ScriptAlias');

        # navigate to AdminGenericAgent screen
        $Selenium->VerifiedGet("${ScriptAlias}index.pl?Action=AdminGenericAgent");

        # check overview AdminGenericAgent
        $Selenium->find_element( "table",             'css' );
        $Selenium->find_element( "table thead tr th", 'css' );
        $Selenium->find_element( "table tbody tr td", 'css' );

        # check add job page
        $Selenium->find_element("//a[contains(\@href, \'Subaction=Update' )]")->VerifiedClick();

        my $Element = $Selenium->find_element( "#Profile", 'css' );
        $Element->is_displayed();
        $Element->is_enabled();

        # Toggle widgets
        $Selenium->execute_script('$(".WidgetSimple.Collapsed .WidgetAction.Toggle a").click();');

        # create test job
        my $GenericTicketSearch = "*Ticket $TestTicketRandomID Generic*";
        my $RandomID            = "GenericAgent" . $Helper->GetRandomID();
        $Selenium->find_element( "#Profile", 'css' )->send_keys($RandomID);
        $Selenium->find_element( "#Title",   'css' )->send_keys($GenericTicketSearch);
        $Selenium->find_element( "#Profile", 'css' )->VerifiedSubmit();

        # check if test job show on AdminGenericAgent
        $Self->True(
            index( $Selenium->get_page_source(), $RandomID ) > -1,
            "$RandomID job found on page",
        );

        # edit test job to delete test ticket
        $Selenium->find_element( $RandomID, 'link_text' )->VerifiedClick();

        # toggle Execute Ticket Commands widget
        $Selenium->execute_script('$(".WidgetSimple.Collapsed .WidgetAction.Toggle a").click();');
        $Selenium->execute_script("\$('#NewDelete').val('1').trigger('redraw.InputField').trigger('change');");
        $Selenium->find_element( "#Profile", 'css' )->VerifiedSubmit();

        # run test job
        $Selenium->find_element("//a[contains(\@href, \'Subaction=Run;Profile=$RandomID' )]")->VerifiedClick();

        # verify there are no tickets found with enabled ExtendedSearchCondition
        $Self->True(
            index( $Selenium->get_page_source(), '0 Tickets affected! What do you want to do?' ) > -1,
            "No tickets found on page with ExtendedSearchCondition enabled",
        );

        # disable extended condition search for generic agent ticket search
        $Helper->ConfigSettingChange(
            Valid => 1,
            Key   => 'Ticket::GenericAgentTicketSearch###ExtendedSearchCondition',
            Value => 0,
        );

        # navigate to AgentGenericAgent screen again
        $Selenium->VerifiedGet("${ScriptAlias}index.pl?Action=AdminGenericAgent");

        # run test job
        $Selenium->find_element("//a[contains(\@href, \'Subaction=Run;Profile=$RandomID' )]")->VerifiedClick();

        # check if test job show expected result
        for my $TicketNumber (@TicketNumbers) {

            $Self->True(
                index( $Selenium->get_page_source(), $TicketNumber ) > -1,
                "$TicketNumber found on page",
            );

        }

        # check if there is warning message:
        # "Affected more tickets then how many will be executed on run job"
        $Self->True(
            $Selenium->execute_script(
                "return \$('p.Error:contains(tickets affected but only)').length"
            ),
            "RunLimit warning message shown",
        );

        # execute test job
        $Selenium->find_element("//a[contains(\@href, \'Subaction=RunNow' )]")->VerifiedClick();

        # run test job again
        $Selenium->find_element("//a[contains(\@href, \'Subaction=Run;Profile=$RandomID' )]")->VerifiedClick();

        # check if there is no warning message:
        # "Affected more tickets than how many will be executed on run job"
        $Self->False(
            $Selenium->execute_script(
                "return \$('p.Error:contains(tickets affected but only)').length"
            ),
            "There is no warning message",
        );

        # execute test job
        $Selenium->find_element("//a[contains(\@href, \'Subaction=RunNow' )]")->VerifiedClick();

        # set test job to invalid
        $Selenium->find_element( $RandomID, 'link_text' )->VerifiedClick();

        $Selenium->execute_script("\$('#Valid').val('0').trigger('redraw.InputField').trigger('change');");
        $Selenium->find_element( "#Profile", 'css' )->VerifiedSubmit();

        # check class of invalid generic job in the overview table
        $Self->True(
            $Selenium->execute_script(
                "return \$('tr.Invalid td:contains($RandomID)').length"
            ),
            "There is a class 'Invalid' for test generic job",
        );

        # delete test job
        $Selenium->find_element("//a[contains(\@href, \'Subaction=Delete;Profile=$RandomID\' )]")->VerifiedClick();

    }

);

1;
