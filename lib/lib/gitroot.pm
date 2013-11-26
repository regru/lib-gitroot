package lib::gitroot;

use Modern::Perl;
use File::Spec;
use lib ();

our $_GIT_ROOT = undef;

sub GIT_ROOT { $_GIT_ROOT };

our %_default_values = ( lib => 'lib' );

sub import
{
    my ($class, %args) = map { /^:(.*)$/ ? ($1 => $_default_values{$1} || 1) : $_ } @_;
    $args{set_root} = 1 if defined $args{lib};

    my ($module, $filename) = caller;

    if ($args{set_root}) {

        die "Git Root aready set" if defined $_GIT_ROOT;

        $filename //= $args{path};
        my $absfilename = File::Spec->rel2abs($filename);
        $_GIT_ROOT = _find_git_dir( $absfilename, -d $filename );
        lib->import($_GIT_ROOT.'/'.$args{lib}) if defined $args{lib} and defined $_GIT_ROOT;
    }


    no strict 'refs';
    *{"$module\::GIT_ROOT"} = \&GIT_ROOT;
    use strict 'refs';
}

sub _is_dir
{
    -d shift();
}

sub _find_git_dir
{
    my ($abspath, $is_dir) = @_;
    my @dirs = File::Spec->splitdir ( $abspath );
    pop @dirs unless $is_dir;
    while (@dirs) {
        my $gitdir = File::Spec->catdir(@dirs, '.git');
        if (_is_dir($gitdir)) {
            return File::Spec->catdir(@dirs);
        }
        pop @dirs;
    }
    return;
}


1;
