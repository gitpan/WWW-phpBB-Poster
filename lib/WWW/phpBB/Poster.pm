package WWW::phpBB::Poster;

use strict;
use warnings;

our $VERSION = '0.01';
use DBI;
use Digest::MD5 qw[md5_hex];

=head1 NAME

WWW::phpBB::Poster - phpBB forum poster

=head1 SYNOPSIS

    use WWW::phpBB::Poster;

    # scrape as guest
    my $phpbb   =   WWW::phpBB::Poster->new({
        base_url    =>  'http://localhost/forum',
        db_host     =>  'localhost',
        db_user     =>  'root',
        db_password =>  'somepass',
        db_database =>  'forum',
        db_prefix   =>  'phpbb_',
        db_type     =>  'mysql',
        db_charset  =>  'utf8'
    });
    
    if(!$phpbb){
        die(qq[Cannot establish connection!\n]);
    }
    my $forums_list = $phpbb->getForums();
    

=head1 DESCRIPTION

I wrote this module for own purposes - exactly for generating SEO-ready forums, already filled in with some parsed data.
Hope, it shall be useful for you :)

P.S. It handles only MySQL or SQLite phpBB installation.

P.P.S. It is NOT suggested for fork using - if so - you may got strange results with posts and topics.
If you want to use this module with forks - please, fix it manually for InnoDB using - commiting, etc.

=head1 REQUIRED MODULES

L<DBI>

L<Digest::MD5>

=head1 EXPORT

None.

=head1 CONSTRUCTOR

=head2 new()

Creates a new WWW::phpBB::Poster object.

Required parameters:

HASH REF: 
=over 4


=item * C<< db_user => $mysql_user >>

=item * C<< db_database => $mysql_db >>

Database with an already installed phpBB forum.

=back

Optional parameters:
HASH REF: 
=over 4
=item * C<< db_host => $sql_host >>

By default, sets to localhost

=item * C<< db_password => $sql_password >>

By default, sets to empty

=item * C<< db_prefix => $phpbb_prefix >>

By default, sets to phpbb_

=item * C<< db_port => $sql_port >>

By default, sets to 3306

=item * C<< db_charset => q[CP1251] >>

By default, sets to UTF8

=item * C<< db_type => q[SQLite] >>

By default, sets to MySQL

=back
=cut
sub new {
    my ($self, $params) = @_;
    return undef if ref($params) ne q[HASH];
    return undef if !$params->{db_user};
    return undef if !$params->{db_database};
    $params->{db_host}      =   q[localhost]    if  !$params->{db_host};    
    $params->{db_password}  =   q[]             if  !$params->{db_password};
    $params->{db_prefix}    =   q[phpbb_]       if  !$params->{db_prefix};
    $params->{db_port}      =   3306            if  !$params->{db_port};
    $params->{db_charset}   =   q[UTF8]         if  !$params->{db_charset};
    $params->{db_type}      =   q[mysql]        if  !$params->{db_type};
    
    return undef if $params->{db_prefix} !~ /^[a-z_\d]*$/i;
    
    $self = {};
    if($params->{db_type} =~ /^mysql$/i){
        $self->{db} = DBI->connect(qq[DBI:$params->{db_type}:database=$params->{db_database};host=$params->{db_host};port=$params->{db_port}], $params->{db_user}, $params->{db_password},{AutoCommit => 1, PrintError=>1});
    }
    else{
        if(-f $params->{db_database}){
            $self->{db} = DBI->connect(qq[DBI:$params->{db_type}:database=$params->{db_database}], $params->{db_user}, $params->{db_password});
        }
    }
    return undef if !$self->{db};
    $self->{db}->do(qq[SET NAMES $params->{db_charset}]);
    $self->{db_prefix} = $params->{db_prefix};
    bless($self);
    return $self;
}

=head1 PUBLIC METHODS

=head2 $phpbb->setUser()

