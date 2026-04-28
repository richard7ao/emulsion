use sqlx::{Pool, Sqlite};
use crate::models::{Conversation, Message};

pub async fn find_by_portfolio_id(pool: &Pool<Sqlite>, portfolio_id: i64) -> Result<Vec<Conversation>, sqlx::Error> {
    sqlx::query_as::<_, Conversation>("SELECT * FROM conversations WHERE portfolio_id = ? ORDER BY updated_at DESC")
        .bind(portfolio_id)
        .fetch_all(pool)
        .await
}

pub async fn find_messages_by_conversation_id(pool: &Pool<Sqlite>, conversation_id: i64) -> Result<Vec<Message>, sqlx::Error> {
    sqlx::query_as::<_, Message>("SELECT * FROM messages WHERE conversation_id = ? ORDER BY created_at ASC")
        .bind(conversation_id)
        .fetch_all(pool)
        .await
}

#[cfg(test)]
mod tests {
    use super::*;
    use sqlx::sqlite::SqlitePoolOptions;

    async fn test_pool() -> Pool<Sqlite> {
        let pool = SqlitePoolOptions::new().connect("sqlite::memory:").await.unwrap();
        sqlx::migrate!().run(&pool).await.unwrap();
        sqlx::query("INSERT INTO portfolios (id, name, bio, summary) VALUES (1, 'T', 'B', 'S')")
            .execute(&pool).await.unwrap();
        sqlx::query("INSERT INTO conversations (id, portfolio_id, participant_name, last_message) VALUES (1, 1, 'Alex', 'Lets chat')")
            .execute(&pool).await.unwrap();
        sqlx::query("INSERT INTO messages (conversation_id, sender, body) VALUES (1, 'Alex', 'Hi Richard')")
            .execute(&pool).await.unwrap();
        pool
    }

    #[tokio::test]
    async fn test_conversations_and_messages() {
        let pool = test_pool().await;
        let convos = find_by_portfolio_id(&pool, 1).await.unwrap();
        assert_eq!(convos.len(), 1);
        let msgs = find_messages_by_conversation_id(&pool, 1).await.unwrap();
        assert_eq!(msgs.len(), 1);
        assert_eq!(msgs[0].sender, "Alex");
    }
}
