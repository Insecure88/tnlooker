FROM mysql:latest

RUN mkdir /opt/tnlooker

COPY $PWD/mysql_secrets.cfg /opt/tnlooker/

COPY $PWD/build_db.sql /docker-entrypoint-initdb.d/

ENTRYPOINT ["/entrypoint.sh"]

CMD ["mysqld"]