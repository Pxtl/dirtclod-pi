# syntax=docker/dockerfile:1
FROM docksal/ssh-agent

COPY bin /usr/local/bin

RUN chmod +x /usr/local/bin/dirtclod-entrypoint.sh

ENTRYPOINT ["dirtclod-entrypoint.sh"]

CMD ["ssh-proxy", "github.com", "22"]