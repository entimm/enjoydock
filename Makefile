include .env

list:
	@echo ""
	@echo "usage: make COMMAND"
	@echo ""
	@echo "Commands:"
	@echo "  list"
	@echo "  mysql-dump"
	@echo "  mysql-restore"
	@echo "  mysql-backup-data"
	@echo "  mysql-restore-data"
	@echo "  nginx-t"
	@echo "  nginx-reload"
	@echo "  fpm-restart"
	@echo "  cron-update"
	@echo "  home"
	@echo "  clean"
	@echo "  logs"

mysql-dump:
	@mkdir -p data/dumps
	@docker exec $(docker-compose ps -q mysql) mysqldump --all-databases -u"root" -p"$(MYSQL_ROOT_PASSWORD)" > data/dumps/db.sql 2 > /dev/null

mysql-restore:
	@docker exec -i $(docker-compose ps -q mysql) mysql -u"root" -p"root" < data/dumps/db.sql 2 > /dev/null

mysql-backup-data:
	@docker run --rm --volumes-from enjoydock_mysql_1 -v $(pwd):/backup busybox tar cvf /backup/backup.tar /var/lib/mysql

mysql-restore-data:
	@docker run --rm --volumes-from enjoydock_mysql_1 -v $(pwd):/backup busybox sh -c "cd /var/lib/mysql && tar xvf /backup/backup.tar --strip 1"

nginx-t:
	@docker-compose exec nginx nginx -t

nginx-reload:
	@docker-compose exec nginx nginx -s reload

fpm-restart:
	@docker-compose exec php-fpm kill -USR2 1

cron-update:
	@docker ./workspace/crontab/* $(docker-compose ps -q workspace):/etc/cron.d
	@docker-compose exec workspace chmod -R 644 /etc/cron.d

home:
	@rm -Rf ./home
	@docker cp $(docker-compose ps -q workspace):/home/laradock ./home

clean:
	@rm -Rf ./data/mysql/*

logs:
	@docker-compose logs -f

.PHONY: home logs nginx
