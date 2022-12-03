FROM --platform=linux/amd64 cowrie/cowrie:latest as cowrie

COPY cowrie.cfg /cowrie/cowrie-git/etc/cowrie.cfg
COPY userdb.txt /cowrie/cowrie-git/etc/userdb.txt

FROM --platform=linux/amd64 debian:latest

ENV COWRIE_GROUP=cowrie \
    COWRIE_USER=cowrie \
    COWRIE_HOME=/cowrie

COPY --from=cowrie --chown=0:0 /etc/passwd /etc/passwd
COPY --from=cowrie --chown=0:0 /etc/group /etc/group
COPY --from=cowrie --chown=${COWRIE_USER}:${COWRIE_GROUP} ${COWRIE_HOME} ${COWRIE_HOME}

RUN apt-get update
RUN apt-get install -y authbind

RUN touch /etc/authbind/byport/22
RUN chown ${COWRIE_USER}:${COWRIE_GROUP} /etc/authbind/byport/22
RUN chmod 770 /etc/authbind/byport/22

# Reference : https://www.m3tech.blog/entry/k8s-honeypot
RUN apt-get install -y supervisor
COPY supervisord.conf /etc/supervisord_cowrie.conf

RUN touch /supervisord.log
RUN touch /supervisord.pid
RUN chown ${COWRIE_USER}:${COWRIE_GROUP} /supervisord.log
RUN chown ${COWRIE_USER}:${COWRIE_GROUP} /supervisord.pid

USER ${COWRIE_USER}

VOLUME ["/cowrie/cowrie-git/var", "/cowrie/cowrie-git/etc/"]
ENTRYPOINT ["/usr/bin/supervisord"]
CMD ["-c", "/etc/supervisord_cowrie.conf", "-e", "critical"]

EXPOSE 22 23 2222 2223
