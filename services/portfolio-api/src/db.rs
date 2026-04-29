use sqlx::sqlite::{SqliteConnectOptions, SqlitePoolOptions, SqliteSynchronous};
use sqlx::{Pool, Sqlite};
use std::str::FromStr;
use std::time::Duration;

pub async fn init_pool() -> Pool<Sqlite> {
    let database_url = std::env::var("DATABASE_URL")
        .unwrap_or_else(|_| "sqlite:./dev.db".to_string());
    init_pool_with_url(&database_url).await
}

pub async fn init_pool_with_url(database_url: &str) -> Pool<Sqlite> {
    let opts = SqliteConnectOptions::from_str(database_url)
        .expect("invalid DATABASE_URL")
        .create_if_missing(true)
        .journal_mode(sqlx::sqlite::SqliteJournalMode::Wal)
        .synchronous(SqliteSynchronous::Normal)
        .busy_timeout(Duration::from_secs(5))
        .foreign_keys(true)
        .pragma("temp_store", "MEMORY")
        .pragma("cache_size", "-16000");

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

#[cfg(test)]
mod tests {
    use super::*;
    use sqlx::Row;

    #[tokio::test]
    async fn pragmas_are_applied() {
        let pool = init_pool_with_url("sqlite::memory:").await;
        let busy: i64 = sqlx::query("PRAGMA busy_timeout")
            .fetch_one(&pool).await.unwrap().get(0);
        assert_eq!(busy, 5000, "busy_timeout should be 5000ms");
        let fk: i64 = sqlx::query("PRAGMA foreign_keys")
            .fetch_one(&pool).await.unwrap().get(0);
        assert_eq!(fk, 1, "foreign_keys should be ON");
        let sync: i64 = sqlx::query("PRAGMA synchronous")
            .fetch_one(&pool).await.unwrap().get(0);
        assert_eq!(sync, 1, "synchronous should be NORMAL (1)");
    }
}
