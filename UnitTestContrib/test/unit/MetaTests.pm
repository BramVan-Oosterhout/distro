# Smoke tests for Foswiki::Meta

package MetaTests;
use strict;
use warnings;
require 5.006;

use FoswikiFnTestCase();
our @ISA = qw( FoswikiFnTestCase );

use Foswiki::Func();
use Foswiki::Store();
use Foswiki::Meta();
use Error qw( :try );

my $args0 = {
    name  => "a",
    value => "1",
    aa    => "AA",
    yy    => "YY",
    xx    => "XX"
};

my $args1 = {
    name  => "a",
    value => "2"
};

my $args2 = {
    name  => "b",
    value => "3"
};

my $args3 = {
    name  => "c",
    value => "1"
};

my $topic = "NoTopic";

sub set_up {
    my $this = shift;
    $this->SUPER::set_up();
    $this->createNewFoswikiSession();

    Foswiki::Func::saveTopic( $this->{test_web}, "MetaTestsForm", undef,
        <<FORM);
| *Name* | *Type* | *Size* | *Values* | *Tooltip message* |
| a | text | 40 | | |
| b | text | 40 | | |
| c | select+values | 1 | one=1, two=2, three=3 | | |
FORM

    return;
}

# Field that can only have one copy
sub test_single {
    my $this = shift;
    my $meta =
      Foswiki::Meta->new( $this->{session}, $this->{test_web}, $topic );

    $meta->put( "TOPICINFO", $args0 );
    my $vals = $meta->get("TOPICINFO");
    $this->assert_str_equals( $vals->{"name"},  "a" );
    $this->assert_str_equals( $vals->{"value"}, "1" );
    $this->assert( $meta->count("TOPICINFO") == 1, "Should be one item" );
    $meta->put( "TOPICINFO", $args1 );
    my $vals1 = $meta->get("TOPICINFO");
    $this->assert_str_equals( "a", $vals1->{"name"} );
    $this->assert_equals( 2, $vals1->{"value"} );
    $this->assert_equals( 1, $meta->count("TOPICINFO"), "Should be one item" );
    $meta->finish();

    return;
}

sub test_forceinsert {
    my $this = shift;

    my $topicObject =
      Foswiki::Meta->new( $this->{session}, $this->{test_web}, 'ANewTtopic' );
    $topicObject->save( forceinsert => 1 );
    $topicObject->finish();

    $topicObject =
      Foswiki::Meta->new( $this->{session}, $this->{test_web}, 'ANewTtopic' );
    try {
        $topicObject->save( forceinsert => 1 );
    }
    catch Error::Simple with {
        my $e = shift;
        $this->assert_str_equals( $e->{-text},
"Unable to save topic ANewTtopic - web $this->{test_web} exists and forceinsert specified."
        );
    };
    $topicObject->finish();

    return;
}

sub test_Autoname_AUTOINC {
    my $this = shift;
    my $meta =
      Foswiki::Meta->new( $this->{session}, $this->{test_web},
        'TestAutoAUTOINC001' );
    $this->assert_str_equals( $meta->topic, "TestAutoAUTOINC001" );
    $meta->save();
    $this->assert_str_equals( $meta->topic, "TestAuto001" );
    $this->assert(
        Foswiki::Func::topicExists( $this->{test_web}, 'TestAuto001' ) );

    # Reset name and inseret another, should create #2
    $meta->topic('TestAutoAUTOINC001');
    $meta->save();
    $this->assert_str_equals( $meta->topic, "TestAuto002" );
    $this->assert(
        Foswiki::Func::topicExists( $this->{test_web}, 'TestAuto002' ) );

    # Remove the first topic
    $meta->topic('TestAuto001');
    $meta->removeFromStore();
    $this->assert(
        !Foswiki::Func::topicExists( $this->{test_web}, 'TestAuto001' ) );

    # Verify that we don't fill in missing holes.  Creates #3`
    $meta->topic('TestAutoAUTOINC001');
    $meta->save();
    $this->assert_str_equals( $meta->topic, "TestAuto003" );
    $this->assert(
        Foswiki::Func::topicExists( $this->{test_web}, 'TestAuto003' ) );

    # Verify that the suffix option works.
    $meta->topic('TestAutoAUTOINC001SUFFIX');
    $meta->save();
    $this->assert_str_equals( $meta->topic, "TestAuto001SUFFIX" );
    $this->assert(
        Foswiki::Func::topicExists( $this->{test_web}, 'TestAuto001SUFFIX' ) );

    $meta->topic('TestAutoAUTOINC001SUFFIX');
    $meta->save();
    $this->assert_str_equals( $meta->topic, "TestAuto002SUFFIX" );
    $this->assert(
        Foswiki::Func::topicExists( $this->{test_web}, 'TestAuto002SUFFIX' ) );

    $meta->finish();

    return;
}

sub test_Autoname_XXXXXXXXXX {
    my $this = shift;
    my $meta =
      Foswiki::Meta->new( $this->{session}, $this->{test_web},
        'TestAutoXXXXXXXXXX' );
    $this->assert_str_equals( $meta->topic, "TestAutoXXXXXXXXXX" );
    $meta->save();
    $this->assert_str_equals( 'TestAuto0', $meta->topic );
    $this->assert(
        Foswiki::Func::topicExists( $this->{test_web}, 'TestAuto0' ) );

    # Reset name and inseret another, should create #2
    $meta->topic('TestAutoXXXXXXXXXX');
    $meta->save();
    $this->assert_str_equals( 'TestAuto1', $meta->topic );
    $this->assert(
        Foswiki::Func::topicExists( $this->{test_web}, 'TestAuto1' ) );

    # Remove the first topic
    $meta->topic('TestAuto0');
    $meta->removeFromStore();
    $this->assert(
        !Foswiki::Func::topicExists( $this->{test_web}, 'TestAuto0' ) );

    # The old XXX method does fill in holes.
    $meta->topic('TestAutoXXXXXXXXXX');
    $meta->save();
    $this->assert_str_equals( 'TestAuto0', $meta->topic );
    $this->assert(
        Foswiki::Func::topicExists( $this->{test_web}, 'TestAuto0' ) );

    # At least 10 X.  9 just creates a topic.
    $meta->topic('TestAutoXXXXXXXXX');
    $meta->save();
    $this->assert_str_equals( 'TestAutoXXXXXXXXX', $meta->topic );
    $this->assert(
        Foswiki::Func::topicExists( $this->{test_web}, 'TestAutoXXXXXXXXX' ) );

    # 11 X,  also autoincrement.
    $meta->topic('TestAutoXXXXXXXXXXX');
    $meta->save();
    $this->assert_str_equals( 'TestAuto2', $meta->topic );
    $this->assert(
        Foswiki::Func::topicExists( $this->{test_web}, 'TestAuto2' ) );
    $meta->finish();

    return;
}

