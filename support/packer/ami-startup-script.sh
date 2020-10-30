#!/bin/bash

is_xml()
{
  fqdn=$1
  word="<?xml"
  if $(test "${fqdn#*$word}" != "$fqdn"); then
    return 0
  else
    return 1
  fi
}

get_ec2_address()
{
  public_hostname_address="http://169.254.169.254/latest/meta-data/public-hostname"
  public_ipv4_address="http://169.254.169.254/latest/meta-data/public-ipv4"

  # Try collecting public hostname. If that is not available, try public IPv4
  # address.
  fqdn=$(/opt/gitlab/embedded/bin/curl -s ${public_hostname_address})
  if [ -z "${fqdn}" ]; then
    fqdn=$(/opt/gitlab/embedded/bin/curl -s ${public_ipv4_address})
  fi

if ! is_xml{fqdn}; then
  echo "http://{fqdn}"
fi
}

EXTERNAL_URL=$(get_ec2_address)

if [ -z "${EXTERNAL_URL}" ]; then
  echo 'Unable to detect public hostname or IPv4 address of the instance. Please update `external_url` value in `/etc/gitlab/gitlab.rb` and run `sudo gitlab-ctl reconfigure`.' >&2
fi

# Replace external URL in gitlab.rb if user hasn't changed it by some other
# means.
EXISTING_EXTERNAL_URL=$(sudo awk '/^external_url/ { print $2 }' /etc/gitlab/gitlab.rb | xargs)
if [ "$EXISTING_EXTERNAL_URL" = "http://gitlab.example.com" ] && [ -n "${EXTERNAL_URL}" ]; then
  sudo sed -i 's!^external_url .*!external_url "'$EXTERNAL_URL'"!g' /etc/gitlab/gitlab.rb
fi

# Setting initial root password to instance ID if user hasn't changed it by
# some other means.
EXISTING_ROOT_PASSWORD=$(sudo grep "^gitlab_rails\['initial_root_password'\]" /etc/gitlab/gitlab.rb | cut -d '=' -f2- | xargs)
if [ -z "${EXISTING_ROOT_PASSWORD}" ] && [ -z "${GITLAB_ROOT_PASSWORD}" ]; then
  GITLAB_ROOT_PASSWORD=$(/opt/gitlab/embedded/bin/curl -s http://169.254.169.254/latest/meta-data/instance-id)
fi

sudo GITLAB_ROOT_PASSWORD=${GITLAB_ROOT_PASSWORD} gitlab-ctl reconfigure
