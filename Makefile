.PHONY: lint up down \
		new-region drop-region migrate \
		add psql

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
	docker compose --progress quiet run --rm sqitch deploy --verify $(REGION)
drop-region:
	@test -n "$(REGION)" || (echo "REGION= required"; exit 1)
	@read -p "Drop database '$(REGION)'? [y/N] " ans; [ "$$ans" = "y" ]
	docker compose exec -u postgres postgres \
	  psql -d postgres -c "DROP DATABASE IF EXISTS $(REGION)"
	docker compose run --rm sqitch target remove $(REGION) || true
migrate:
	docker compose run --rm sqitch deploy --verify $(TARGET_DB)
# make add NAME=018_table_x NOTE="adds x" [REQUIRES="010_table_fields 011_table_ndvi-points"]
add:
	@test -n "$(NAME)" || (echo "NAME= required"; exit 1)
	@test -n "$(NOTE)" || (echo "NOTE= required"; exit 1)
	docker compose run --rm \
	  -e SQITCH_FULLNAME="$$(git config user.name)" \
	  -e SQITCH_EMAIL="$$(git config user.email)" \
	  sqitch add $(NAME) \
	  $(foreach r,$(REQUIRES),--requires $(r)) \
	  --use deploy=templates/deploy/pg.tmpl \
	  --use revert=templates/revert/pg.tmpl \
	  --use verify=templates/verify/pg.tmpl \
	  -n "$(NOTE)"
psql:
	docker compose exec -u postgres postgres psql postgres

