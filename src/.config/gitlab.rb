# Letsencrypt
letsencrypt['enable'] = false
logging['log_group'] = 'git'

gitlab_rails['gitlab_shell_ssh_port'] = 2222
gitlab_rails['trusted_proxies'] = ['10.0.0.0/8', '172.16.0.0/12', '192.168.0.0/16']

# Nginx
gitlab_rails['nginx']['listen_https'] = false
gitlab_rails['nginx']['listen_port'] = 80
gitlab_rails['nginx']['redirect_http_to_https'] = false
gitlab_rails['nginx']['real_ip_trusted_addresses'] = ['10.0.0.0/8', '172.16.0.0/12', '192.168.0.0/16']
gitlab_rails['nginx']['real_ip_header'] = 'X-Forwarded-For'
gitlab_rails['nginx']['real_ip_recursive'] = 'on'

# SMTP
gitlab_rails['smtp_authentication'] = 'login'
gitlab_rails['smtp_enable_starttls_auto'] = true
gitlab_rails['smtp_tls'] = false
gitlab_rails['smtp_enable'] = true
gitlab_rails['smtp_address'] = 'smtp.mail.me.com' # for iCloud
gitlab_rails['smtp_port'] = 587 # for iCloud
gitlab_rails['gitlab_email_display_name'] = 'GitLab'

# GitLab Pages
gitlab_pages['enable'] = true
gitlab_pages['listen_proxy'] = 'localhost:8090'
gitlab_pages['internal_gitlab_server'] = 'http://127.0.0.1'
gitlab_pages['redirect_http'] = false
gitlab_pages['nginx']['listen_https'] = false
gitlab_pages['nginx']['listen_port'] = 8091
gitlab_pages['nginx']['redirect_http_to_https'] = false

# Registry
registry['nginx']['listen_https'] = false
registry['nginx']['listen_port'] = 5050

# Auth
gitlab_rails['gitlab_signup_enabled'] = false
gitlab_rails['omniauth_enabled'] = true
gitlab_rails['omniauth_allow_single_sign_on'] = ['github']
gitlab_rails['omniauth_block_auto_created_users'] = false
gitlab_rails['omniauth_auto_link_user'] = ['github']

# Dotenv
external_url 'https://gitlab.${PRIVATE_DOMAIN}'
pages_external_url 'https://pages.${PRIVATE_DOMAIN}'
registry_external_url 'https://registry.${PRIVATE_DOMAIN}'
gitlab_rails['time_zone'] = '${TIME_ZONE?:TIME_ZONE is missing in Bitwarden}'
gitlab_rails['initial_root_password'] = '${GITLAB_INITIAL_ROOT_PASSWORD}'
gitlab_rails['omniauth_providers'] = [
	{
  'name' => 'github',
  'app_id' => '${GITHUB_CLIENT_ID}',
  'app_secret' => '${GITHUB_CLIENT_SECRET}',
  'args' => { 'scope' => 'user:email' }
	}
]
gitlab_rails['smtp_user_name'] = '${EMAIL?:Error - EMAIL is missing in Bitwarden}'
gitlab_rails['smtp_password'] = '${EMAIL_PASSWORD?:Error - EMAIL_PASSWORD is missing in Bitwarden}'
gitlab_rails['smtp_domain'] = '${PRIVATE_DOMAIN}'
gitlab_rails['gitlab_email_from'] = '${EMAIL}'
gitlab_rails['gitlab_email_reply_to'] = '${EMAIL}'
#gitlab_pages['internal_gitlab_server'] = 'http://127.0.0.1'
