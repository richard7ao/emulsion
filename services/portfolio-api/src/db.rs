use sqlx::sqlite::{SqliteConnectOptions, SqlitePoolOptions};
use sqlx::{Pool, Sqlite};
use std::str::FromStr;

pub async fn init_pool() -> Pool<Sqlite> {
    let database_url = std::env::var("DATABASE_URL")
        .unwrap_or_else(|_| "sqlite:./dev.db".to_string());

    let opts = SqliteConnectOptions::from_str(&database_url)
        .expect("invalid DATABASE_URL")
        .create_if_missing(true)
        .journal_mode(sqlx::sqlite::SqliteJournalMode::Wal);

    let pool = SqlitePoolOptions::new()
        .max_connections(5)
        .connect_with(opts)
        .await
        .expect("failed to connect to database");

    sqlx::migrate!()
        .run(&pool)
        .await
        .expect("failed to run migrations");

    pool
}
