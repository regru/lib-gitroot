package lib::gitroot;

# VERSION

use Modern::Perl;
use File::Spec;
use lib ();

our $_GIT_ROOT = undef;

sub GIT_ROOT { $_GIT_ROOT };

our %_default_values = ( lib => 'lib' );

# :set_root
# :lib (implies :set_root, same as lib => 'lib')
# lib => library path
# use_base_dir => 'somedir_or_filename'
sub import
{
    my ($class, %args) = map { /^:(.*)$/ ? ($1 => $_default_values{$1} || 1) : $_ } @_;
    $args{set_root} = 1 if defined $args{lib};

    my ($module, $filename) = caller;
    $filename = $args{use_base_dir} if defined $args{use_base_dir};

    if ($args{set_root}) {

        if (defined $_GIT_ROOT) {
            die "Git Root already set" unless $args{once};
        } else {
            $filename //= $args{path};
            my $absfilename = File::Spec->rel2abs($filename);
            $_GIT_ROOT = _find_git_dir( $absfilename, _is_dir($filename) );
            lib->import($_GIT_ROOT.'/'.$args{lib}) if defined $args{lib} and defined $_GIT_ROOT;
        }
    }


    no strict 'refs';
    no warnings 'redefine';
    *{"$module\::GIT_ROOT"} = \&GIT_ROOT;
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

__END__

=pod

=encoding utf-8

=head1 NAME

lib::gitroot - locate .git root at compile time and use as lib path

=head1 SYNOPSIS

    use lib::gitroot qw/:set_root/;

Finds git root and export GIT_ROOT function to current package. Will die if called several times from different places.

    use lib::gitroot qw/:lib/;

Finds git root, export GIT_ROOT function to current package and adds GIT_ROOT/lib to @INC. Will die if called several times from different places.

    use lib::gitroot qw/:set_root :once/;

Same as :set_root, but will not die if called from different places (instead will use first found GIT_ROOT)

    use lib::gitroot qw/:lib :once/;

Similar to :set_root :once

    use lib::gitroot lib => 'mylib';

Use GIT_ROOT/mylib instead

    use lib::gitroot;

Exports GIT_ROOT hoping that it's set previously or will be set in the future

    use lib::gitroot ':lib', use_base_dir => "/some/path";

Use some path, instead of caller filename, for searching for git

=head1 AUTHOR

Victor Efimov <lt>efimov@reg.ruE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2012-2013 by REG.RU LLC

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
