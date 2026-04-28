# Seed Tool

Populates SQLite with Richard's CV content. Idempotent — safe to run multiple times.

## Run

```bash
# Ensure migrations have run first
cd services/portfolio-api && DATABASE_URL=sqlite:./dev.db sqlx migrate run

# Seed
DATABASE_URL=sqlite:./services/portfolio-api/dev.db cargo run -p seed
```
