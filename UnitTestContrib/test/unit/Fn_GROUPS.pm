# tests for the correct expansion of GROUPS

package Fn_GROUPS;
use v5.14;

use Foswiki;

use Moo;
use namespace::clean;
extends qw( FoswikiFnTestCase );

around BUILDARGS => sub {
    my $orig  = shift;
    my $class = shift;
    return $orig->( $class, @_, testSuite => 'GROUPS' );
};

around set_up => sub {
    my $orig = shift;
    my $this = shift;
    $orig->( $this, @_ );
    my ($topicObject) =
      Foswiki::Func::readTopic( $this->users_web, "GropeGroup" );
    $topicObject->text("   * Set GROUP = ScumBag,WikiGuest\n");
    $topicObject->save();
    $topicObject->finish();

    ($topicObject) =
      Foswiki::Func::readTopic( $this->users_web, "NestingGroup" );
    $topicObject->text("   * Set GROUP = GropeGroup\n");
    $topicObject->save();
    $topicObject->finish();
    ($topicObject) =
      Foswiki::Func::readTopic( $this->users_web, "GroupWithHiddenGroup" );
    $topicObject->text("   * Set GROUP = HiddenGroup,WikiGuest\n");
    $topicObject->save();
    $topicObject->finish();
    ($topicObject) =
      Foswiki::Func::readTopic( $this->users_web, "HiddenGroup" );
    $topicObject->text(
        "   * Set GROUP = ScumBag\n   * Set ALLOWTOPICVIEW = AdminUser\n");
    $topicObject->save();
    $topicObject->finish();

    ($topicObject) =
      Foswiki::Func::readTopic( $this->users_web, "HiddenUserGroup" );
    $topicObject->text("   * Set GROUP = ScumBag,HidemeGood\n");
    $topicObject->save();
    $topicObject->finish();

    ($topicObject) = Foswiki::Func::readTopic( $this->users_web, "HidemeGood" );
    my $topText = $topicObject->text();
    $topText .= "   * Set ALLOWTOPICVIEW = AdminUser\n";
    $topText = $topicObject->text($topText);
    $topicObject->save();
    $topicObject->finish();

};

sub test_basic {
    my $this = shift;

    my $ui    = $this->test_topicObject->expandMacros('%GROUPS%');
    my $regex = <<STR;
^| *Group* | *Members* |
| <nop>AdminGroup | [[TemporaryGROUPSUsersWeb.AdminUser][AdminUser]] |
| <nop>BaseGroup | [[TemporaryGROUPSUsersWeb.AdminUser][AdminUser]] [[TemporaryGROUPSUsersWeb.WikiGuest][WikiGuest]] [[TemporaryGROUPSUsersWeb.UnknownUser][UnknownUser]] [[TemporaryGROUPSUsersWeb.ProjectContributor][ProjectContributor]] [[TemporaryGROUPSUsersWeb.RegistrationAgent][RegistrationAgent]] |
| [[TemporaryGROUPSUsersWeb.GropeGroup][GropeGroup]] | [[TemporaryGROUPSUsersWeb.ScumBag][ScumBag]] [[TemporaryGROUPSUsersWeb.WikiGuest][WikiGuest]] |
STR
    $this->assert_matches( $regex, "$ui\n",
        'Mismatch in headings and base groups' );
    $this->assert_matches(
qr/^\| \[\[TemporaryGROUPSUsersWeb.HiddenUserGroup\]\[HiddenUserGroup\]\] \| \[\[TemporaryGROUPSUsersWeb.ScumBag\]\[ScumBag\]\] \|/ms,
        $ui,
        'Missmatch on hidden user'
    );
    $this->assert_matches(
qr/^\| \[\[TemporaryGROUPSUsersWeb.NestingGroup\]\[NestingGroup\]\] \| \[\[TemporaryGROUPSUsersWeb.ScumBag\]\[ScumBag\]\] \[\[TemporaryGROUPSUsersWeb.WikiGuest\]\[WikiGuest\]\] \|/ms,
        $ui,
        'mismatch on nesting group'
    );
    $this->assert_does_not_match(
        qr/^\| \[\[TemporaryGROUPSUsersWeb.HiddenGroup\]\[HiddenGroup\]\] \|/ms,
        $ui,
        'Hidden group revealed'
    );

# SMELL: Tasks/Item10176 - GroupWithHiddenGroup contains HiddenGroup - which contains user ScumBag.  However user ScumBag is NOT hidden.
# So even though HiddenGroup is not visible,  the users it contains are still revealed if they are not also hidden.  Since the HiddenGroup
# itself is not revealed, this bug is questionable.
    $this->assert_matches(
qr/^\| \[\[TemporaryGROUPSUsersWeb\.GroupWithHiddenGroup\]\[GroupWithHiddenGroup\]\] \| \[\[TemporaryGROUPSUsersWeb\.ScumBag\]\[ScumBag\]\] \[\[TemporaryGROUPSUsersWeb\.WikiGuest\]\[WikiGuest\]\] \|$/ms,
        $ui,
        'Mismatch on hidden nested group'
    );

}

1;
