.PHONY: lint migrate psql

lint:
	docker compose run --rm sqlfluff lint \
		migrations/deploy/ \
		migrations/revert/ \
		migrations/verify/ \
		bootstrap/
migrate:
	docker compose run --rm sqitch deploy gis
psql:
	docker compose exec -u postgres postgres psql postgres

