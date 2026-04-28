use sqlx::{Pool, Sqlite};
use crate::models::QaPair;

pub async fn find_canned_by_portfolio_id(pool: &Pool<Sqlite>, portfolio_id: i64) -> Result<Vec<QaPair>, sqlx::Error> {
    sqlx::query_as::<_, QaPair>("SELECT * FROM qa_pairs WHERE portfolio_id = ? AND is_canned = 1")
        .bind(portfolio_id)
        .fetch_all(pool)
        .await
}

pub async fn fuzzy_match(pool: &Pool<Sqlite>, portfolio_id: i64, query: &str) -> Result<Option<QaPair>, sqlx::Error> {
    let pattern = format!("%{}%", query);
    sqlx::query_as::<_, QaPair>(
        "SELECT * FROM qa_pairs WHERE portfolio_id = ? AND prompt LIKE ? LIMIT 1"
    )
        .bind(portfolio_id)
        .bind(&pattern)
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
        sqlx::query("INSERT INTO portfolios (id, name, bio, summary) VALUES (1, 'T', 'B', 'S')")
            .execute(&pool).await.unwrap();
        sqlx::query("INSERT INTO qa_pairs (portfolio_id, prompt, answer, is_canned) VALUES (1, 'What are you working on?', 'Building at Serac', 1)")
            .execute(&pool).await.unwrap();
        pool
    }

    #[tokio::test]
    async fn test_fuzzy_match_found() {
        let pool = test_pool().await;
        let result = fuzzy_match(&pool, 1, "working").await.unwrap();
        assert!(result.is_some());
        assert_eq!(result.unwrap().prompt, "What are you working on?");
    }

    #[tokio::test]
    async fn test_fuzzy_match_not_found() {
        let pool = test_pool().await;
        let result = fuzzy_match(&pool, 1, "xyzzy_no_match").await.unwrap();
        assert!(result.is_none());
    }
}
