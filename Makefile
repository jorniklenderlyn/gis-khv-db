.PHONY: lint up down \
		bootstrap migrate \
		psql-root

lint:
	docker compose run --rm sqlfluff lint \
		migrations/deploy/ \
		migrations/revert/ \
		migrations/verify/ \
		bootstrap/
up:
	docker compose up -d
down:
	docker compose down -v
bootstrap:
	docker compose exec -u postgres postgres \
		/bootstrap/bootstrap.sh $(SHARD_NAME)
migrate:
	docker compose run --rm sqitch deploy gis
psql:
	docker compose exec -u postgres postgres psql postgres

