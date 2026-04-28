use sqlx::{Pool, Sqlite};
use crate::models::Experience;

pub async fn find_by_portfolio_id(pool: &Pool<Sqlite>, portfolio_id: i64) -> Result<Vec<Experience>, sqlx::Error> {
    sqlx::query_as::<_, Experience>("SELECT * FROM experiences WHERE portfolio_id = ?")
        .bind(portfolio_id)
        .fetch_all(pool)
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
    async fn test_find_by_portfolio_id_empty() {
        let pool = test_pool().await;
        let result = find_by_portfolio_id(&pool, 1).await.unwrap();
        assert!(result.is_empty());
    }

    #[tokio::test]
    async fn test_find_by_portfolio_id_returns_entries() {
        let pool = test_pool().await;
        sqlx::query("INSERT INTO portfolios (id, name, bio, summary) VALUES (1, 'T', 'B', 'S')")
            .execute(&pool).await.unwrap();
        sqlx::query("INSERT INTO experiences (portfolio_id, company, role, dates, bullets) VALUES (1, 'Serac', 'Engineer', '2025-now', '[]')")
            .execute(&pool).await.unwrap();
        let result = find_by_portfolio_id(&pool, 1).await.unwrap();
        assert_eq!(result.len(), 1);
        assert_eq!(result[0].company, "Serac");
    }
}
