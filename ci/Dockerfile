FROM bats/bats AS bats
FROM stedolan/jq AS jq
FROM governmentpaas/cf-cli AS cfcli
FROM ruby as ruby
COPY --from=bats /usr/sbin/bats /usr/sbin/bats
COPY --from=bats /opt/bats/* /opt/bats/
COPY --from=jq /usr/local/bin/jq /usr/local/bin/jq
COPY --from=cfcli /usr/local/bin/cf /usr/local/bin/cf
