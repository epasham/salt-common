#!pyobjects
# -*- mode: python -*-
# To require this state in your state:
# - require:
#     - file: gentoo.portage.packages
from salt.ext import six
import re

def process_target(package, version_num):
    if version_num is None:
        return package
    else:
        # PCRE modified a bit compared to one from ebuild.py since here we don't support list of USE package_vars in verstr 
        match = re.match('^(~|-|\*)?([<>]?=?)?([^<>=\[\]]*)$', version_num)
        if match:
            keyword, prefix, verstr = match.groups()
            # If no prefix characters were supplied and verstr contains a version, use '='
            if len(verstr) > 0 and verstr[0] != ':':
                prefix = prefix or '='
                return '{0}{1}-{2}'.format(prefix, package, verstr)
            else:
                return '{0}{1}'.format(package, verstr)
        else:
            raise AttributeError(
                'Unable to parse version {0} of {1}'.\
                format(repr(version_num), package))

include('gentoo.portage')

packages = pillar('gentoo:portage:packages', {})
profile = pillar('gentoo:portage:profile', {})
filenames = []

for var in ('accept_keywords', 'mask', 'unmask', 'use', 'env', 'license', 'properties'):
    d = '/etc/portage/package.{}/'.format(var)
    File.directory(d, create=True, mode='0755', user='root', group='portage')

    result = []
    for cp, package_vars in packages.items():
        if var not in package_vars:
            continue
        value = package_vars[var]
        if value is True:
            result.append((cp, ''))
        elif value is False:
            pass
        elif hasattr(value, '__iter__'):
            result.append((cp, ' '.join(value))
        else:
            result.append((cp, value))
    result_str = ''.join([ "{} {}\n".format(process_target(cp, packages.get(cp, {}).get('version')), value) for cp, value in sorted(result) ])
    filename = d + 'SALT'
    filenames.append({'file': filename})
    File.managed(filename, contents=result_str, mode='0640',
                 user='root', group='portage', require=[File(d)])

for var in ('accept_keywords', 'mask', 'unmask', 'use', 'use.mask', 'use.force', 'provided'):
    d = '/etc/portage/profile/package.{}/'.format(var)
    File.directory(d, create=True, mode='0755', user='root', group='portage',
                   require=[File('/etc/portage/profile/')])

    result = []
    for cp, profile_vars in profile.items():
        if var not in profile_vars:
            continue
        value = package_vars[var]
        if value is True:
            result.append((cp, ''))
        elif value is False:
            pass
        elif hasattr(value, '__iter__'):
            result.append((cp, ' '.join(value))
        else:
            result.append((cp, value))
    result_str = ''.join([ "{} {}\n".format(process_target(cp, profiles.get(cp, {}).get('version')), value) for cp, value in sorted(result) ])
    filename = '/etc/portage/profile/package.{}/SALT'.format(var)
    filenames.append({'file': filename})
    File.managed(filename, contents=result_str, mode='0640',
                 user='root', group='portage', makedirs=True,
                 require=[File(d)])

File.managed('gentoo.portage.packages', name='/etc/portage/.gentoo.portage.packages', mode='0640',
             user='root', group='portage', contents="Stub file for convenient usage of gentoo.portage.packages state\n", require=filenames)
