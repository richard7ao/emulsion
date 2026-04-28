use sqlx::{Pool, Sqlite};
use crate::models::{Note, CreateNote};

pub async fn create(pool: &Pool<Sqlite>, portfolio_id: i64, note: &CreateNote) -> Result<i64, sqlx::Error> {
    let result = sqlx::query(
        "INSERT INTO notes (portfolio_id, name, email, message) VALUES (?, ?, ?, ?)"
    )
        .bind(portfolio_id)
        .bind(&note.name)
        .bind(&note.email)
        .bind(&note.message)
        .execute(pool)
        .await?;
    Ok(result.last_insert_rowid())
}

pub async fn find_by_portfolio_id(pool: &Pool<Sqlite>, portfolio_id: i64) -> Result<Vec<Note>, sqlx::Error> {
    sqlx::query_as::<_, Note>("SELECT * FROM notes WHERE portfolio_id = ? ORDER BY created_at DESC")
        .bind(portfolio_id)
        .fetch_all(pool)
        .await
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::test_utils::test_pool;

    async fn seeded_pool() -> Pool<Sqlite> {
        let pool = test_pool().await;
        sqlx::query("INSERT INTO portfolios (id, name, bio, summary) VALUES (1, 'T', 'B', 'S')")
            .execute(&pool).await.unwrap();
        pool
    }

    #[tokio::test]
    async fn test_create_and_list() {
        let pool = seeded_pool().await;
        let note = CreateNote { name: "Alice".into(), email: "a@b.com".into(), message: "Hello".into() };
        create(&pool, 1, &note).await.unwrap();
        let notes = find_by_portfolio_id(&pool, 1).await.unwrap();
        assert_eq!(notes.len(), 1);
        assert_eq!(notes[0].name, "Alice");
    }
}
