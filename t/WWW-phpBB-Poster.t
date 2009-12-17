#!/usr/bin/perl

use warnings;
use strict;

use Test::More tests    => 11;
use Data::Dumper;
use Encode qw(decode);

BEGIN {
    diag("************* Test WWW::phpBB::Poster *************");
    use_ok('WWW::phpBB::Poster');
    use_ok('DBI');
    use_ok('Digest::MD5');
}

my $params = {};
$params->{db_host}      =   q[localhost];
$params->{db_port}      =   3306;
$params->{db_prefix}    =   q[phpbb_];
#$params->{db_password}  =   q[];
#$params->{db_user}      =   q[];
#$params->{db_database}  =   q[];
my $skipMySQL           =   0;
my $createMySQLStruct   =   0;
my $sql_struct_file     =   "./struct.sql";
sub round {
    my $double = shift;
    return undef if $double !~ /^\d+\.\d+$/;
    return $1 if $double =~ /^(\d+)/;
    return $double;
}

sub init {
    use WWW::phpBB::Poster;
    my $phpBB = new WWW::phpBB::Poster({
                                            db_user     =>  $params->{db_user},
                                            db_password =>  $params->{db_password},
                                            db_database =>  $params->{db_database},
                                            db_prefix   =>  $params->{db_prefix},
                                            db_host     =>  $params->{db_host},
                                            db_port     =>  $params->{db_port}
                                    });
    return $phpBB;
}
sub t_connect {
    
    my $phpBB = init();
    return 0 if !$phpBB;
    return 1;
}

sub t_get_forums {
    my $phpBB = init();
    return 0 if !$phpBB;
    print "\t[*] Fetching forums list...\n";
    my $forums_list = $phpBB->getForumList();
    if(ref($forums_list) eq q[ARRAY]){
        foreach(@$forums_list){
            print $_->[0]." => ".$_->[1]."\n";
        }
        print "\t[+] Done!\n";
        return 1;
    }
    return 0;
}
sub t_get_user {
    use Digest::MD5 qw(md5_hex);

    my $phpBB = init();
    return 0 if !$phpBB;
    my $username = q[User].(round(rand(1000))+time());
    print "\t[*] Testing username $username with one parameter ... \n";
    my $userID = $phpBB->setUser({login   =>  $username});
    if(!$userID){
        print "\t[-] No user ID!\n";
        return 0;
    }
    print "\t[+] Got userID = $userID\n";
    print "\t[*] Testing username $username for same selection... \n";
    my $newUserID = $phpBB->setUser({login   =>  $username});
    return 0 if !$newUserID;
    if($newUserID != $userID){
        print "\t[-] User ID's not the same!\n";
        return 0;
    }
    print "\t[+] User ID's are the same, resuming...\n";
    print "\t[*] Generating new username...\n";
    my $x = $username;
    while($x eq $username){
        $username = q[User].(round(rand(1000))+time());
    }
    print "\t[+] New username: $username\n";
    
    ($userID, $newUserID) = (undef, undef);
    
    print "Ready to register username with random data...\n";
    my $user_params = {};
    
    $user_params->{login}           =   $username;
    $user_params->{email}           =   q[test@test.ru];
    $user_params->{user_type}       =   round(rand(10));
    $user_params->{group_id}        =   round(rand(100));
    $user_params->{user_from}       =   q[Moscow];
    $user_params->{password}        =   md5_hex(rand(1000));
    $user_params->{user_regdate}    =   time()-10400;
    
    
    print "\t[*] Data for new user $username:\n";
    foreach(keys %$user_params){
        print "\t$_\t=>\t$user_params->{$_}\n";
    }
    print "\t[*] Setting up user $username ...\n";
    $userID = $phpBB->setUser($user_params);
    if(!$userID){
        print "\t[-] No user ID!\n";
        return 0;
    }
    print "\t[+] Got user ID = $userID\n";
    print "\t[*] Testing username $username for same selection... \n";
    $newUserID = $phpBB->setUser($user_params);
    if(!$newUserID){
        print "\t[-] No user ID!\n";
        return 0;
    }
    if($newUserID != $userID){
        print "\t[-] User ID's not the same!\n";
        return 0;
    }
    print "\t[+] User ID's are the same, resuming...\n";
    print "\t[*] Selecting user's data $username [$userID]\n";
    my $userData = $phpBB->getUser($userID);
    if(!$userData || ref($userData) ne q[HASH]){
        print "\t[-] Failed selecting user data!\n";
        return 0;
    }
    
    $user_params->{userID} = $userID;
    print "\t[*] Looking for same data...\n";
    my $r = 1;
    foreach (keys %$userData){
        if(!exists $user_params->{$_}){
            print "\t[-] No original param '$_'\n";
            $r = 0;
        }
        elsif($userData->{$_} ne $user_params->{$_}){
            print "\t[-] Gotten $_ param [$userData->{$_}] not equals with original param [$user_params->{$_}]\n";
            $r = 0;
        }
        else{
            print "\t[+] OK $_ param [$userData->{$_}] eq with original param [$user_params->{$_}]\n";
        }
    }
    return $r;
}