Tries to select user from DB, if none - tries to insert user into DB.
Returns ID of user.

Required parameters:
HASH REF: 
=over 1

=item * C<< login => q[Vasya] >>

=back

Optional parameters:
HASH REF: 
=over 7

=item * C<< password => $phpbb_hash_password >>

By default, sets with 'qwerty312', hashed with phpBB

=item * C<< email => $user_email >>

By default, sets to first 10 symbols of md5(rand(100))@first 10 symbols of md5(rand(100)).ru

=item * C<< created => time >>

By default, sets to current time

=item * C<< user_type => 0 >>

By default, sets to 0 (USER_NORMAL)

=item * C<< group_id => 2 >>

By default, sets to 2 (REGISTERED)

=item * C<< user_from => 'Moscow' >>

By default, sets to empty value

=item * C<< user_regdate => time >>

By default, sets to current time
=back

=cut
sub setUser {
    my ($self, $params) = @_;
    return undef if ref($params) ne q[HASH];
    return undef if !$params->{login};

    my $userID = $self->{db}->selectrow_array(qq[SELECT user_id FROM $self->{db_prefix}users WHERE username = ?], undef, $params->{login});
    return $userID if $userID;
    $params->{user_type}    =   0 if !$params->{user_type};
    $params->{email}        =   substr(md5_hex(rand(100000)),0,10).q[@].(md5_hex(rand(100000))).q[.ru] if !$params->{email};
    $params->{password}     =   q[$H$9acO.NmmXrWMkCGOXtVnvPlznCr9KP1] if !$params->{password}; # qwerty312
    $params->{user_from}    =   q[] if !$params->{user_from};
    $params->{group_id}     =   2 if !$params->{group_id};
    $params->{user_regdate} =   time() if !$params->{user_regdate};

    $self->{db}->do(
                    qq[
                        INSERT INTO $self->{db_prefix}users
                        SET
                            user_type = ?,      /* 1 */
                            user_regdate = ?,   /* 2 */
                            username = ?,       /* 3 */
                            username_clean = ?, /* 4 */
                            user_password = ?,  /* 5 */
                            user_email = ?,     /* 6 */
                            user_from = ?,      /* 7 */
                            group_id = ?        /* 8 */,
                            user_colour = ''
                    ],
                    undef,
                        $params->{user_type},       # 1
                        $params->{user_regdate},    # 2 
                        $params->{login},           # 3
                        $params->{login},           # 4
                        $params->{password},        # 5
                        $params->{email},           # 6
                        $params->{user_from},       # 7
                        $params->{group_id}         # 8
                );
    
    $userID =   $self->{db}->selectrow_array(q[SELECT LAST_INSERT_ID()]);
    $self->{db}->do(qq[INSERT INTO $self->{db_prefix}user_group SET group_id=?, user_id=?], undef, $params->{group_id}, $userID);
    return $userID;
}

=head2 $phpbb->getUser($intUserID)
Gets user data by ID. Returns a hash of values
=over 8
=item * C<< userID >>
=item * C<< user_type >>
=item * C<< user_regdate >>
=item * C<< login >>
=item * C<< password >>
=item * C<< email >>
=item * C<< user_from >>
=item * C<< group_id >>
=back
=cut
sub getUser {
    my ($self, $userID) = @_;
    return undef if !$userID || $userID !~ /^\d+$/;
    return $self->{db}->selectrow_hashref(qq[SELECT user_id as userID, user_type, user_regdate, username as `login`, user_password as `password`, user_email as email, user_from, group_id FROM $self->{db_prefix}users WHERE user_id=$userID]);
}
=head2 $phpbb->getForumList()

Selects all forums, having parent id (exactly forums, not categories) from DB. Returns a ref to an array, where first key is forum ID, and second - forum name.
=cut
sub getForumList {
    my $self = shift;
    return $self->{db}->selectall_arrayref(qq[SELECT forum_id, forum_name FROM $self->{db_prefix}forums WHERE parent_id<>0]);
}

