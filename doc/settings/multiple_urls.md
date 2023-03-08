---
stage: Systems
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

TODO: Check if the frontmatter above is correct

# Configuring multiple domains for an instance

It's occasionally desirable to have multiple domains pointing to the same instance (such as for a domain migration).

While technically a Geo instance with secondary proxying enabled can achieve this, that is not a feasible approach for cases where an environment only contains one GitLab instance.

There are two possible methods for configuring multiple domains for an instance:

- Adding Subject Alternative Names to the generated Let's Encrypt certificate
- Adding a custom Nginx configuration to rewrite requests to the `external_url` configured in the `gitlab.rb` file.

It is possible to use _both_ approaches at once, however in this case Let's Encrypt _must_ be used to generate the certificate for `external_url`.

## Let's Encrypt approach

Let's Encrypt certificates support Subject Alternative Names (SANs), a means of including additional domains on a certificate generated for the primary domain (`external_url`).


### Constraints

This approach requires Let's Encrypt to be enabled - unless otherwise specified, Let's Encrypt is enabled on new GitLab installations. Please ensure that your `gitlab.rb` file does not contain the line `letsencrypt['enable'] = false` or has it commented out.

Additionally, please ensure that `nginx['ssl_certificate']` and `nginx['ssl_certificate_key']` are not set, as these values will overwrite the Let's Encrypt generated configuration.

Please note that while users may use your alternative domain in place of your `external_url`, your instance will still use the `external_url` as the primary domain reference (such as in generated `git clone ...` commands displayed on repositories).

Using `git` commands with the alternative domain will add a new entry to the `known_hosts` file.

### Configuration

Firstly please ensure that the alternative domain name (that is, the domain that is _not_ the current value of `external_url`) has a DNS record pointing at your instance.

Secondly, please add the following line with `example.com` replaced by your alternative domain:

```
letsencrypt["alt_names"] = ["example.com"]
```

Finally, run `gitlab-ctl reconfigure` to generate the new Let's Encrypt certificate.

## Nginx approach

It is possible to [add an additional server block](https://docs.gitlab.com/omnibus/settings/nginx.html#inserting-custom-settings-into-the-nginx-configuration) to the Nginx configuration that GitLab generates using the `nginx['custom_nginx_config']` line in your `gitlab.rb` file.

Inside this configuration you can add logic to rewrite requests from one domain to your `external_url`.



### Constraints

It's important to understand that this approach is less sophisticated that the Let's Encrypt approach. Using the Let's Encrypt approach above will result in users being able to navigate an instance using the alternative domain without being redirected to the `external_url`, whereas this approach will redirect users from the alternative domain to the `external_url` when they navigate to the alternative domain.

`git` commands using the alternative domain will succeed, although this has not been rigorously tested.

Using `git` commands with the alternative domain will add a new entry to the `known_hosts` file.

### Configuration

Firstly please ensure that the alternative domain name (that is, the domain that is _not_ the current value of `external_url`) has a DNS record pointing at your instance.

Next, create a new Nginx configuration file in `/etc/gitlab` (Storing configuration files here will [guarantee the files are included in backups]()).

Modify the following configuration and insert it into the empty Nginx configuration file you just created. Replace `example.com` with the domain you would like to redirect, and replace `gitlab.example.com` with your `external_url`.

```
server {
    listen 80;
    server_name example.com;
    access_log /var/log/gitlab/nginx/example.com.access.log;
    error_log /var/log/gitlab/nginx/example.com.error.log;
    
    # Let's Encrypt ACME challenge validation
    location ^~ /.well-known/acme-challenge/ {
        allow all;
         root /var/opt/gitlab/nginx/www/; 
    }
    
    # Redirect all HTTP requests to HTTPS
    return 301 https://gitlab.example.com$request_uri;
}

server {
    listen 443 ssl;
    server_name example.com;
    access_log /var/log/gitlab/nginx/example.com.access.log;
    error_log /var/log/gitlab/nginx/example.com.error.log;
    ssl_certificate /path/to/certificate.crt; 
    ssl_certificate_key /path/to/certificate.key; 
    
    location ^~ /.well-known/acme-challenge/ {
        allow all;
         root /var/opt/gitlab/nginx/www/; 
    }
    
    # Redirect all HTTPS requests to the new domain
    return 301 https://gitlab.example.com$request_uri;
}
```

Save your new custom configuration file and [add a reference to the file to your `gitlab.rb`](https://docs.gitlab.com/omnibus/settings/nginx.html#inserting-custom-settings-into-the-nginx-configuration).

Run `gitlab-ctl reconfigure` and your custom Nginx configuration should be loaded.

If a user navigates to the alternative name set in your custom Nginx configuration file, they will be redirected to your `external_url` (with the path of the original request preserved).
