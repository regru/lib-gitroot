#!/usr/bin/env perl

use Test::More tests => 27;
use Modern::Perl;
use lib::gitroot ();
use File::Spec;
use Test::Spec;
use Test::Deep;

sub localize_gitroot
{
    my $cb = pop;
    my ($val) = @_;
    local $lib::gitroot::_GIT_ROOT = $val;
    no warnings 'once';
    local *main::GIT_ROOT = sub { undef };
    $cb->();
}

$SIG{__WARN__} = sub { die @_ };

describe "libgitroot" => sub {
    describe "lib" => sub {
        it "should work" => sub {
            localize_gitroot sub {
                File::Spec->expects('rel2abs')->returns("mockfilename");
                lib::gitroot->expects('_is_dir')->returns(0);
                lib::gitroot->expects('_find_git_dir')->returns(sub{
                    cmp_deeply [@_], ["mockfilename", bool(0)];
                    "mockroot";
                });
                lib->expects('import')->returns(sub{
                    shift;
                    cmp_deeply [@_], ['mockroot/lib'];
                });
                is GIT_ROOT(), undef;
                lib::gitroot->import(':lib');
                is GIT_ROOT(), "mockroot";
            };
        };
        it "should work with custom library" => sub {
            localize_gitroot sub {
                File::Spec->expects('rel2abs')->returns("mockfilename");
                lib::gitroot->expects('_is_dir')->returns(0);
                lib::gitroot->expects('_find_git_dir')->returns("mockroot");
                lib->expects('import')->returns(sub{
                    shift;
                    cmp_deeply [@_], ['mockroot/somelib'];
                });
                is GIT_ROOT(), undef;
                lib::gitroot->import(lib => 'somelib');
                is GIT_ROOT(), "mockroot";
            };
        };
        it "should work with custom base dir" => sub {
            localize_gitroot sub {
                File::Spec->expects('rel2abs')->returns(sub{
                    shift;
                    cmp_deeply [@_], ['some/dir'];
                    "mockfilename"
                });
                lib::gitroot->expects('_is_dir')->returns(0);
                lib::gitroot->expects('_find_git_dir')->returns("mockroot");
                lib->expects('import')->returns(sub{
                    shift;
                    cmp_deeply [@_], ['mockroot/somelib'];
                });
                is GIT_ROOT(), undef;
                lib::gitroot->import(lib => 'somelib', use_base_dir => 'some/dir');
                is GIT_ROOT(), "mockroot";
            };
        };
        it "should work when directory" => sub {
            localize_gitroot sub {
                File::Spec->expects('rel2abs')->returns("mockfilename");
                lib::gitroot->expects('_is_dir')->returns(1);
                lib::gitroot->expects('_find_git_dir')->returns(sub{
                    cmp_deeply [@_], ["mockfilename", bool(1)];
                    "mockroot";
                });
                lib->expects('import')->returns(sub{
                    shift;
                    cmp_deeply [@_], ['mockroot/lib'];
                });
                is GIT_ROOT(), undef;
                lib::gitroot->import(':lib');
                is GIT_ROOT(), "mockroot";
            };
        };
        it "should die when git root already defined" => sub {
            localize_gitroot "someroot", sub {
                ok ! eval { lib::gitroot->import(':lib'); 1};
                like $@, qr/Git Root already set/;
            };
        };
        it "should work with 'once'" => sub {
            localize_gitroot "someroot", sub {
                File::Spec->expects('rel2abs')->never;
                lib::gitroot->expects('_is_dir')->never;
                lib::gitroot->expects('_find_git_dir')->never;
                lib->expects('import')->never;
                is GIT_ROOT(), undef;
                lib::gitroot->import(':lib', ':once');
                is GIT_ROOT(), "someroot";
            };
        };
    };
    describe "set_root" => sub {
        it "should work" => sub {
            localize_gitroot sub {
                File::Spec->expects('rel2abs')->returns("mockfilename");
                lib::gitroot->expects('_is_dir')->returns(0);
                lib::gitroot->expects('_find_git_dir')->returns(sub{
                    cmp_deeply [@_], ["mockfilename", bool(0)];
                    "mockroot";
                });
                lib->expects('import')->never;
                is GIT_ROOT(), undef;
                lib::gitroot->import(':set_root');
                is GIT_ROOT(), "mockroot";
            };
        };
        it "should work when directory" => sub {
            localize_gitroot sub {
                File::Spec->expects('rel2abs')->returns("mockfilename");
                lib::gitroot->expects('_is_dir')->returns(1);
                lib::gitroot->expects('_find_git_dir')->returns(sub{
                    cmp_deeply [@_], ["mockfilename", bool(1)];
                    "mockroot";
                });
                lib->expects('import')->never;
                is GIT_ROOT(), undef;
                lib::gitroot->import(':set_root');
                is GIT_ROOT(), "mockroot";
            };
        };
        it "should die when git root already defined" => sub {
            localize_gitroot "someroot", sub {
                ok ! eval { lib::gitroot->import(':set_root'); 1};
                like $@, qr/Git Root already set/;
            };
        };
    };
};

runtests unless caller;