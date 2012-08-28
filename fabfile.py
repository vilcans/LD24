import re
from fabric.api import task, local, run, abort, sudo
from fabric.operations import put
from fabric.context_managers import prefix, cd


install_dir = '/opt/LD24/'


def get_version():
    """Get the Git hash for the current version."""
    return local('git rev-parse --short HEAD', capture=True)

@task
def clean_build():
    local('rm -rf site tmp')
    #local('NANOC_ENV=production nanoc')
    local('nanoc')

@task
def release(version=None):
    """Creates and releases the current code.
    Takes an optional version string as parameter.
    By default uses the Git hash.

    """
    clean_build()
    release_only(version)

@task
def release_only(version=None):
    """Upload the current version to the server without building first.
    Takes an optional version string as parameter.
    By default uses the Git hash.

    """
    if not version:
        version = get_version()
    local('bin/release')

@task
def deploy():
    """Deploy latest version"""
    with cd(install_dir):
        run('git pull')

@task
def restart_nginx():
    sudo('kill -HUP $(cat /var/run/nginx.pid)')