sub test_multiple {
    my $this = shift;
    my $meta =
      Foswiki::Meta->new( $this->{session}, $this->{test_web}, $topic );

    $meta->putKeyed( "FIELD", $args0 );
    my $vals = $meta->get( "FIELD", "a" );
    $this->assert_str_equals( $vals->{"name"},  "a" );
    $this->assert_str_equals( $vals->{"value"}, "1" );
    $this->assert( $meta->count("FIELD") == 1, "Should be one item" );

    $meta->putKeyed( "FIELD", $args1 );
    my $vals1 = $meta->get( "FIELD", "a" );
    $this->assert_str_equals( $vals1->{"name"},  "a" );
    $this->assert_str_equals( $vals1->{"value"}, "2" );
    $this->assert( $meta->count("FIELD") == 1, "Should be one item" );

    $meta->putKeyed( "FIELD", $args2 );
    $this->assert( $meta->count("FIELD") == 2, "Should be two items" );
    my $vals2 = $meta->get( "FIELD", "b" );
    $this->assert_str_equals( $vals2->{"name"},  "b" );
    $this->assert_str_equals( $vals2->{"value"}, "3" );
    $meta->finish();

    return;
}

# Field with value 0 and value ''  This does not cover Item8738
sub test_zero_empty {
    my $this = shift;
    my $meta =
      Foswiki::Meta->new( $this->{session}, $this->{test_web}, $topic );

    my $args_zero = {
        name  => "a",
        value => "0"
    };

    my $args_empty = {
        name  => "b",
        value => ""
    };

    $meta->putKeyed( "FIELD", $args_zero );
    $meta->putKeyed( "FIELD", $args_empty );

    my $vals1 = $meta->get( "FIELD", "a" );
    $this->assert_str_equals( $vals1->{"name"},  "a" );
    $this->assert_str_equals( $vals1->{"value"}, "0" );

    my $vals2 = $meta->get( "FIELD", "b" );
    $this->assert_str_equals( $vals2->{"name"},  "b" );
    $this->assert_str_equals( $vals2->{"value"}, "" );
    $meta->finish();

    return;
}

sub test_removeSingle {
    my $this = shift;
    my $meta =
      Foswiki::Meta->new( $this->{session}, $this->{test_web}, $topic );

    $meta->put( "TOPICINFO", $args0 );
    $this->assert( $meta->count("TOPICINFO") == 1, "Should be one item" );
    $meta->remove("TOPICINFO");
    $this->assert( $meta->count("TOPICINFO") == 0,
        "Should be no items after remove" );
    $meta->finish();

    return;
}

sub test_removeMultiple {
    my $this = shift;
    my $meta =
      Foswiki::Meta->new( $this->{session}, $this->{test_web}, $topic );

    $meta->putKeyed( "FIELD", $args0 );
    $meta->putKeyed( "FIELD", $args2 );
    $meta->put( "TOPICINFO", $args0 );
    $this->assert( $meta->count("FIELD") == 2, "Should be two items" );

    $meta->remove("FIELD");

    $this->assert( $meta->count("FIELD") == 0,
        "Should be no FIELD items after remove" );
    $this->assert( $meta->count("TOPICINFO") == 1, "Should be one item" );

    $meta->putKeyed( "FIELD", $args0 );
    $meta->putKeyed( "FIELD", $args2 );
    $meta->remove( "FIELD", "b" );
    $this->assert( $meta->count("FIELD") == 1,
        "Should be one FIELD items after partial remove" );
    $meta->finish();

    return;
}

