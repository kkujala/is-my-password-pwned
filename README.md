# is-my-password-pwned

## About

This is small bash script for checking if a password is compromised. That is
if a password has been leaked in data breaches and effectively known to the
world.

This script creates a sha1 hash and queries a service maintained by
[haveibeenpwned](https://haveibeenpwned.com/). It sends a partial sha1 hash to
the service in order to avoid revealing the plain text password. For further
information on how this protects the password, please read about
[k-anonymity](https://en.wikipedia.org/wiki/K-anonymity) and this blog post
about the service
[pwned passwords](https://www.troyhunt.com/ive-just-launched-pwned-passwords-version-2/).

## Purpose

This script is created for the sole purpose to be able to check whether a
password is compromised in an easy way via the command line. It can be run
securely from one's own machine.

## Requirements

This script needs bash, cat, curl, sha1sum and a shell where to execute these
commands.

## How to use

First clone the repo and then run the bash script.

    $ ./is-my-password-pwned.sh

For more options run with this option.

    $ ./is-my-password-pwned.sh -h

Alternatively, the script can be run like this without needing to clone. It
shoule be noted this requires trust to run scripts like this, hence it is not
really recommended.

    $ bash <(curl --fail --show-error --silent https://raw.githubusercontent.com/kkujala/is-my-password-pwned/master/is-my-password-pwned.sh)

