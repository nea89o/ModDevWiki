export SSH_USER="site-deploy"
export SSH_HOST="nea.moe"
export GITHUB_SHA="$(git rev-parse HEAD)-$(openssl rand -hex 10)"

venv/bin/mkdocs build
scp -r site "$SSH_USER"@"$SSH_HOST":~/new-site-content-$GITHUB_SHA
ssh "$SSH_USER"@"$SSH_HOST" <<EOF
set -x
chmod -R g+rw ~/new-site-content-$GITHUB_SHA
rm -fr /var/www/moddev
mkdir /var/www/moddev
mv ~/new-site-content-$GITHUB_SHA/* /var/www/moddev
chmod -R g+rw /var/www/moddev
rm -rf ~/new-site-content-$GITHUB_SHA/
EOF

