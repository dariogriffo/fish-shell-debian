# Make fish's builtin man pages reachable.
#
# The pages for builtins (string, abbr, argparse, ...) live in a private
# directory rather than /usr/share/man, because fish's builtin set includes
# echo, test, kill, printf, true and false, whose pages would otherwise
# overwrite the coreutils ones.
#
# Upstream's own `man` wrapper prepends $__fish_data_dir/man, but that is empty
# in the self-contained binary this package ships, so wire it up here instead.
#
# Appended, not prepended: the system pages keep priority, so `man echo` still
# shows the coreutils page and only fish-specific pages resolve here. The empty
# first element is what tells man(1) to search its default path as well —
# without it, setting MANPATH would replace the default path entirely.
if not set -q MANPATH
    set -gx MANPATH ''
end
if not contains /usr/share/fish/man $MANPATH
    set -gx MANPATH $MANPATH /usr/share/fish/man
end
