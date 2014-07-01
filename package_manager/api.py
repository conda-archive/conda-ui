from __future__ import print_function, division, absolute_import

import os
from os.path import basename, dirname, isdir, join

from conda import config, resolve
from conda.api import get_index

class Env(object):

    def __init__(self, prefix=None):
        if prefix is None:
            self.prefix = config.root_dir
        else:
            self.prefix = prefix
    @property
    def name(self):
        if self.is_root:
            return config.root_env_name
        else:
            return basename(self.prefix)

    @property
    def is_default(self):
        return self.prefix == config.default_prefix

    @property
    def is_root(self):
        return self.prefix == config.root_dir

    def to_dict(self):
        return dict(name=self.name, is_default=self.is_default, is_root=self.is_root)

def get_envs():
    envs = []

    for envs_dir in config.envs_dirs:
        if not isdir(envs_dir):
            continue

        for dn in sorted(os.listdir(envs_dir)):
            if dn.startswith('.'):
                continue

            prefix = join(envs_dir, dn)

            if isdir(prefix):
                envs.append(Env(prefix))

    return envs

def get_resolve():
    return Resolve(get_index(use_cache=True))

class Resolve(resolve.Resolve):

    def get_packages(self, name, max_only=False):
        pkgs = self.get_pkgs(resolve.MatchSpec(name), max_only=max_only)
        return [ Package(pkg.fn, self.index[pkg.fn]) for pkg in pkgs ]

class Package(object):

    def __init__(self, fn, info):
        self.fn = fn
        self.info = info

    @property
    def dist(self):
        return self.fn[:-8] # XXX: self.fn.strip_suffix(".tar.bz2")
    @property
    def name(self):
        return self.info['name']
    @property
    def version(self):
        return self.info['version']
    @property
    def norm_version(self):
        return resolve.normalized_version(self.version)
    @property
    def build(self):
        return self.info['build']
    @property
    def build_number(self):
        return self.info['build_number']
    @property
    def features(self):
        return sorted(set(self.info.get('features', '').split()))
    @property
    def track_features(self):
        return sorted(set(self.info.get('track_features', '').split()))
    @property
    def channel(self):
        return self.info.get('channel')
    @property
    def canonical_channel(self):
        return config.canonical_channel_name(self.channel)
    @property
    def build_channel(self):
        return self.info.get('build_channel')
    @property
    def canonical_build_channel(self):
        return config.canonical_channel_name(self.build_channel)
    @property
    def depends(self):
        return self.info.get('depends', [])
    @property
    def conflicts(self):
        return self.info.get('conflicts')
    @property
    def size(self):
        return self.info.get('size')
    @property
    def md5(self):
        return self.info.get('md5')
    @property
    def icon(self):
        return self.info.get('icon')
    @property
    def license(self):
        return self.info.get('license')
    @property
    def summary(self):
        return self.info.get('summary')
    @property
    def pub_date(self):
        return self.info.get('pub_date')
    @property
    def type(self):
        return self.info.get('type')
    @property
    def app_entry(self):
        return self.info.get('app_entry')
    @property
    def with_features_depends(self):
        return self.info.get('with_features_depends')
    @property
    def build_target(self):
        return self.info.get('build_target')
    @property
    def app_cli_opts(self):
        return self.info.get('app_cli_opts')
    @property
    def app_type(self):
        return self.info.get('app_type')

    def __iter__(self):
        return iter([self.name, self.version, self.build])

    def to_dict(self):
        return dict(
            dist=self.dist,
            name=self.name,
            version=self.version,
            # norm_version=self.norm_version,
            build=self.build,
            build_number=self.build_number,
            features=self.features,
            track_features=self.track_features,
            channel=self.channel,
            canonical_channel=self.canonical_channel,
            build_channel=self.build_channel,
            canonical_build_channel=self.canonical_build_channel,
            depends=self.depends,
            conflicts=self.conflicts,
            size=self.size,
            md5=self.md5,
            icon=self.icon,
            license=self.icon,
            summary=self.summary,
            pub_date=self.pub_date,
            type=self.type,
            app_entry=self.app_entry,
            with_features_depends=self.with_features_depends,
            build_target=self.build_target,
            app_cli_opts=self.app_cli_opts,
            app_type=self.app_type,
        )

    # http://python3porting.com/problems.html#unorderable-types-cmp-and-cmp
#     def __cmp__(self, other):
#         if self.name != other.name:
#             raise ValueError('cannot compare packages with different '
#                              'names: %r %r' % (self.fn, other.fn))
#         try:
#             return cmp((self.norm_version, self.build_number),
#                       (other.norm_version, other.build_number))
#         except TypeError:
#             return cmp((self.version, self.build_number),
#                       (other.version, other.build_number))

    def __lt__(self, other):
        if self.name != other.name:
            raise TypeError('cannot compare packages with different '
                             'names: %r %r' % (self.fn, other.fn))
        try:
            return ((self.norm_version, self.build_number, other.build) <
                    (other.norm_version, other.build_number, self.build))
        except TypeError:
            return ((self.version, self.build_number) <
                    (other.version, other.build_number))

    def __eq__(self, other):
        if not isinstance(other, Package):
            return False
        if self.name != other.name:
            return False
        try:
            return ((self.norm_version, self.build_number, self.build) ==
                    (other.norm_version, other.build_number, other.build))
        except TypeError:
            return ((self.version, self.build_number, self.build) ==
                    (other.version, other.build_number, other.build))

    def __gt__(self, other):
        return not (self.__lt__(other) or self.__eq__(other))

    def __le__(self, other):
        return self < other or self == other

    def __ge__(self, other):
        return self > other or self == other

    def __repr__(self):
        return '<Package %s>' % self.fn