=head2 $phpbb->setTopic()

Tries to select topic by title and forum id from DB, if none - tries to insert topic into DB and then makes necessary updates with other tables and increases the user post count.

Returns ID of topic.

Required parameters:
HASH REF: 
=over 4

=item * C<< title => q[My first topic] >>
=item * C<< text => q[Content of topic] >>
=item * C<< forumID => 2 >>
=item * C<< userID => 2 >>
ID 1 - Anonymous
ID 2 - admin

=back

Optional parameters:
HASH REF: 
=item * C<< created => time() >>

By default, sets with current time

=item * C<< sync_forums => 0/1 >>

By default - 1 - syncing forum stats after topic adding;

=back
=cut
sub setTopic {
    my ($self, $params) = @_;
    return undef if ref($params) ne q[HASH];
    return undef if !$params->{text};
    return undef if !$params->{title};
    return undef if !$params->{userID} || $params->{userID} !~ /^\d+$/;
    return undef if !$params->{forumID} || $params->{forumID} !~ /^\d+$/;
    
    $params->{created}      = time()    if !$params->{created};
    $params->{sync_forums}  = 1         if !$params->{sync_forums};
    
    my $topicID = $self->{db}->selectrow_array(qq[SELECT topic_id FROM $self->{db_prefix}topics WHERE topic_title=? AND forum_id=?], undef, $params->{title}, $params->{forumID});
    
    if(!$topicID){
        my $user_name = $self->{db}->selectrow_array(qq[SELECT username FROM $self->{db_prefix}users WHERE user_id=?], undef, $params->{userID});
        return undef if !$user_name;
        $self->{db}->do(qq[
                            INSERT INTO $self->{db_prefix}topics
                            SET
                                topic_title = ?,                /* 1 */      
                                forum_id = ?,                   /* 2 */
                                topic_poster = ?,               /* 3 */
                                topic_first_poster_name = ?,    /* 4 */
                                topic_last_poster_id = ?,       /* 5 */
                                topic_last_poster_name = ?,     /* 6 */
                                topic_last_post_subject =?,     /* 7 */
                                topic_last_post_time = ?,       /* 8 */
                                topic_time = ?                  /* 9 */
                        ], undef,
                                $params->{title},   # 1
                                $params->{forumID}, # 2
                                $params->{userID},  # 3
                                $user_name,         # 4
                                $params->{userID},  # 5
                                $user_name,         # 6
                                $params->{title},   # 7
                                $params->{created}, # 8
                                $params->{created}  # 9
                    );
        $topicID = $self->{db}->selectrow_array(q[SELECT LAST_INSERT_ID()]);
        return undef if !$topicID;
        
        $self->{db}->do(qq[INSERT INTO $self->{db_prefix}topics_posted SET user_id=?, topic_id=?, topic_posted=1], undef, $params->{userID}, $topicID);
        
        my $postID = $self->setPost({
                                        topicID     =>  $topicID,
                                        forumID     =>  $params->{forumID},
                                        userID      =>  $params->{userID},
                                        created     =>  $params->{created},
                                        user_name   =>  $user_name,       
                                        title       =>  \$params->{title},
                                        text        =>  \$params->{text},
                                        sync_forums =>  $params->{sync_forums},
                                        first_post  =>  1
                            });
        if(!$postID){
            $self->{db}->do(qq[DELETE FROM $self->{db_prefix}topics WHERE topic_id=?], undef, $topicID);
            $self->{db}->do(qq[DELETE FROM $self->{db_prefix}topics_posted WHERE topic_id=?], undef, $topicID);
            return undef;
        }
        $self->{db}->do(qq[UPDATE $self->{db_prefix}topics SET topic_first_post_id=?, topic_last_post_id=? WHERE topic_id=?], undef, $postID, $postID, $topicID);
    }
    
    return $topicID;
}
=head2 $phpbb->getTopic($intTopicID)
Gets topic data by ID. Returns a hash of values

