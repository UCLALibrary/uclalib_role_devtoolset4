# uclalib_role_devtoolset4 [![Build Status](https://travis-ci.org/UCLALibrary/uclalib_role_devtoolset4.svg?branch=master)](https://travis-ci.org/UCLALibrary/uclalib_role_devtoolset4)

Ansible role to install devtoolset-4 on CentOS 6. It should work on RHEL 6, too, but has not yet been tested there.

## Default Variables

dt4_packages: ['devtoolset-4-gcc.x86_64', 'devtoolset-4-gcc-c++.x86_64', 'devtoolset-4-libstdc++-devel.x86_64']

### These values can be overridden in a playbook:

    ---
    
    - hosts: all

    # Optionally, specify different packages to install
    - dt4_packages: ['devtoolset-4-docker-client', 'devtoolset-4-binutils']

    roles:
      - { role: uclalib_role_devtoolset4 }
