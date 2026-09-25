.PHONY: lint migrate psql

lint:
	docker compose run --rm sqlfluff lint \
		migrations/deploy/ \
		migrations/revert/ \
		migrations/verify/ \
		bootstrap/
bootstrap:
    docker compose exec -u postgres postgres \
	psql -U postgres \
	-d postgres
migrate:
	docker compose run --rm sqitch deploy gis
psql:
	docker compose exec -u postgres postgres psql postgres

