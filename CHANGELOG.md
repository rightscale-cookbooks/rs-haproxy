rs-haproxy Cookbook CHANGELOG
=======================

This file is used to list changes made in each version of the rs-haproxy cookbook.

v1.1.1
------

- Enable/disable schedule to periodically run rs-haproxy::frontend.

v1.1.0
------

- Installs HAProxy 1.5.1
- Created `rs-haproxy::schedule` recipe
- HAProxy logs via rsyslog to `/var/log/haproxy.log`
- HAProxy version determined by name of source file
- In `rs-haproxy::frontend`, if no application servers are discovered, do nothing
- Created rspec tests for `rs-haproxy::schedule`

v1.0.0
------

- Initial release
