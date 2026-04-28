use sqlx::{Pool, Sqlite};
use crate::models::{Conversation, Message};

const AMA_PARTICIPANT_NAME: &str = "Ask Me Anything";

pub async fn find_by_portfolio_id(pool: &Pool<Sqlite>, portfolio_id: i64) -> Result<Vec<Conversation>, sqlx::Error> {
    sqlx::query_as::<_, Conversation>("SELECT * FROM conversations WHERE portfolio_id = ? ORDER BY updated_at DESC")
        .bind(portfolio_id)
        .fetch_all(pool)
        .await
}

pub async fn create_from_note(pool: &Pool<Sqlite>, portfolio_id: i64, name: &str, message: &str) -> Result<i64, sqlx::Error> {
    let result = sqlx::query("INSERT INTO conversations (portfolio_id, participant_name, last_message) VALUES (?, ?, ?)")
        .bind(portfolio_id)
        .bind(name)
        .bind(message)
        .execute(pool)
        .await?;
    let convo_id = result.last_insert_rowid();
    sqlx::query("INSERT INTO messages (conversation_id, sender, body) VALUES (?, ?, ?)")
        .bind(convo_id)
        .bind(name)
        .bind(message)
        .execute(pool)
        .await?;
    Ok(convo_id)
}

pub async fn add_message(pool: &Pool<Sqlite>, conversation_id: i64, sender: &str, body: &str) -> Result<i64, sqlx::Error> {
    let result = sqlx::query("INSERT INTO messages (conversation_id, sender, body) VALUES (?, ?, ?)")
        .bind(conversation_id)
        .bind(sender)
        .bind(body)
        .execute(pool)
        .await?;
    sqlx::query("UPDATE conversations SET last_message = ?, updated_at = datetime('now') WHERE id = ?")
        .bind(body)
        .bind(conversation_id)
        .execute(pool)
        .await?;
    Ok(result.last_insert_rowid())
}

pub async fn find_or_create_ama(pool: &Pool<Sqlite>, portfolio_id: i64) -> Result<i64, sqlx::Error> {
    let row = sqlx::query_scalar::<_, i64>(
        "SELECT id FROM conversations WHERE portfolio_id = ? AND participant_name = ?"
    )
        .bind(portfolio_id)
        .bind(AMA_PARTICIPANT_NAME)
        .fetch_optional(pool)
        .await?;

    if let Some(id) = row {
        return Ok(id);
    }

    let result = sqlx::query(
        "INSERT INTO conversations (portfolio_id, participant_name, last_message) VALUES (?, ?, '')"
    )
        .bind(portfolio_id)
        .bind(AMA_PARTICIPANT_NAME)
        .execute(pool)
        .await?;

    Ok(result.last_insert_rowid())
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