=over 11
=item * C<< topic_title >>
=item * C<< forum_id >>
=item * C<< topic_poster >>
=item * C<< topic_first_poster_name >>
=item * C<< topic_last_poster_id >>
=item * C<< topic_last_poster_name >>
=item * C<< topic_last_post_subject >>
=item * C<< topic_last_post_time >>
=item * C<< topic_time >>
=item * C<< topic_first_post_id >>
=item * C<< topic_last_post_id >>
=back
=cut
sub getTopic {
    my ($self, $topicID) = @_;
    return undef if !$topicID || $topicID !~ /^\d+$/;
    return $self->{db}->selectrow_hashref(qq[
                                            SELECT
                                                topic_title,
                                                forum_id,
                                                topic_poster,
                                                topic_first_poster_name,
                                                topic_last_poster_id ,
                                                topic_last_poster_name,
                                                topic_last_post_subject,
                                                topic_last_post_time,
                                                topic_time,
                                                topic_first_post_id,
                                                topic_last_post_id
                                            FROM
                                                $self->{db_prefix}topics
                                            WHERE topic_id=$topicID
                                        ]);
}

=head2 $phpbb->setPost()

Adds post content to topic.

Returns ID of post or undef if no such topic or user.

Required parameters:
HASH REF: 
=over 4

=item * C<< title => q[My first topic] >>
=item * C<< text => q[Content of topic] >>
=item * C<< forumID => 2 >>
=item * C<< userID => 2 >>
ID 1 - Anonymous
ID 2 - admin

=back

Optional parameters:
HASH REF: 
=item * C<< created => time() >>

By default, sets with current time

=item * C<< sync_forums => 0/1 >>

By default - 1 - syncing forum stats after post adding;

=item * C<< first_post => 0/1 >>

By default - 0 - adds 'Re: ' to the post title;


=back
=cut
sub setPost {
    my ($self, $params) = @_;
    return undef if ref($params) ne q[HASH];
    return undef if !$params->{text};
    return undef if !$params->{title};
    return undef if ref($params->{text})    ne q[SCALAR];
    return undef if ref($params->{title})   ne q[SCALAR];
    
    return undef if !$params->{userID}  || $params->{userID}    !~ /^\d+$/;
    return undef if !$params->{forumID} || $params->{forumID}   !~ /^\d+$/;
    return undef if !$params->{topicID} || $params->{topicID}   !~ /^\d+$/;    

    ${$params->{title}} = q[Re: ].${$params->{title}} if !$params->{first_post} && ${$params->{title}} !~ /^Re:\s+/;
    
    $params->{created}      = time()    if !$params->{created};
    $params->{sync_forums}  = 1         if !$params->{sync_forums};
    
    $params->{user_name} = $self->{db}->selectrow_array(qq[SELECT username FROM $self->{db_prefix}users WHERE user_id = ?], undef, $params->{userID});
    
    return undef if !$params->{user_name};   
    return undef if !$self->{db}->selectrow_array(qq[SELECT topic_id FROM $self->{db_prefix}topics WHERE topic_id=?], undef, $params->{topicID});
    
    $self->{db}->do(qq[
                        INSERT INTO $self->{db_prefix}posts
                        SET
                            topic_id = ?,       /* 1 */
                            forum_id = ?,       /* 2 */
                            poster_id = ?,      /* 3 */
                            post_time = ?,      /* 4 */
                            post_username = ?,  /* 5 */
                            post_subject = ?,   /* 6 */
                            post_text = ?       /* 7 */
                        ],
                        undef,
                            $params->{topicID},     # 1
                            $params->{forumID},     # 2
                            $params->{userID},      # 3
                            $params->{created},     # 4
                            $params->{user_name},   # 5
                            ${$params->{title}},    # 6
                            ${$params->{text}}      # 7
                    );
    my $postID = $self->{db}->selectrow_array(q[SELECT LAST_INSERT_ID()]);
    $self->{db}->do(qq[UPDATE $self->{db_prefix}users SET user_posts=user_posts+1 WHERE user_id=?], undef, $params->{userID}) if $postID;
    if(!$params->{first_post} && $postID){
        
        $self->{db}->do(qq[
                            UPDATE $self->{db_prefix}topics
                            SET
                                topic_last_post_id = ?,                     /* 1 */
                                topic_replies = topic_replies+1,
                                topic_replies_real = topic_replies_real+1,
                                topic_last_poster_id = ?,                   /* 2 */
                                topic_last_poster_name = ?,                 /* 3 */
                                topic_last_post_subject = ?,                /* 4 */
                                topic_last_post_time = ?                    /* 5 */
                            WHERE
                                topic_id=?                                  /* 6 */
                        ],
                        undef,
                            $postID,                # 1
                            $params->{userID},      # 2
                            $params->{user_name},   # 3
                            ${$params->{title}},    # 4
                            $params->{created},     # 5
                            $params->{topicID}      # 6
                        );
    }
    return undef if $self->{db}->errstr;
    $self->syncForums($params->{forumID}) if $params->{sync_forums};
    return $postID;    
}


