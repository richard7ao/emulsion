use sqlx::{Pool, Sqlite};
use crate::models::Portfolio;

pub async fn find_by_id(pool: &Pool<Sqlite>, id: i64) -> Result<Option<Portfolio>, sqlx::Error> {
    sqlx::query_as::<_, Portfolio>("SELECT * FROM portfolios WHERE id = ?")
        .bind(id)
        .fetch_optional(pool)
        .await
}

#[cfg(test)]
mod tests {
    use super::*;
    use sqlx::sqlite::SqlitePoolOptions;

    async fn test_pool() -> Pool<Sqlite> {
        let pool = SqlitePoolOptions::new()
            .connect("sqlite::memory:")
            .await
            .unwrap();
        sqlx::migrate!().run(&pool).await.unwrap();
        pool
    }

    #[tokio::test]
    async fn test_find_by_id_not_found() {
        let pool = test_pool().await;
        let result = find_by_id(&pool, 999).await.unwrap();
        assert!(result.is_none());
    }

    #[tokio::test]
    async fn test_find_by_id_found() {
        let pool = test_pool().await;
        sqlx::query("INSERT INTO portfolios (id, name, bio, summary) VALUES (1, 'Test', 'Bio', 'Summary')")
            .execute(&pool).await.unwrap();
        let result = find_by_id(&pool, 1).await.unwrap();
        assert!(result.is_some());
        assert_eq!(result.unwrap().name, "Test");
    }
}
