use sqlx::{Pool, Sqlite};
use crate::models::Portfolio;

pub async fn find_by_id(pool: &Pool<Sqlite>, id: i64) -> Result<Option<Portfolio>, sqlx::Error> {
    sqlx::query_as::<_, Portfolio>("SELECT * FROM portfolios WHERE id = ?")
        .bind(id)
        .fetch_optional(pool)
        .await
}

pub async fn increment_view_count(pool: &Pool<Sqlite>, id: i64) -> Result<(), sqlx::Error> {
    sqlx::query("UPDATE portfolios SET view_count = view_count + 1 WHERE id = ?")
        .bind(id)
        .execute(pool)
        .await?;
    Ok(())
}

pub async fn increment_interested_count(pool: &Pool<Sqlite>, id: i64) -> Result<(), sqlx::Error> {
    sqlx::query("UPDATE portfolios SET interested_count = interested_count + 1 WHERE id = ?")
        .bind(id)
        .execute(pool)
        .await?;
    Ok(())
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
    async fn test_increment_view_count() {
        let pool = test_pool().await;
        sqlx::query("INSERT INTO portfolios (id, name, bio, summary) VALUES (1, 'Test', 'Bio', 'Summary')")
            .execute(&pool).await.unwrap();
        increment_view_count(&pool, 1).await.unwrap();
        let p = find_by_id(&pool, 1).await.unwrap().unwrap();
        assert_eq!(p.view_count, 1);
    }

    #[tokio::test]
    async fn test_increment_interested_count() {
        let pool = test_pool().await;
        sqlx::query("INSERT INTO portfolios (id, name, bio, summary) VALUES (1, 'Test', 'Bio', 'Summary')")
            .execute(&pool).await.unwrap();
        increment_interested_count(&pool, 1).await.unwrap();
        let p = find_by_id(&pool, 1).await.unwrap().unwrap();
        assert_eq!(p.interested_count, 1);
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