=head2 $phpbb->getTopicList($intLimit)
Gets topics list.
If limit is undefined, method will return you the whole list of topics.
Return format: array of arrays - first key is topic ID, second - topic name.
=cut
sub getTopicList {
    my ($self, $limit) = @_;
    $limit = 10 if !$limit;
    return undef if $limit !~ /^\d+$/;
    $limit = $limit ? q[ LIMIT ].$limit : q[];
    return $self->{db}->selectall_arrayref(qq[SELECT topic_id, topic_title FROM $self->{db_prefix}topics].$limit);
}

=head2 $phpbb->syncForums()

Syncs forum's count of posts, topics, post_id, poster_id.
=cut
sub syncForums {
    my ($self, $forumID) = @_;
    return undef if !$forumID || $forumID !~ /^\d+$/;
    my ($l_post_id, $l_poster_id, $l_post_subject, $l_post_time, $l_poster_name) = $self->{db}->selectrow_array(qq[SELECT post_id, poster_id, post_subject, post_time, post_username FROM $self->{db_prefix}posts WHERE forum_id = ? ORDER BY post_id DESC LIMIT 1], undef, $forumID);
    my $c_posts = $self->{db}->selectrow_array(qq[SELECT COUNT(*) FROM $self->{db_prefix}posts WHERE forum_id = ?], undef, $forumID);
    my $c_topics = $self->{db}->selectrow_array(qq[SELECT COUNT(*) FROM $self->{db_prefix}topics WHERE forum_id = ?], undef, $forumID);
    $self->{db}->do(qq[
                        UPDATE
                            $self->{db_prefix}forums
                        SET
                            forum_posts = ?,                /* 1 */
                            forum_topics = ?,               /* 2 */
                            forum_topics_real = ?,          /* 3 */
                            forum_last_post_id = ?,         /* 4 */
                            forum_last_poster_id = ?,       /* 5 */
                            forum_last_post_subject = ?,    /* 6 */
                            forum_last_post_time = ?,       /* 7 */
                            forum_last_poster_name = ?      /* 8 */
                        WHERE
                            forum_id = ?                    /* 9 */
                        ],
                        undef,
                            $c_posts,                       # 1
                            $c_topics,                      # 2
                            $c_topics,                      # 3
                            $l_post_id,                     # 4
                            $l_poster_id,                   # 5
                            $l_post_subject,                # 6
                            $l_post_time,                   # 7
                            $l_poster_name,                 # 8
                            $forumID                        # 9
                );
}

1;
__END__


=head1 AUTHOR

Andrew Jumash, E<lt>skazo4nik@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Andrew Jumash

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut

1;
__END__
