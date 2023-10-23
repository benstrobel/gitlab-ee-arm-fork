---
stage: Systems
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# What happens when `gitlab-ctl reconfigure` is run?

Omnibus GitLab uses [Cinc](https://cinc.sh/) under the hood,
which is a Free-as-in-Beer distribution of the open source software of [Chef Software Inc](https://docs.chef.io/). 

In very basic terms, a [Cinc client](https://cinc.sh/start/client/) run
happens when `gitlab-ctl reconfigure` is run. This document hopes to elaborate
the process and details the flow of control during a `gitlab-ctl reconfigure`
run.

`gitlab-ctl reconfigure` is defined in the
[`omnibus-ctl` project](https://gitlab.com/gitlab-org/build/omnibus-mirror/omnibus-ctl/-/blob/0.6.0.1/lib/omnibus-ctl.rb#L517)
and as mentioned above, it performs a
[`cinc-client` run](https://gitlab.com/gitlab-org/build/omnibus-mirror/omnibus-ctl/-/blob/0.6.0.1/lib/omnibus-ctl.rb#L501)
under the hood in [the local mode](https://docs.chef.io/ctl_chef_client/#run-in-local-mode) (using the `-z` flag). This invocation takes
two files as inputs - a configuration file named
[`solo.rb`](https://gitlab.com/gitlab-org/omnibus-gitlab/-/blob/master/files/gitlab-cookbooks/solo.rb) and an attribute file named
`dna.json`. `dna.json` is created during build time and differs between CE and
EE on which cookbook to load. For CE, it loads the
[`gitlab`](https://gitlab.com/gitlab-org/omnibus-gitlab/-/blob/master/files/gitlab-cookbooks/gitlab) cookbook while for EE, it loads
the [`gitlab-ee`](https://gitlab.com/gitlab-org/omnibus-gitlab/-/blob/master/files/gitlab-cookbooks/gitlab-ee) cookbook. Cinc then
follows its [two-pass model of execution](https://coderanger.net/two-pass/) for
the selected cookbook.

In the load phase, the main cookbook and its dependency cookbooks (mentioned in
the `metadata.rb` file) are loaded. The attributes mentioned in the default
attribute files of these cookbooks are loaded (thus populating the `node` object
with the default values specified in those attribute files) and the custom
reasources are all made available for use. Then the control moves to the
execution phase. In the `dna.json` file, we specify the cookbook name as the
`run_list`, which makes Cinc use the default recipe as the only entry in the run
list.

The `gitlab-ee` cookbook extends on top of the `gitlab` cookbook with EE only
features. For explanation purposes. let's first look at the
[`gitlab` cookbook's default recipe](https://gitlab.com/gitlab-org/omnibus-gitlab/-/blob/master/files/gitlab-cookbooks/gitlab/recipes/default.rb).

## The default recipe

The functionality in the default recipe can be summarized as below:

1. Call the `config` recipe to load the attributes from `gitlab.rb` and fully
   populate `node` obect.
1. Check for any deprecations and exit early
1. Check for any problematic settings in the run environment, like
   `LD_LIBRARY_PATH` being defined which can interfere with the included
   libraries and linking of software against them, and raise warnings.
1. Check for non-UTF-8 locales and raise warnings.
1. Create and configure necessary base directories like `/etc/gitlab` (unless
   explicitly disabled), `/var/opt/gitlab`, `/var/log/gitlab`.
1. Call other necessary helper recipes, enable/disable recipes for different
   services, etc.

Note that this summary is not complete. Check out the default recipe code to
learn more.

### The config recipe

It is the config recipe's responsibility to populate the `node` object with the
final values for various settings, after merging static default values,
computed default values, and the values user has specified via
`/etc/gitlab/gitlab.rb` file.

Notice that, in the above statement we have mentioned two types of default
values - static and computed. Static default values are specified in various
attribute files in different cookbooks, and are independently set. Computed
default values are used in scenarios where the default value for a setting
depends on either the static default value or user specified value of another
setting.

For example, the setting `gitlab_rails['gitlab_port']` which translates to the
`production.gitlab.port` key in the rendered `gitlab.yml` file which is used to
configure the GitLab Rails application's port has a static default value of
`80`. However, the setting used to inform the GitLab Rails application about the
GitLab Pages deployment's host and port (`gitlab_rails['pages_host']` and
`gitlab_rails['pages_port']`) depends on where the user has configured to run
GitLab Pages via `pages_external_url` setting. So, the computation of these
default values can happen only after the `gitlab.rb` file has been parsed.

#### What goes in to the `gitlab.rb` file?

Omnibus GitLab uses a module named `Gitlab` to store the settings specified in
`gitlab.rb`. This module, which extends `Mixlib::Config` module, can work as a
configuration hash. In the
[definition of this module](https://gitlab.com/gitlab-org/omnibus-gitlab/-/blob/master/files/gitlab-cookbooks/package/libraries/config/gitlab.rb),
we register the various roles, attribute blocks, and top-level attributes that
can be specified in `gitlab.rb`. The code for this registration is specified in
the `SettingsDSL` module, and is extended by `GitLab` module.

When `Gitlab.from_file` method is called in the config recipe, the settings from
`gitlab.rb` is parsed, and loaded to the `Gitlab` object, and are accessible via
`Gitlab['<setting_name>']`.

Once `gitlab.rb` has been parsed and the values are available in `Gitlab`
object, we can compute default values of settings dependent on other settings.

#### Computation of default values

Each component which require some sort of operations on its attributes, specify
a library file during its registration. One of the methods in this library file
is a `parse_variables`. This method is responsible for validating the user
provided input, setting default values to settings depending on other settings
(usually only if user hasn't already specified a value), and raising errors on
bad configuration.

As mentioned above, one of the responsibilities of `parse_variables` method is
to set default values to settings based on the default or user-provided values
of other settings. The default values to these other settings are already
available in the `node` object by this point (happened in the load phase of Cinc
run). However, this `node` object, while is available in the recipe, is not
available in the libraries. So, to make the static default values available in
the libraries, we attach the node object to the `Gitlab` object, which is
available in the libraries. This is done using the following statement in the
config recipe:

```ruby
Gitlab[:node] = node
```

With this, the static default values of attributes can be accessed in the libraries
using `Gitlab[:node]['<top-level-key>'][<setting>]`.

It is important to note that `Gitlab` object stores keys as they are mentioned
in `gitlab.rb` while `node` stores them based on the nesting
attribute-block-attribute hierarchy defined. So, `gitlab_rails` settings from
`gitlab.rb` is available as `Gitlab['gitlab_rails']` while default values of
those settings from attribute files are available at
`Gitlab[:node]['gitlab']['gitlab_rails']`. The `gitlab_rails` key is specified
under the `gitlab` attribute block, so an extra layer of nesting is present
while accessing it via `node`.

While `Gitlab` object is technically only supposed to hold the settings
specified in `gitlab.rb`, when computing default values of settings based on
other settings, we usually put them under `Gitlab` key itself.
[Issue #3932](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/3923) is open to change
this behavior.

#### Handling of secrets

Many of the attributes required for GitLab functionality are secrets that
needs to be persisted across reconfigure runs, and even across different nodes
of a multi-node setup for proper functioning. Moreover, Omnibus GitLab has to
create many of these secrets, if user hasn't specified them, for GitLab to
function correctly. For this purpose, similar to `parse_variables` method, each
of the library file specifies a `parse_secrets` method too. This method is
responsible for generating secrets (unless explicitly disabled) if none hasn't
been specified in `gitlab.rb` file.

These secrets are written (unless explicitly disabled) to a persisted file named
`/etc/gitlab/gitlab-secrets.json` file, and read from in subsequent reconfigure
runs so that same secret gets populated to the node in every reconfigure run.

#### Updating the node objct with final attribute list

Once all libraries are executed for all attributes, what we have is final
configuration that needs to be merged with the default attributes already
present in `node`. This is done by `node.consume_attributes` method, which
essentially merges the final configuration with the default configuration that
was populated in the load phase. Any configuration that was either read from
`gitlab.rb` or computed in libraries will overwrite the corresponding default
values in `node` object, thus causing the `node` object to end up with the final
attribute list.

#### `gitlab-cluster.json` file

`gitlab.rb` file is what a user uses to configure the system to match the
requirement. However, in certain scenarios, we need to imitate the user
modifying `gitlab.rb` file. Instead of writing back to `gitlab.rb` file,
Omnibus GitLab uses a different file located at
`/etc/gitlab/gitlab-cluster.json` that is used to override the user specified
values in `gitlab.rb`. This file is populated dynamically as part of a
`gitlab-ctl` command run or a reconfigure, and will be read and merged on top
of the node attributes at the end of the config recipe.

An example usecase for this is the `gitlab-ctl geo promote` command, which when
used on a multi-node PostgreSQL instance using Patroni, has to disable Patroni
standby server. Generally, this is done by
`patroni['standby_cluster']['enable']` field in `gitlab.rb`. However, because
it is being modified as part of execution of `gitlab-ctl` command and because
`gitlab.rb` file should ideally be read-only for the Cinc run, this setting
will be set to `false` in the `gitlab-cluster.json` file. Then, on reconfigure
run, this file will be parsed at the end, causing the setting
`node['patroni']['standby_cluster']['enable']` to `false`.

With the config recipe run, once the Cinc run moves on to the helper recipes and
service-specific recipes, the node object will be fully populated and can be
used in recipes/resources.

The default recipe in EE cookbook essentially calls `gitlab::default` recipe,
and then handles the EE-specific components separately.
