.PHONY: lint up down \
		new-region drop-region migrate \
		psql

lint:
	docker compose run --rm sqlfluff lint \
		migrations/deploy/ \
		migrations/revert/ \
		migrations/verify/
up:
	docker compose up -d
down:
	docker compose down -v
new-region:
	@test -n "$(REGION)" || (echo "REGION= required"; exit 1)
	docker compose exec -u postgres postgres /bootstrap/new-region.sh $(REGION)
	docker compose run --rm sqitch target show $(REGION) >/dev/null 2>&1 \
	  || docker compose run --rm sqitch target add $(REGION) \
	     db:pg://gis_migrator@postgres:5432/$(REGION)
	docker compose --progress quiet run --rm sqitch deploy $(REGION)
drop-region:
	@test -n "$(REGION)" || (echo "REGION= required"; exit 1)
	@read -p "Drop database '$(REGION)'? [y/N] " ans; [ "$$ans" = "y" ]
	docker compose exec -u postgres postgres \
	  psql -d postgres -c "DROP DATABASE IF EXISTS $(REGION)"
	docker compose run --rm sqitch target remove $(REGION) || true
migrate:
	docker compose run --rm sqitch deploy $(TARGET_DB)
psql:
	docker compose exec -u postgres postgres psql postgres

