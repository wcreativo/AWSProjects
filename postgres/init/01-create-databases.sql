-- Create databases for each project
CREATE DATABASE helloproject_db;

-- Create users for each project (better security)
CREATE USER helloproject_user WITH PASSWORD 'helloproject_password';

-- Connect to helloproject_db and grant specific privileges
\c helloproject_db;
GRANT ALL PRIVILEGES ON SCHEMA public TO helloproject_user;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO helloproject_user;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO helloproject_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO helloproject_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO helloproject_user;

-- Back to postgres database
\c postgres;