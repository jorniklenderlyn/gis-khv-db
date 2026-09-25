DO $$
BEGIN
    IF EXISTS (
        SELECT FROM pg_database
        WHERE datname = :'shard_name'
    ) THEN
        RAISE NOTICE 'Database "%" already exists', :'shard_name';
    END IF;
END
$$;