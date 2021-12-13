FROM mysql:latest

ENV MYSQL_DATABASE=tnlooker_db

COPY $PWD/build_db.sql /docker-entrypoint-initdb.d/

EXPOSE 3306 

ENTRYPOINT ["/entrypoint.sh"]

CMD ["mysqld"]