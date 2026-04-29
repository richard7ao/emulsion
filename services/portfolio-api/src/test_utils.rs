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

pub async fn seeded_test_pool() -> Pool<Sqlite> {
    let pool = test_pool().await;
    sqlx::query(
        "INSERT INTO portfolios (id, name, bio, summary, photo_path) \
         VALUES (1, 'Richard', 'Bio', 'Summary', '/static/hero.png')"
    ).execute(&pool).await.unwrap();
    sqlx::query(
        "INSERT INTO experiences (portfolio_id, company, role, dates, bullets) \
         VALUES (1, 'Serac', 'Engineer', 'now', '[\"a\",\"b\"]')"
    ).execute(&pool).await.unwrap();
    sqlx::query(
        "INSERT INTO projects (portfolio_id, title, role, writeup, screenshots) \
         VALUES (1, 'P', 'R', 'W', '[]')"
    ).execute(&pool).await.unwrap();
    pool
}
