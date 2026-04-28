use sqlx::{Pool, Sqlite};
use crate::models::Project;

pub async fn find_by_portfolio_id(pool: &Pool<Sqlite>, portfolio_id: i64) -> Result<Vec<Project>, sqlx::Error> {
    sqlx::query_as::<_, Project>("SELECT * FROM projects WHERE portfolio_id = ?")
        .bind(portfolio_id)
        .fetch_all(pool)
        .await
}

pub async fn find_by_id(pool: &Pool<Sqlite>, id: i64) -> Result<Option<Project>, sqlx::Error> {
    sqlx::query_as::<_, Project>("SELECT * FROM projects WHERE id = ?")
        .bind(id)
        .fetch_optional(pool)
        .await
}

pub async fn increment_view_count(pool: &Pool<Sqlite>, id: i64) -> Result<(), sqlx::Error> {
    sqlx::query("UPDATE projects SET view_count = view_count + 1 WHERE id = ?")
        .bind(id)
        .execute(pool)
        .await?;
    Ok(())
}

pub async fn increment_interested_count(pool: &Pool<Sqlite>, id: i64) -> Result<(), sqlx::Error> {
    sqlx::query("UPDATE projects SET interested_count = interested_count + 1 WHERE id = ?")
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
        sqlx::query("INSERT INTO portfolios (id, name, bio, summary) VALUES (1, 'T', 'B', 'S')")
            .execute(&pool).await.unwrap();
        pool
    }

    #[tokio::test]
    async fn test_increment_view_count() {
        let pool = test_pool().await;
        sqlx::query("INSERT INTO projects (id, portfolio_id, title, role, writeup, view_count, interested_count) VALUES (1, 1, 'P', 'R', 'W', 0, 0)")
            .execute(&pool).await.unwrap();

        increment_view_count(&pool, 1).await.unwrap();
        let project = find_by_id(&pool, 1).await.unwrap().unwrap();
        assert_eq!(project.view_count, 1);

        increment_view_count(&pool, 1).await.unwrap();
        let project = find_by_id(&pool, 1).await.unwrap().unwrap();
        assert_eq!(project.view_count, 2);
    }

    #[tokio::test]
    async fn test_increment_interested_count() {
        let pool = test_pool().await;
        sqlx::query("INSERT INTO projects (id, portfolio_id, title, role, writeup, view_count, interested_count) VALUES (1, 1, 'P', 'R', 'W', 0, 0)")
            .execute(&pool).await.unwrap();

        increment_interested_count(&pool, 1).await.unwrap();
        let project = find_by_id(&pool, 1).await.unwrap().unwrap();
        assert_eq!(project.interested_count, 1);
    }
}