sub t_start_topic {
    my $phpBB = init();
    return 0 if !$phpBB;
    my $username    =   q[User].round(rand(1000));
    my $title       =   q[Test topic].round(rand(1000));
    my $text        =   q[Lorem ipsum ]x10;
    print "\t[*] Setting user for topic...\n";
    my $userID = $phpBB->setUser({login=>$username});
    return 0 if !$userID;
    my $forumsList = $phpBB->getForumList();
    return 0 if !$forumsList->[0]->[0];
    
    print "\t[*] Setting topic...\n";
    print "\t[*] Title: $title\n";
    print "\t[*] Text: $text\n";
    print "\t[*] User: $username [$userID] \n";
    print "\t[*] Forum: $forumsList->[0]->[1] [$forumsList->[0]->[1]]\n";
    my $topicID = $phpBB->setTopic({forumID=>$forumsList->[0]->[0], userID=>$userID, title=>$title, text=>$text});
    if(!$topicID){
        print "\t[-] No topic ID\n";
        return 0;
    }
    print "\t[+] Got topic ID $topicID\n";
    print "\t[*] Getting topic data for comparison\n";
    my $topicData = $phpBB->getTopic($topicID);
    if(!$topicData || ref($topicData) ne q[HASH]){
        print "\t[-] No topic data returned\n";
        return 0;
    }
    
    print "\t[*] Checking for null values for $topicID\n";
    my $r = undef;
    foreach(keys %$topicData){
        if($topicData->{$_} =~ /^[0\s]*$/){
            print "\t[-] NULL [$topicData->{$_}] for $_\n";
            $r = 1;    
        }
        else{
            print "\t[+]\t$_\t=>\t$topicData->{$_}\n";
        }
    }
    return 0 if $r;
    return 1;
}
sub t_generate_posts {
    my $phpBB = init();
    return 0 if !$phpBB;
    
    print "\t[*] Generating users...\n";
    my $usersList = [];
    for(1..10){
        my $userID = $phpBB->setUser({login=>q[User].round(rand(100))});
        if(!$userID){
            print "\t[-] Failed on $_ try getting user ID\n";
            return 0;
        }
        push(@$usersList,$userID);
    }
    print "\t[+] Users done, ".scalar(@$usersList)." elements\n";
    print "\t[*] Making topic for test\n";
    my $username    =   q[User].round(rand(1000));
    my $title       =   q[Test post topic].round(rand(1000));
    my $text        =   q[Lorem ipsum ]x10;
    print "\t[*] Setting user for topic...\n";
    my $userID = $phpBB->setUser({login=>$username});
    return 0 if !$userID;
    my $forumsList = $phpBB->getForumList();
    return 0 if !$forumsList->[0]->[0];
    
    print "\t[*] Setting topic...\n";
    print "\t[*] Title: $title\n";
    print "\t[*] Text: $text\n";
    print "\t[*] User: $username [$userID] \n";
    print "\t[*] Forum: $forumsList->[0]->[1] [$forumsList->[0]->[0]]\n";
    my $topicID = $phpBB->setTopic({forumID=>$forumsList->[0]->[0], userID=>$userID, title=>$title, text=>$text});
    if(!$topicID){
        print "\t[-] No topic ID\n";
        return 0;
    }
    print "\t[+] Got topic ID $topicID\n";
    my $postsNum = round(rand(1000));
    print "\t[*] Making $postsNum posts in $topicID\n";
    for(0..$postsNum){
        $userID = qq($usersList->[rand((@$usersList))]);
        my $postID = $phpBB->setPost({userID=>$userID, forumID=>$forumsList->[0]->[0], topicID=>$topicID, title=>\$title, text=>\$text});
        if(!$postID){
            print "\t[-] Failed creating post $_ for user $userID forum $forumsList->[0]->[0] topicID $topicID\n";
            return 0;
        }
        #print "\t[+] OK with $_\n";
    }
    return 1;
}
sub t_sync_forums {
    my $phpBB = init();
    return 0 if !$phpBB;
    print "\t[*] Getting forums list\n";
    my $forumsList = $phpBB->getForumList();
    foreach(@$forumsList){
        print "\t[*] Trying to sync $_->[1] [$_->[0]]\n";
        if(!$phpBB->syncForums($_->[0])){
            print "\t[-] Failed with $_->[0]\n";
            return 0;
        }
        print "\t[+] OK with $_->[0]\n";
    }
    return 1;
}

