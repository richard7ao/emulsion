use sqlx::{Pool, Sqlite};
use sqlx::sqlite::SqlitePoolOptions;

pub async fn test_pool() -> Pool<Sqlite> {
    let pool = SqlitePoolOptions::new()
        .connect("sqlite::memory:")
        .await
        .unwrap();
    sqlx::migrate!().run(&pool).await.unwrap();
    pool
}
