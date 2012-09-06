import os

from fabric.api import task, local, run, abort, sudo, env
from fabric.operations import prompt
from fabric.decorators import hosts
from fabric.context_managers import prefix, cd, settings, hide
from fabric.colors import green
from fabric.contrib.files import exists

# For a new project:
# 1. Edit project_name below.
# 2. fab create_releases_repo

# Edit this! Must be unique.
project_name = 'site-start'
deploy_host = repo_host = 'vilcon.se'

install_dir = '/opt/%s' % project_name
releases_repo_path = '/home/martin/releases/%s.git' % project_name
releases_repo_remote = '%s:%s' % (repo_host, releases_repo_path)

def check_working_dir_clean():
    """Aborts if not everything has been committed."""
    # Inspiration:
    # http://stackoverflow.com/questions/5139290/how-to-check-if-theres-nothing-to-be-committed-in-the-current-branch
    with settings(warn_only=True):
        if not local('git diff --stat --exit-code').succeeded:
            abort('You have unstaged changes')
        if not local('git diff --cached --stat --exit-code').succeeded:
            abort('Your index contains uncommitted changes')

        r = local(
            'git ls-files --other --exclude-standard --directory',
            capture=True
        )
        if r != '':
            abort('Untracked files exist')

def get_hash():
    """Get the Git hash for the current version."""
    return local('git rev-parse --short HEAD', capture=True)

@task
def clean_build():
    local('rm -rf site tmp')
    local('NANOC_ENV=production nanoc')

@task
def release(version=None):
    """Creates and releases the current code.
    Takes an optional version string as parameter.

    """
    check_working_dir_clean()
    clean_build()
    release_only(version)

@task
def release_only(version=None):
    """Upload the current version to the server without building first.
    Takes an optional version string as parameter.
    By default generates a new version number by incrementing.

    """

    if not os.path.exists('releases.git'):
        clone_releases_repo()

    def git(command, **kwargs):
        return local(
            'git --work-tree=. --git-dir=releases.git ' + command,
            **kwargs
        )

    git('fetch')
    # fast-forward
    git('reset --mixed origin/master --')
    # Get latest release version number
    git('checkout version.txt')

    commit = get_hash()
    if not version:
        version = get_next_version_number()

    tag = 'v' + version
    if git('tag -l ' + tag, capture=True):
        abort('Tag %s already exists in releases repo' % tag)
    if local('git tag -l ' + tag, capture=True):
        abort('Tag %s already exists in local repo' % tag)

    set_version_number(version)
    git('add -fA site/ version.txt')
    message = 'Version %s, commit %s' % (version, commit)
    git('diff --staged --stat')
    print(green('This will be committed as ' + message))
    if prompt('Go on?', default='y', validate='[yn]') == 'n':
        abort('Aborted')

    git('commit -m "%s"' % message)
    git('tag ' + tag)
    git('push --tags origin master')
    local('git tag ' + tag)

def get_next_version_number():
    """Increase and return the version number.
    Makes sure the version is at least three numbers,
    e.g. 2.3.0

    """
    with open('version.txt') as s:
        values = s.read().strip().split('.')
    values += ('0',) * (3 - len(values))
    values[-1] = str(int(values[-1]) + 1)
    return '.'.join(values)

def set_version_number(version):
    with open('version.txt', 'w') as s:
        s.write(version)

@task
def clone_releases_repo():
    """Clones the releases repo into releases.git."""
    local('git clone --bare %s releases.git' % releases_repo_remote)
    #local('git --git-dir=releases.git config core.bare false')
    local('git --git-dir=releases.git config remote.origin.fetch "+refs/heads/*:refs/remotes/origin/*"')

@task
@hosts(deploy_host)
def deploy(version=None):
    """Deploy latest version, or a specific version if given as argument.

    """
    gitdir = install_dir + '/.git'
    if exists(gitdir):
        with cd(install_dir):
            run('git fetch')
    else:
        print(green('%s does not exist, I guess this is the first release' %
            gitdir))
        run('git clone %s %s' % (releases_repo_path, install_dir))

    with cd(install_dir):
        if version:
            run('git reset --hard v' + version)
        else:
            run('git reset --hard origin/master')

@task
@hosts(repo_host)
def create_releases_repo():
    """Creates the releases repository on the repo server"""

    # This doesn't fail if the directory already exists,
    # but doesn't destroy anything.
    run('git --git-dir=%s init' % releases_repo_path)
    run(
        (
            'git --git-dir=%s --work-tree=. '
            'commit --allow-empty -m "Dummy initial commit"'
        ) % (
            releases_repo_path
        )
    )

@task
def restart_nginx():
    sudo('kill -HUP $(cat /var/run/nginx.pid)')