sub t_db_create{
    use DBI;
    my $dbh = DBI->connect(qq[DBI:mysql:host=$params->{db_host};port=$params->{db_port}], $params->{db_user}, $params->{db_password},{AutoCommit => 1, PrintError=>1});
    return 0 if !$dbh;
    if(!$dbh->do(qq[CREATE DATABASE IF NOT EXISTS $params->{db_database}])){
        print "\t[-] Cannot create database $params->{db_database}";
        return 0;
    }
    
    $dbh->do(qq[USE $params->{db_database}]);
    return 0 if $dbh->errstr;
    $dbh->do(q[SET NAMES UTF8]);
    return 0 if $dbh->errstr;
    return 0 if !-f "$sql_struct_file";
    open FF,"<$sql_struct_file";
    my $x = <FF>;
    my @struct = split(";",$x);
    foreach(@struct){
        $dbh->do($_) if $_ !~ /^\s*$/sm;
        return 0 if $dbh->errstr;
    }  
    return 1;
}
sub t_db_delete {
    use DBI;
    my $dbh = DBI->connect(qq[DBI:mysql:host=$params->{db_host};port=$params->{db_port}], $params->{db_user}, $params->{db_password},{AutoCommit => 1, PrintError=>1});
    return 0 if !$dbh;
    if(!$dbh->do(qq[DROP DATABASE $params->{db_database}])){
        print "\t[-] Cannot drop database $params->{db_database}";
        return 0;
    }
    return 1;
}
sub askFor {
    my $msg = shift;
    print $msg." [Y/n] : ";
    my $answer = <STDIN>;
    chop $answer;
    return 1 if $answer =~ /^\s*$/;
    return 1 if $answer =~ /^y$/i;
    return 0;
}
sub getSTD {
    my ($field, $human_name) = @_;
    while(1){
        print qq[Please, enter $human_name];
        print " [$params->{$field}]" if exists $params->{$field};
        print qq[: ];
        my $tmp = <STDIN>;
        chop($tmp);
        
        next if !$tmp && !exists $params->{$field};
        $params->{$field} = $tmp if $tmp;
        print "\nGot ".$params->{$field}." ...OK\n";
        last;
    }
}
my $skipAll = 0;
if(-t STDIN && -t STDOUT){
    if(!askFor("Do you want test MySQL operations with phpBB?")){
        $skipMySQL = 1;
    }
    else{
        if(-f $sql_struct_file){
            $createMySQLStruct = 1 if askFor("May i create a test DB for tests? (acceptable login and password need)");
        }
        getSTD('db_host', 'MySQL host');
        getSTD('db_port', 'MySQL port');
        getSTD('db_user', 'MySQL user');
        getSTD('db_password', 'MySQL password');
        getSTD('db_database', 'MySQL database with phpBB');
        getSTD('db_prefix', 'phpBB tables prefix') if !$createMySQLStruct;
    }
}
else{
    $skipAll = 1;
}
SKIP: {
    skip(q[No terminal found!], 8) if $skipAll;
    skip(q[Skipping without MySQL tests!], 8) if $skipMySQL;
    SKIP: {
        skip(q[Skipping creation of struct],1) if !$createMySQLStruct;
        ok(t_db_create, 'Creating phpBB struct');
    }
    ok(t_connect, 'Testing phpBB initialization');
    ok(t_get_forums, 'Getting forums list');
    ok(t_get_user, 'Testing user manipulations');
    ok(t_start_topic, 'Testing topic creation');
    ok(t_generate_posts, 'Testing post generation');    
    ok(t_sync_forums, 'Testing forums syncing');
    skip(q[Skipping deleting struct], 1) if !$createMySQLStruct;
    ok(t_db_delete, 'Deleting phpBB struct');
}