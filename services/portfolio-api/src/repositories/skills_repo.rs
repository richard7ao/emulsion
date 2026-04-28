use sqlx::{Pool, Sqlite};
use crate::models::Skill;

pub async fn find_by_portfolio_id(pool: &Pool<Sqlite>, portfolio_id: i64) -> Result<Vec<Skill>, sqlx::Error> {
    sqlx::query_as::<_, Skill>("SELECT * FROM skills WHERE portfolio_id = ?")
        .bind(portfolio_id)
        .fetch_all(pool)
        .await
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::test_utils::test_pool;

    #[tokio::test]
    async fn test_find_by_portfolio_id() {
        let pool = test_pool().await;
        sqlx::query("INSERT INTO portfolios (id, name, bio, summary) VALUES (1, 'T', 'B', 'S')")
            .execute(&pool).await.unwrap();
        sqlx::query("INSERT INTO skills (portfolio_id, category, items) VALUES (1, 'Languages', '[\"Rust\",\"Swift\"]')")
            .execute(&pool).await.unwrap();
        let result = find_by_portfolio_id(&pool, 1).await.unwrap();
        assert_eq!(result.len(), 1);
        assert_eq!(result[0].category, "Languages");
    }
}
