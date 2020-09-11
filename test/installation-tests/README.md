# Testing installation of ruby-cbc

Since there have been numerous problems with the installation of ruby-cbc on different platforms,
I have set up some tests for installing ruby-cbc in different environments.

These tests use docker, and thus only test linux distributions.
These tests use the production ruby-cbc gem, installing it with `gem install ruby-cbc`.

To run it:

```bash
ruby tests.rb
```

For each distribution (1 per dockerfile), we install ruby-cbc, and run a little sample to make sure
everything is ok.