sub test_foreach {
    my $this = shift;
    my $meta =
      Foswiki::Meta->new( $this->{session}, $this->{test_web}, $topic );

    $meta->putKeyed( "FIELD", { name => "a", value => "aval" } );
    $meta->putKeyed( "FIELD", { name => "b", value => "bval" } );
    $meta->put( "FINAGLE", { name => "a", value => "aval" } );
    $meta->put( "FINAGLE", { name => "b", value => "bval" } );

    my $d      = {};
    my $before = $meta->stringify();
    $meta->forEachSelectedValue( undef, undef, \&fleegle, $d );
    $this->assert( $d->{collected} =~ s/FINAGLE.name:b;// );
    $this->assert( $d->{collected} =~ s/FINAGLE.value:bval;// );
    $this->assert( $d->{collected} =~ s/FIELD.name:a;// );
    $this->assert( $d->{collected} =~ s/FIELD.value:aval;// );
    $this->assert( $d->{collected} =~ s/FIELD.name:b;// );
    $this->assert( $d->{collected} =~ s/FIELD.value:bval;// );
    $this->assert_str_equals( "",      $d->{collected} );
    $this->assert_str_equals( $before, $meta->stringify() );

    $meta->forEachSelectedValue( qr/^FIELD$/, undef, \&fleegle, $d );
    $this->assert( $d->{collected} =~ s/FIELD.name:a;// );
    $this->assert( $d->{collected} =~ s/FIELD.value:aval;// );
    $this->assert( $d->{collected} =~ s/FIELD.name:b;// );
    $this->assert( $d->{collected} =~ s/FIELD.value:bval;// );
    $this->assert_str_equals( "", $d->{collected} );

    $meta->forEachSelectedValue( qr/^FIELD$/, qr/^value$/, \&fleegle, $d );
    $this->assert( $d->{collected} =~ s/FIELD.value:aval;// );
    $this->assert( $d->{collected} =~ s/FIELD.value:bval;// );
    $this->assert_str_equals( "", $d->{collected} );

    $meta->forEachSelectedValue( undef, qr/^name$/, \&fleegle, $d );
    $this->assert( $d->{collected} =~ s/FINAGLE.name:b;// );
    $this->assert( $d->{collected} =~ s/FIELD.name:a;// );
    $this->assert( $d->{collected} =~ s/FIELD.name:b;// );
    $this->assert_str_equals( "", $d->{collected} );
    $meta->finish();

    return;
}

sub fleegle {
    my ( $t, $o ) = @_;
    $o->{collected} .= "$o->{_type}.$o->{_key}:$t;";
    return $t;
}

sub test_copyFrom {
    my $this = shift;
    my $meta =
      Foswiki::Meta->new( $this->{session}, $this->{test_web}, $topic );

    $meta->putKeyed( "FIELD", { name => "a", value => "aval" } );
    $meta->putKeyed( "FIELD", { name => "b", value => "bval" } );
    $meta->putKeyed( "FIELD", { name => "c", value => "cval" } );
    $meta->put( "FINAGLE", { name => "a", value => "aval" } );

    my $new = Foswiki::Meta->new( $this->{session}, $this->{test_web}, $topic );
    $new->copyFrom($meta);

    my $d = {};
    $new->forEachSelectedValue( qr/^F.*$/, qr/^value$/, \&fleegle, $d );
    $this->assert( $d->{collected} =~ s/FIELD.value:aval;// );
    $this->assert( $d->{collected} =~ s/FIELD.value:bval;// );
    $this->assert( $d->{collected} =~ s/FIELD.value:cval;// );
    $this->assert( $d->{collected} =~ s/FINAGLE.value:aval;// );
    $this->assert_str_equals( "", $d->{collected} );

    $new->finish();
    $new = Foswiki::Meta->new( $this->{session}, $this->{test_web}, $topic );
    $new->copyFrom( $meta, 'FIELD' );

    $new->forEachSelectedValue( qr/^FIELD$/, qr/^value$/, \&fleegle, $d );
    $this->assert( $d->{collected} =~ s/FIELD.value:aval;// );
    $this->assert( $d->{collected} =~ s/FIELD.value:bval;// );
    $this->assert( $d->{collected} =~ s/FIELD.value:cval;// );
    $this->assert_str_equals( "", $d->{collected} );

    $new->finish();
    $new = Foswiki::Meta->new( $this->{session}, $this->{test_web}, $topic );
    $new->copyFrom( $meta, 'FIELD', qr/^(a|b)$/ );
    $new->forEachSelectedValue( qr/^FIELD$/, qr/^value$/, \&fleegle, $d );
    $this->assert( $d->{collected} =~ s/FIELD.value:aval;// );
    $this->assert( $d->{collected} =~ s/FIELD.value:bval;// );
    $this->assert_str_equals( "", $d->{collected} );
    $new->finish();
    $meta->finish();

    return;
}

sub test_formfield {
    my $this = shift;

    my $m1 = Foswiki::Meta->new( $this->{session}, $this->{test_web}, $topic );
    $m1->put( "TOPICINFO", $args0 );
    $m1->putKeyed( "FORM", { name => "MetaTestsForm" } );
    $m1->putKeyed( "FIELD", $args3 );

    my $str = $m1->expandMacros('%META{"formfield" name="c" display="on"}%');
    $this->assert_str_equals( "one", $str );
    $str = $m1->expandMacros('%META{"formfield" name="c"}%');
    $this->assert_str_equals( "1", $str );

    $m1->finish();
}

sub test_parent {
    my $this = shift;
    my $web  = $this->{test_web};

    my $testTopic = "TestParent";
    for my $depth ( 1 .. 5 ) {
        my $child  = $testTopic . $depth;
        my $parent = $testTopic . ( $depth + 1 );
        my $text   = "This is ancestor number $depth";
        my $topicObject =
          Foswiki::Meta->new( $this->{session}, $web, $child, $text );
        $topicObject->put( "TOPICPARENT", { name => $parent } );
        $topicObject->save();
        $topicObject->finish();
    }
    my $ttopicObject = Foswiki::Meta->new(
        $this->{session}, $web,
        $testTopic . '6',
        'Final ancestor'
    );
    $ttopicObject->save();
    $ttopicObject->finish();

    for my $depth ( 1 .. 5 ) {
        my $child       = $testTopic . $depth;
        my $topicObject = Foswiki::Meta->load( $this->{session}, $web, $child );
        my $parent      = $topicObject->getParent();
        $this->assert_str_equals(
            $parent,
            $testTopic . ( $depth + 1 ),
            "getParent failed at depth $depth"
        );

        # Test basic parent
        my $str = $topicObject->expandMacros('%META{"parent"}%');
        $this->assert_str_equals(
            $str,
            join( " &gt; ",
                map { "[[$web.$testTopic$_][$testTopic$_]]" }
                  reverse $depth + 1 .. 6 )
        );

        # Test norecurse
        $str = $topicObject->expandMacros('%META{"parent" dontrecurse="on"}%');
        $this->assert_str_equals( $str, "[[$web.$parent][$parent]]" );

        # Test depth
        for my $subDepth ( 1 .. 5 - $depth ) {
            $str = $topicObject->expandMacros(
                '%META{"parent" depth="' . $subDepth . '"}%' );
            my $parentDepth = $subDepth + $depth;
            $this->assert_str_equals( $str,
                "[[$web.${testTopic}$parentDepth][${testTopic}$parentDepth]]" );
        }

        # Test prefix and suffix
        $str = $topicObject->expandMacros(
            '%META{"parent" prefix="Before" suffix="After"}%');
        $this->assert_str_equals(
            $str,
            "Before"
              . join( " &gt; ",
                map { "[[$web.$testTopic$_][$testTopic$_]]" }
                  reverse $depth + 1 .. 6 )
              . "After"
        );

        # Test format
        $str =
          $topicObject->expandMacros('%META{"parent" format="$web.$topic"}%');
        $this->assert_str_equals(
            $str,
            join( " &gt; ",
                map { "$web.$testTopic$_" } reverse $depth + 1 .. 6 )
        );

        # Test separator
        $str = $topicObject->expandMacros('%META{"parent" separator=" << "}%');
        $this->assert_str_equals(
            $str,
            join( " << ",
                map { "[[$web.$testTopic$_][$testTopic$_]]" }
                  reverse $depth + 1 .. 6 )
        );
        $topicObject->finish();
    }

    # Test nowebhome
    $ttopicObject = Foswiki::Meta->new(
        $this->{session}, $web,
        $testTopic . '6',
        'Final ancestor with WebHome as parent'
    );
    $ttopicObject->put( "TOPICPARENT",
        { name => $web . '.' . $Foswiki::cfg{HomeTopicName} } );
    $ttopicObject->save();
    $ttopicObject->finish();
    $ttopicObject =
      Foswiki::Meta->load( $this->{session}, $web, $testTopic . '1' );
    my $str = $ttopicObject->expandMacros('%META{"parent"}%');
    $this->assert_str_equals(
        $str,
        join( " &gt; ",
            map { "[[$web.$_][$_]]" }
              ( 'WebHome', map { "$testTopic$_" } reverse 2 .. 6 ) )
    );
    $str = $ttopicObject->expandMacros('%META{"parent" nowebhome="on"}%');
    $this->assert_str_equals(
        $str,
        join( " &gt; ",
            map { "[[$web.$testTopic$_][$testTopic$_]]" } reverse 2 .. 6 )
    );
    $ttopicObject->finish();

    return;
}

# Note: for full coverage, there needs to be at least one plugin with
# a beforeUploadHandler (and one with a beforeAttachmentHandler) for
# each of the following three attachment modes. Therefore they are repeated
# during the store tests.
sub test_attach_stream {
    my $this = shift;

    my $temp = File::Temp->new();
    print $temp 'eeza stream';

    # $fh->seek only in File::Temp 0.17 and later
    seek( $temp, 0, 0 );
    $this->{test_topicObject}->attach( name => 'dis.dat', stream => $temp );
    $this->assert( close($temp) );

    my $fh = $this->{test_topicObject}->openAttachment( 'dis.dat', '<' );
    my $x = <$fh>;
    $this->assert( close($fh) );
    $this->assert_str_equals( 'eeza stream', $x );

    return;
}

sub test_attach_file {
    my $this = shift;

    my $temp = File::Temp->new();
    print $temp 'eeza file';

    # $fh->seek only in File::Temp 0.17 and later
    seek( $temp, 0, 0 );
    $this->{test_topicObject}
      ->attach( name => 'dis.dat', file => $temp->filename );
    $this->assert( close($temp) );

    my $fh = $this->{test_topicObject}->openAttachment( 'dis.dat', '<' );
    my $x = <$fh>;
    $this->assert( close($fh) );
    $this->assert_str_equals( 'eeza file', $x );

    return;
}

sub test_attach_file_and_stream {
    my $this = shift;

    my $temp = File::Temp->new();
    print $temp 'eeza file and a stream';

    # $fh->seek only in File::Temp 0.17 and later
    seek( $temp, 0, 0 );
    $this->{test_topicObject}
      ->attach( name => 'dis.dat', stream => $temp, file => $temp->filename );
    $this->assert( close($temp) );

    my $fh = $this->{test_topicObject}->openAttachment( 'dis.dat', '<' );
    my $x = <$fh>;
    $this->assert( close($fh) );
    $this->assert_str_equals( 'eeza file and a stream', $x );

    return;
}

sub test_attachmentStreams {
    my $this = shift;

    #--- Simple write and read
    my $fh = $this->{test_topicObject}->openAttachment( 'dis.dat', '>' );
    $this->assert($fh);
    print $fh 'Twas brillig, and the slithy toves';
    $this->assert( close($fh) );

    $fh = $this->{test_topicObject}->openAttachment( 'dis.dat', '<' );
    $this->assert($fh);
    local $/ = undef;
    my $x = <$fh>;
    $this->assert( close($fh) );
    $this->assert_str_equals( 'Twas brillig, and the slithy toves', $x );

    #--- Appending write
    $fh = $this->{test_topicObject}->openAttachment( 'dis.dat', '>>' );
    $this->assert($fh);
    print $fh " did gyre and gimbal in the wabe";
    $this->assert( close($fh) );

    $fh = $this->{test_topicObject}->openAttachment( 'dis.dat', '<' );
    $x = <$fh>;
    $this->assert( close($fh) );
    $this->assert_str_equals(
        'Twas brillig, and the slithy toves did gyre and gimbal in the wabe',
        $x );

    #--- Reading older versions

    # Rev 1
    $fh = $this->{test_topicObject}->openAttachment( 'dis.dat', '<' );
    $this->{test_topicObject}->attach(
        name    => 'dat.dis',
        dontlog => 1,
        comment => "Shiver me timbers",
        hide    => 0,
        stream  => $fh
    );
    $this->assert( close($fh) );

    # Rev 2
    $fh = $this->{test_topicObject}->openAttachment( 'dis.dat', '>' );
    $this->assert($fh);
    print $fh "All mimsy were the borogroves";
    $this->assert( close($fh) );

    $fh = $this->{test_topicObject}->openAttachment( 'dis.dat', '<' );
    $this->{test_topicObject}->attach(
        name    => 'dat.dis',
        dontlog => 1,
        comment => "Pieces of eight",
        hide    => 0,
        stream  => $fh
    );
    $this->assert( close($fh) );
    $this->assert_equals( 2,
        $this->{test_topicObject}->getLatestRev('dat.dis') );

    # Latest rev (rev 2)
    $fh = $this->{test_topicObject}->openAttachment( 'dat.dis', '<' );
    $x = <$fh>;
    $this->assert( close($fh) );
    $this->assert_str_equals( 'All mimsy were the borogroves', $x );

    $fh =
      $this->{test_topicObject}->openAttachment( 'dat.dis', '<', version => 1 );
    $x = <$fh>;

    # Foswiki::Store::_MemoryFile::CLOSE returns undef :-(
    close($fh);
    $this->assert_str_equals(
        'Twas brillig, and the slithy toves did gyre and gimbal in the wabe',
        $x );

    $fh =
      $this->{test_topicObject}->openAttachment( 'dat.dis', '<', version => 2 );
    $x = <$fh>;

    # Foswiki::Store::_MemoryFile::CLOSE returns undef :-(
    close($fh);
    $this->assert_str_equals( 'All mimsy were the borogroves', $x );

    return;
}

sub test_testAttachment {
    my $this = shift;

    my $fh = $this->{test_topicObject}->openAttachment( 'dis.dat', '>' );
    print $fh "No! Not the bore worms!";

    #$this->assert( close($fh) );

    $fh = $this->{test_topicObject}->openAttachment( 'dis.dat', '<' );
    $this->{test_topicObject}->attach(
        name    => 'dat.dis',
        dontlog => 1,
        comment => "Pieces of eight",
        hide    => 0,
        stream  => $fh
    );

    my $t = time;
    $this->assert( $this->{test_topicObject}->hasAttachment('dat.dis') );

    $this->assert(
        $this->{test_topicObject}->testAttachment( 'dat.dis', 'e' ) );
    $this->assert(
        $this->{test_topicObject}->testAttachment( 'dat.dis', 'r' ) );
    $this->assert(
        $this->{test_topicObject}->testAttachment( 'dat.dis', 'w' ) );
    $this->assert(
        !$this->{test_topicObject}->testAttachment( 'dat.dis', 'z' ) );
    $this->assert_equals( 23,
        $this->{test_topicObject}->testAttachment( 'dat.dis', 's' ) );
    $this->assert(
        $this->{test_topicObject}->testAttachment( 'dat.dis', 'T' ) );
    $this->assert(
        !$this->{test_topicObject}->testAttachment( 'dat.dis', 'B' ) );
    $this->assert( $t,
        $this->{test_topicObject}->testAttachment( 'dat.dis', 'M' ) );
    $this->assert( $t,
        $this->{test_topicObject}->testAttachment( 'dat.dis', 'A' ) );

    return;
}

# Item10475.  Reading a undef attachment returns the topic text.
sub test_undef_attach {
    my $this = shift;
    $this->expect_failure('Undefined attachment should assert.');

# openAttachment of an undefined attachment returns the file handle for the topic.
# Assert in Meta should catch it.
    my $fh = $this->{test_topicObject}->openAttachment( undef, '<' );
    my $data = <$fh>;
    close $fh;

    $this->assert( length($data) );

    return;
}

# Make sure that badly-formed meta tags in text are validated on save
sub test_validateMetaTagsInText {
    my $this = shift;
    my $gunk = <<'GUNK';
%META{"form"}%
%META{"formfield" name="bad"}%
%META{"attachments"}%
%META{"parent"}%
%META{"moved"}%
GUNK
    my $text = <<"EVIL";
%META:TOPICINFO{bad="bad"}%
%META:TOPICPARENT{bad="bad"}%
%META:FORM{bad="bad"}%
%META:FIELD{bad="bad"}%
%META:FILEATTACHMENT{bad="bad"}%
%META:TOPICMOVED{bad="bad"}%
$gunk
EVIL

    my $topicObject =
      Foswiki::Meta->new( $this->{session}, $this->{test_web}, "BadMeta",
        $text );

    $this->assert_equals( $text, $topicObject->text() . "\n" );
    $topicObject->save();

    # SMELL: setEmbeddedStoreForm has been eating two newlines by now,
    # yet the serializer refused to remove the bad META records either.
    # ... a rather pathological unit test.
    $this->assert_equals( $text, $topicObject->text() . "\n" );

    $topicObject->expandMacros( $topicObject->text() );
    $topicObject->expandNewTopic();
    $topicObject->renderTML( $topicObject->text() );
    $topicObject->renderFormForDisplay();
    $text = $topicObject->text();
    $this->assert_matches( qr/%META:TOPICINFO\{bad="bad"\}%/,      $text );
    $this->assert_matches( qr/%META:TOPICPARENT\{bad="bad"\}%/,    $text );
    $this->assert_matches( qr/%META:FORM\{bad="bad"\}%/,           $text );
    $this->assert_matches( qr/%META:FIELD\{bad="bad"\}%/,          $text );
    $this->assert_matches( qr/%META:FILEATTACHMENT\{bad="bad"\}%/, $text );
    $this->assert_matches( qr/%META:TOPICMOVED\{bad="bad"\}%/,     $text );
    $this->assert_does_not_match( qr/%META:TOPICMOVED\{\}%/, $text );

    # Item2554
    $text = <<'EVIL';
%META:TOPICPARENT{}%
EVIL
    $topicObject->finish();
    $topicObject =
      Foswiki::Meta->new( $this->{session}, $this->{test_web}, "BadMeta",
        $text );
    $topicObject->save();
    $text = $topicObject->text();
    $this->assert_does_not_match( qr/%META:TOPICPARENT\{\}%/, $text );

    $text = <<"GOOD";
%META:TOPICINFO{version="1" date="9876543210" author="AlbertCamus" format="1.1"}%
%META:TOPICPARENT{name="System.UserForm"}%
%META:FORM{name="System.UserForm"}%
%META:FIELD{name="Profession" value="Saint"}%
%META:FILEATTACHMENT{name="sausage.gif"}%
%META:TOPICMOVED{from="here" to="there" by="her" date="1234567890"}%
$gunk
GOOD
    $topicObject->finish();
    $topicObject =
      Foswiki::Meta->new( $this->{session}, $this->{test_web}, "GoodMeta",
        $text );
    $topicObject->save();
    $this->assert_equals( $gunk, $topicObject->text() );
    $topicObject->expandMacros( $topicObject->text() );
    $topicObject->expandNewTopic();
    $topicObject->renderTML( $topicObject->text() );
    $topicObject->renderFormForDisplay();
    $topicObject->finish();

    return;
}

sub test_registerMETA {
    my $this = shift;

    my $o = Foswiki::Meta->new( $this->{session} );

    # Check an unregistered tag
    $this->assert(
        Foswiki::Meta::isValidEmbedding(
            'TREE', { type => 'ash', height => '15' }
        )
    );
    $this->assert( Foswiki::Meta::isValidEmbedding( 'TREE', {} ) );

    # required param
    Foswiki::Func::registerMETA( 'TREE', require => ['spread'] );
    $this->assert( !Foswiki::Meta::isValidEmbedding( 'TREE', {} ) );
    $this->assert(
        !Foswiki::Meta::isValidEmbedding(
            'TREE', { type => 'ash', height => '15' }
        )
    );
    $this->assert(
        Foswiki::Meta::isValidEmbedding(
            'TREE', { type => 'ash', height => '15', spread => '5' }
        )
    );

    # required param and allowed param
    Foswiki::Func::registerMETA(
        'TREE',
        require => ['spread'],
        allow   => ['height']
    );
    $this->assert(
        !Foswiki::Meta::isValidEmbedding(
            'TREE', { type => 'ash', height => '15', spread => '5' }
        )
    );
    $this->assert(
        Foswiki::Meta::isValidEmbedding(
            'TREE', { spread => '5', height => '15' }
        )
    );

    # Function and require.
    Foswiki::Func::registerMETA(
        'TREE',
        require  => ['height'],
        function => sub {
            my ( $name, $args ) = @_;
            $this->assert_equals( 'TREE', $name );
            return $args->{spread};
        }
    );
    $this->assert(
        !Foswiki::Meta::isValidEmbedding( 'TREE', { height => 10 } ) );

    # required param, allowed param and function
    Foswiki::Func::registerMETA(
        'TREE',
        require  => ['spread'],
        allow    => ['height'],
        function => sub {
            my ( $name, $args ) = @_;
            $this->assert_equals( 'TREE', $name );
            $this->assert( $args->{spread} );
            $this->assert( $args->{height} );
            return 1;
        }
    );
    $this->assert(
        Foswiki::Meta::isValidEmbedding(
            'TREE', { spread => 15, height => 10 }
        ),
        $Foswiki::Meta::reason
    );

    # allowed param only, function rewrites args
    Foswiki::Func::registerMETA(
        'TREE',
        allow    => ['height'],
        function => sub {
            my ( $name, $args ) = @_;
            $this->assert_equals( 'TREE', $name );
            delete $args->{spread};
            return 1;
        }
    );
    $this->assert(
        !Foswiki::Meta::isValidEmbedding(
            'TREE', { type => 'elm', height => '15' }
        )
    );
    $this->assert(
        Foswiki::Meta::isValidEmbedding( 'TREE', { height => '15' } ) );
    $this->assert(
        Foswiki::Meta::isValidEmbedding(
            'TREE', { spread => '5', height => '15' }
        )
    );
    $o->finish();

    return;
}

# Item9948
sub test_registerArrayMeta {
    my $this = shift;
    my $test = <<'TEST';
Properties: %QUERY{"META:SLPROPERTY.name"}%
A property: %QUERY{"slug[name='PreyOf'].values"}%
Values: %QUERY{"META:SLPROPERTYVALUE.value"}%
TEST
    my $text = <<'HERE';
%META:SLPROPERTYVALUE{name="System.SemanticIsPartOf__1" value="System.UserDocumentationCategory"}%
%META:SLPROPERTYVALUE{name="Example.Property__1" value="UserDocumentationCategory"}%
%META:SLPROPERTYVALUE{name="PreyOf__1" value="Snakes"}%
%META:SLPROPERTYVALUE{name="Eat__1" value="Mosquitos"}%
%META:SLPROPERTYVALUE{name="Eat__2" value="Flies"}%
%META:SLPROPERTYVALUE{name="IsPartOf__1" value="UserDocumentationCategory"}%
%META:SLPROPERTY{name="System.SemanticIsPartOf" values="System.UserDocumentationCategory"}%
%META:SLPROPERTY{name="Example.Property" values="UserDocumentationCategory"}%
%META:SLPROPERTY{name="PreyOf" values="Snakes"}%
%META:SLPROPERTY{name="Eat" values="Mosquitos,Flies"}%
%META:SLPROPERTY{name="IsPartOf" values="UserDocumentationCategory"}%
HERE
    Foswiki::Meta::registerMETA(
        'SLPROPERTY',
        many    => 1,
        alias   => 'slug',
        require => [qw(name values)],
    );
    Foswiki::Meta::registerMETA(
        'SLPROPERTYVALUE',
        many    => 1,
        require => [qw(name value)],
    );
    my $topicObject =
      Foswiki::Meta->new( $this->{session}, $this->{test_web},
        "registerArrayMetaTest", $text );
    $topicObject->save();

    # All meta should have found its way into text
    $this->assert_equals( <<'EXPECTED', $topicObject->expandMacros($test) );
Properties: System.SemanticIsPartOf,Example.Property,PreyOf,Eat,IsPartOf
A property: Snakes
Values: System.UserDocumentationCategory,UserDocumentationCategory,Snakes,Mosquitos,Flies,UserDocumentationCategory
EXPECTED
    $topicObject->finish();

    return;
}

# Item9948
sub test_registerScalarMeta {
    my $this = shift;
    my $test = <<'TEST';
Properties: %QUERY{"META:SLPROPERTY.name"}%
Alias: %QUERY{"slug.name"}%
Values: %QUERY{"META:SLPROPERTYVALUE.value"}%
TEST
    my $text = <<'HERE';
%META:SLPROPERTYVALUE{name="System.SemanticIsPartOf__1" value="System.UserDocumentationCategory"}%
%META:SLPROPERTYVALUE{name="Example.Property__1" value="UserDocumentationCategory"}%
%META:SLPROPERTYVALUE{name="PreyOf__1" value="Snakes"}%
%META:SLPROPERTYVALUE{name="Eat__1" value="Mosquitos"}%
%META:SLPROPERTYVALUE{name="Eat__2" value="Flies"}%
%META:SLPROPERTYVALUE{name="IsPartOf__1" value="UserDocumentationCategory"}%
%META:SLPROPERTY{name="System.SemanticIsPartOf" values="System.UserDocumentationCategory"}%
%META:SLPROPERTY{name="Example.Property" values="UserDocumentationCategory"}%
%META:SLPROPERTY{name="PreyOf" values="Snakes"}%
%META:SLPROPERTY{name="Eat" values="Mosquitos,Flies"}%
%META:SLPROPERTY{name="IsPartOf" values="UserDocumentationCategory"}%
HERE
    Foswiki::Meta::registerMETA(
        'SLPROPERTY',
        alias   => 'slug',
        require => [qw(name values)],
    );
    Foswiki::Meta::registerMETA( 'SLPROPERTYVALUE',
        require => [qw(name value)], );
    my $topicObject =
      Foswiki::Meta->new( $this->{session}, $this->{test_web},
        "registerArrayMetaTest", $text );
    $topicObject->save();

    # All meta should have found its way into text
    $this->assert_equals( <<'EXPECTED', $topicObject->expandMacros($test) );
Properties: System.SemanticIsPartOf
Alias: System.SemanticIsPartOf
Values: System.UserDocumentationCategory
EXPECTED
    $topicObject->finish();

    return;
}

sub test_getRevisionHistory {
    my $this = shift;
    my $topicObject =
      Foswiki::Meta->new( $this->{session}, $this->{test_web}, 'RevIt',
        "Rev 1" );
    $this->assert_equals( 1, $topicObject->save() );
    $topicObject->finish();
    $topicObject =
      Foswiki::Meta->load( $this->{session}, $this->{test_web}, 'RevIt' );
    my $revIt = $topicObject->getRevisionHistory();
    $this->assert( $revIt->hasNext() );
    $this->assert_equals( 1, $revIt->next() );
    $this->assert( !$revIt->hasNext() );

    $topicObject->text('Rev 2');
    $this->assert_equals( 2, $topicObject->save( forcenewrevision => 1 ) );
    $topicObject->finish();
    $topicObject =
      Foswiki::Meta->load( $this->{session}, $this->{test_web}, 'RevIt' );
    $revIt = $topicObject->getRevisionHistory();
    $this->assert( $revIt->hasNext() );
    $this->assert_equals( 2, $revIt->next() );
    $this->assert( $revIt->hasNext() );
    $this->assert_equals( 1, $revIt->next() );
    $this->assert( !$revIt->hasNext() );

    $topicObject->text('Rev 3');
    $this->assert_equals( 3, $topicObject->save( forcenewrevision => 1 ) );
    $topicObject->finish();
    $topicObject =
      Foswiki::Meta->load( $this->{session}, $this->{test_web}, 'RevIt' );
    $revIt = $topicObject->getRevisionHistory();
    $this->assert( $revIt->hasNext() );
    $this->assert_equals( 3, $revIt->next() );
    $this->assert( $revIt->hasNext() );
    $this->assert_equals( 2, $revIt->next() );
    $this->assert( $revIt->hasNext() );
    $this->assert_equals( 1, $revIt->next() );
    $this->assert( !$revIt->hasNext() );
    $topicObject->finish();

    return;
}

sub test_summariseChanges {
    my $this = shift;
    my $topicObject =
      Foswiki::Meta->new( $this->{session}, $this->{test_web}, 'RevIt',
        "Line 1\n\nLine 2\n\nLine 3" );
    $this->assert_equals( 1, $topicObject->save() );
    $topicObject->finish();
    $topicObject =
      Foswiki::Meta->load( $this->{session}, $this->{test_web}, 'RevIt' );
    my $revIt = $topicObject->getRevisionHistory();
    $this->assert( $revIt->hasNext() );
    $this->assert_equals( 1, $revIt->next() );
    $this->assert( !$revIt->hasNext() );

    #print "REV1 \n(".$topicObject->text().")\n";

    $topicObject->text("Line 1\n\nLine 3");
    $this->assert_equals( 2, $topicObject->save( forcenewrevision => 1 ) );
    $topicObject->finish();
    $topicObject =
      Foswiki::Meta->load( $this->{session}, $this->{test_web}, 'RevIt' );
    $revIt = $topicObject->getRevisionHistory();
    $this->assert( $revIt->hasNext() );
    $this->assert_equals( 2, $revIt->next() );
    $this->assert( $revIt->hasNext() );
    $this->assert_equals( 1, $revIt->next() );
    $this->assert( !$revIt->hasNext() );

    #print "REV2 \n(".$topicObject->text().")\n";

    $topicObject->text("Line 1\n<nop>SomeOtherData\nLine 3");
    $this->assert_equals( 3, $topicObject->save( forcenewrevision => 1 ) );
    $topicObject->finish();
    $topicObject =
      Foswiki::Meta->load( $this->{session}, $this->{test_web}, 'RevIt' );
    $revIt = $topicObject->getRevisionHistory();
    $this->assert( $revIt->hasNext() );
    $this->assert_equals( 3, $revIt->next() );
    $this->assert( $revIt->hasNext() );
    $this->assert_equals( 2, $revIt->next() );
    $this->assert( $revIt->hasNext() );
    $this->assert_equals( 1, $revIt->next() );
    $this->assert( !$revIt->hasNext() );

    #print "REV3 \n(".$topicObject->text().")\n";

    # Verify the plain text summary
    my $diff = $topicObject->summariseChanges( '1', '3', 0 );

    #print "\nTEXT rev1:rev3\n====\n" . $diff . "\n====\n\n";
    my $expected = <<'RESULT';
 Line 1
-Line 2
+<nop>SomeOtherData
 Line 3
RESULT
    chomp $expected;
    $this->assert_equals( $expected, $diff );

# Verify the HTML summary
#print "\nHTML rev1:rev3\n" . $topicObject->summariseChanges('1', '3', 1) . "\n";
    $this->assert_equals(
" Line 1<br /><del>Line 2</del><br /><ins>SomeOtherData</ins><br /> Line 3",
        $topicObject->summariseChanges( '1', '3', 1 )
    );

    # Verify default summary - should be text for rev 3 vs. rev 2
    $diff     = $topicObject->summariseChanges();
    $expected = qr/^ Line 1
\+<nop>SomeOtherData
 Line 3$/ms;

   #print "This summary doesn't make any sense: comparing rev2:rev3\n($diff)\n";
   #print "\nTEXT rev2:rev3\n====\n" . $diff . "\n====\n\n";
    $this->assert_matches( $expected, $diff );

# Verify the HTML default summary
#print "\nThis summary doesn't make any sense either:  comparing rev2:rev3\n(" . $topicObject->summariseChanges(undef,undef,1) . ")\n";
    $expected = qr#^ Line 1<br /><ins>SomeOtherData</ins><br /> Line 3$#;
    $this->assert_matches( $expected,
        $topicObject->summariseChanges( undef, undef, 1 ) );

    #$topicObject =
    #  Foswiki::Meta->load($this->{session}, $this->{test_web}, 'RevIt', '1' );
    #print "REV1 \n====\n".$topicObject->text()."\n====\n";
    #$topicObject =
    #  Foswiki::Meta->load($this->{session}, $this->{test_web}, 'RevIt', '2' );
    #print "REV2 \n====\n".$topicObject->text()."\n====\n";
    #$topicObject =
    #  Foswiki::Meta->load($this->{session}, $this->{test_web}, 'RevIt', '3' );
    #print "REV3 \n====\n".$topicObject->text()."\n====\n";
    $topicObject->finish();

    return;
}

sub test_haveAccess {
    my $this = shift;

    my $topicObject =
      Foswiki::Meta->new( $this->{session}, $this->{test_web}, 'WebHome' );
    $this->assert( $topicObject->haveAccess('VIEW') );
    $this->assert( $topicObject->haveAccess('CHANGE') );
    $topicObject->finish();

    my $webObject = Foswiki::Meta->new( $this->{session}, $this->{test_web} );
    $this->assert( $webObject->haveAccess('VIEW') );
    $this->assert( $webObject->haveAccess('CHANGE') );
    $webObject->finish();

    my $rootObject = Foswiki::Meta->new( $this->{session} );
    $this->assert( $rootObject->haveAccess('VIEW') );
    $this->assert( not $rootObject->haveAccess('CHANGE') );
    $rootObject->finish();

    return;
}

#Item10789 - TOPICINFO should only come from the first line of the topic
#thankyou TemiVarghese for finding it!
sub test_setEmbededStoreForm_DOUBLE {
    my $this = shift;

    my $meta =
      Foswiki::Meta->new( $this->{session}, $this->{test_web}, 'TestTopic' );
    $meta->setEmbeddedStoreForm(<<'HERE');
%META:TOPICINFO{author="TemiVarghese" comment="reprev" date="1306913758" format="1.1" reprev="10" version="10"}%
%META:TOPICPARENT{name="PhyloWidgetPlugin"}%
<!--
This topic is part of the documentation for PhyloWidgetPlugin and is
automatically generated from Subversion. You can edit it, but if you do,
please make sure the maintainer of the extension knows about your changes,
otherwise your edits might be lost the next time the topic is uploaded.

If you want to report an error in the topic, please raise a report at
http://foswiki.org/Tasks/PhyloWidgetPlugin
-->
%META:TOPICINFO{author="ProjectContributor" format="1.1" version="$Rev$"}%
%META:TOPICPARENT{name="PhyloWidgetPlugin"}%
#VarNEXUSTREES
---+++ NEXUSTREES{"Topic"} -- display phylogeny
 and more
HERE

    my $ti = $meta->get('TOPICINFO');
    $this->assert_equals( 'TemiVarghese', $ti->{author} );
    $this->assert_equals( 10,             $ti->{version} );
    $this->assert_equals( 1306913758,     $ti->{date} );
    $meta->finish();

    return;
}

sub test_setEmbededStoreForm_NotFirstLine {
    my $this = shift;

    my $meta =
      Foswiki::Meta->new( $this->{session}, $this->{test_web}, 'TestTopic' );
    $meta->setEmbeddedStoreForm(<<'HERE');
SOMETHING ELSE
%META:TOPICINFO{author="TemiVarghese" comment="reprev" date="1306913758" format="1.1" reprev="10" version="10"}%
%META:TOPICPARENT{name="PhyloWidgetPlugin"}%
<!--
This topic is part of the documentation for PhyloWidgetPlugin and is
automatically generated from Subversion. You can edit it, but if you do,
please make sure the maintainer of the extension knows about your changes,
otherwise your edits might be lost the next time the topic is uploaded.

If you want to report an error in the topic, please raise a report at
http://foswiki.org/Tasks/PhyloWidgetPlugin
-->
%META:TOPICINFO{author="ProjectContributor" format="1.1" version="$Rev$"}%
%META:TOPICPARENT{name="PhyloWidgetPlugin"}%
#VarNEXUSTREES
---+++ NEXUSTREES{"Topic"} -- display phylogeny
 and more
HERE

    #you're not supposed to access TOPICINFO like this :(
    my $ti = $meta->get('TOPICINFO');
    $this->assert_equals( undef, $ti->{author} );
    $this->assert_equals( undef, $ti->{version} );
    $this->assert_equals( undef, $ti->{date} );

    $ti = $meta->getRevisionInfo();
    $this->assert_equals( 'BaseUserMapping_666', $ti->{author} );
    $this->assert_equals( 0,                     $ti->{version} );
    $this->assert_equals( 0,                     $ti->{date} );
    $meta->finish();

    return;
}

# Disabled as XML functionnality has been removed from the core, see Foswikitask:Item1917
# sub testXML_topic {
#     my $this = shift;
#
#     my $text = <<GOOD;
# %META:TOPICINFO{version="1.2" date="9876543210" author="AlbertCamus" format="1.1"}%
# %META:TOPICPARENT{name="System.UserForm"}%
# %META:FORM{name="System.UserForm"}%
# %META:FIELD{name="Profession" value="Saint"}%
# %META:FILEATTACHMENT{name="sausage.gif"}%
# %META:TOPICMOVED{from="here" to="there" by="her" date="1234567890"}%
# Green eggs and ham
# GOOD
#     my $expected = <<'XML';
# <topic name="GoodMeta" format="1.1" date="@REX(\d+)" version="1.2" rev="2" author="AlbertCamus">
#  <form name="System.UserForm">
#   <field value="Saint" name="Profession" />
#  </form>
#  <fileattachment name="sausage.gif" />
#  <topicmoved to="there" date="@REX(\d+)" from="here" by="her" />
#  <topicparent name="System.UserForm" />
#  <body>
#   <![CDATA[Green eggs and ham]]>
#  </body>
# </topic>
# XML
#     my $topicObject =
#       Foswiki::Meta->new(
#           $this->{session}, $this->{test_web}, "GoodMeta", $text );
#     my $xml = $topicObject->xml();
#     $this->assert_html_equals($expected, $xml);
# }
#
# sub testXML_web {
#     my $this = shift;
#     my $webObject = Foswiki::Meta->new( $this->{session}, "$this->{test_web}/SubWeb" );
#     $webObject->populateNewWeb();
#     my $expected = <<'XML';
# <web name="SubWeb">
#  <topic name="WebPreferences" format="1.1" version="1.1" date="@REX(\d+)" rev="1" author="BaseUserMapping_666">
#   <body><![CDATA[Preferences]]>
#   </body>
#  </topic>
# </web>
# XML
#     my $xml = $webObject->xml();
#     $this->assert_html_equals($expected, $xml);
#
#     $expected = <<'XML';
# <web name="TemporaryMetaTestsTestWebMetaTests">
#  <web name="SubWeb">
#   <topic name="WebPreferences" format="1.1" version="1.1" date="@REX(\d+)" rev="1" author="BaseUserMapping_666">
#    <body><![CDATA[Preferences]]>
#    </body>
#   </topic>
#  </web>
# </web>
# XML
#     $xml = $webObject->xml(1);
#     $this->assert_html_equals($expected, $xml);
#
#     $expected = <<'XML';
# <web name="TemporaryMetaTestsTestWebMetaTests">
#  <topic name="TestTopicMetaTests" format="1.1" version="1.1" date="@REX(\d+)" rev="1" author="BaseUserMapping_666">
#   <body>
#    <![CDATA[BLEEGLE
# ]]>
#   </body>
#  </topic>
#  <topic name="WebPreferences" format="1.1" version="1.1" date="@REX(\d+)" rev="1" author="BaseUserMapping_666">
#   <body>
#    <![CDATA[Preferences]]>
#   </body>
#  </topic>
#  <web name="SubWeb">
#   <topic name="WebPreferences" format="1.1" version="1.1" date="@REX(\d+)" rev="1" author="BaseUserMapping_666">
#    <body><![CDATA[Preferences]]>
#    </body>
#   </topic>
#  </web>
# </web>
# XML
#     my $topicObject =
#       Foswiki::Meta->new( $this->{session}, $this->{test_web} );
#     $xml = $topicObject->xml();
#     $this->assert_html_equals($expected, $xml);
# }

1;
