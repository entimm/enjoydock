include .env

mysql-dump:
	@mkdir -p data/dumps
	@docker exec $(docker-compose ps -q mysql) mysqldump --all-databases -u"root" -p"$(MYSQL_ROOT_PASSWORD)" > data/dumps/db.sql 2 > /dev/null
	@make resetOwner

mysql-restore:
	@docker exec -i $(docker-compose ps -q mysql) mysql -u"root" -p"root" < data/dumps/db.sql 2 > /dev/null

nginx-t:
	@docker-compose exec nginx nginx -t

nginx-reload:
	@docker-compose exec nginx nginx -s reload

fpm-restart:
	@docker-compose exec php-fpm kill -USR2 1

home:
	@rm -Rf ./home
	@docker cp $(docker-compose ps -q workspace):/home/laradock ./home

clean:
	@rm -Rf ./data/mysql/*

logs:
	@docker-compose logs -f

.PHONY: home logs nginx
