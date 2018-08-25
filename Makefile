include .env

MYSQL_CONTAINER = $(shell docker-compose ps -q mysql)
WORKSPACE_CONTAINER = $(shell docker-compose ps -q workspace)

DATE = $(shell date +%y%m%d-%H%M%S)

DUMPS_PATH = $(shell pwd)/data/dumps
BACKUPS_PATH = $(shell pwd)/data/backups

SOURCE ?= latest

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
	@echo "  supervisor"

mysql-dump:
	@mkdir -p $(DUMPS_PATH)
	@docker exec $(MYSQL_CONTAINER) mysqldump --all-databases -u"root" -p"$(MYSQL_ROOT_PASSWORD)" > $(DUMPS_PATH)/$(DATE).sql 2>/dev/null
	@ln -nfs $(DUMPS_PATH)/$(DATE).sql $(DUMPS_PATH)/latest.sql

mysql-restore:
	@docker exec -i $(MYSQL_CONTAINER) mysql -u"root" -p"root" < $(DUMPS_PATH)/$(SOURCE).sql 2>/dev/null

mysql-backup-data:
	@mkdir -p $(BACKUPS_PATH)
	@docker run --rm --volumes-from $(MYSQL_CONTAINER) -v $(BACKUPS_PATH):/backup busybox tar cvf /backup/$(DATE).tar /var/lib/mysql
	@ln -nfs $(BACKUPS_PATH)/$(DATE).tar $(BACKUPS_PATH)/latest.tar

mysql-restore-data:
	@docker run --rm --volumes-from $(MYSQL_CONTAINER) -v $(BACKUPS_PATH):/backup busybox sh -c "cd /var/lib/mysql && tar xvf /backups/$(SOURCE).tar --strip 1"

nginx-t:
	@docker-compose exec nginx nginx -t

nginx-reload:
	@docker-compose exec nginx nginx -s reload

fpm-restart:
	@docker-compose restart php-fpm

cron-update:
	@docker cp ./workspace/crontab/* $(WORKSPACE_CONTAINER):/etc/cron.d
	@docker-compose exec workspace chmod -R 644 /etc/cron.d

home:
	@rm -Rf ./home
	@docker cp $(WORKSPACE_CONTAINER):/home/laradock ./home

clean:
	@rm -Rf ./data/mysql/*

logs:
	@docker-compose logs -f

supervisor-reload:
	@docker-compose exec php-worker supervisorctl reload

supervisor-status:
	@docker-compose exec php-worker supervisorctl status

.PHONY: home logs nginx
