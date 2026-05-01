use sqlx::{Pool, Sqlite};
use crate::models::{Conversation, Message};

const AMA_PARTICIPANT_NAME: &str = "Ask Me Anything";

pub async fn find_by_id(pool: &Pool<Sqlite>, id: i64) -> Result<Option<Conversation>, sqlx::Error> {
    sqlx::query_as::<_, Conversation>("SELECT * FROM conversations WHERE id = ?")
        .bind(id)
        .fetch_optional(pool)
        .await
}

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
    sqlx::query("UPDATE conversations SET last_message = ?, updated_at = datetime('now'), is_theatre = 0 WHERE id = ?")
        .bind(body)
        .bind(conversation_id)
        .execute(pool)
        .await?;
    Ok(result.last_insert_rowid())
}

pub async fn find_or_create_ama(pool: &Pool<Sqlite>, portfolio_id: i64) -> Result<i64, sqlx::Error> {
    sqlx::query(
        "INSERT OR IGNORE INTO conversations (portfolio_id, participant_name, last_message, is_theatre) \
         VALUES (?, ?, '', 0)"
    )
        .bind(portfolio_id)
        .bind(AMA_PARTICIPANT_NAME)
        .execute(pool)
        .await?;

    let id = sqlx::query_scalar::<_, i64>(
        "SELECT id FROM conversations WHERE portfolio_id = ? AND participant_name = ?"
    )
        .bind(portfolio_id)
        .bind(AMA_PARTICIPANT_NAME)
        .fetch_one(pool)
        .await?;

    Ok(id)
}

pub async fn find_messages_by_conversation_id(pool: &Pool<Sqlite>, conversation_id: i64) -> Result<Vec<Message>, sqlx::Error> {
    sqlx::query_as::<_, Message>("SELECT * FROM messages WHERE conversation_id = ? ORDER BY created_at ASC")
        .bind(conversation_id)
        .fetch_all(pool)
        .await
}

pub async fn delete_by_id(pool: &Pool<Sqlite>, id: i64) -> Result<bool, sqlx::Error> {
    sqlx::query("DELETE FROM messages WHERE conversation_id = ?")
        .bind(id)
        .execute(pool)
        .await?;
    let result = sqlx::query("DELETE FROM conversations WHERE id = ?")
        .bind(id)
        .execute(pool)
        .await?;
    Ok(result.rows_affected() > 0)
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::test_utils::test_pool;

    async fn seeded_pool() -> Pool<Sqlite> {
        let pool = test_pool().await;
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
        let pool = seeded_pool().await;
        let convos = find_by_portfolio_id(&pool, 1).await.unwrap();
        assert_eq!(convos.len(), 1);
        let msgs = find_messages_by_conversation_id(&pool, 1).await.unwrap();
        assert_eq!(msgs.len(), 1);
        assert_eq!(msgs[0].sender, "Alex");
    }

    #[tokio::test]
    async fn test_theatre_flag_transitions_on_message() {
        let pool = seeded_pool().await;
        let convo = find_by_id(&pool, 1).await.unwrap().unwrap();
        assert!(convo.is_theatre, "seeded conversations should be theatre");

        add_message(&pool, 1, "Visitor", "Hello").await.unwrap();

        let convo = find_by_id(&pool, 1).await.unwrap().unwrap();
        assert!(!convo.is_theatre, "conversation should be non-theatre after a message is sent");
    }

    #[tokio::test]
    async fn test_ama_conversation_is_not_theatre() {
        let pool = seeded_pool().await;
        let ama_id = find_or_create_ama(&pool, 1).await.unwrap();
        let convo = find_by_id(&pool, ama_id).await.unwrap().unwrap();
        assert!(!convo.is_theatre, "AMA conversations should not be theatre");
    }

    #[tokio::test]
    async fn find_or_create_ama_is_idempotent() {
        let pool = seeded_pool().await;
        let id1 = find_or_create_ama(&pool, 1).await.unwrap();
        let id2 = find_or_create_ama(&pool, 1).await.unwrap();
        assert_eq!(id1, id2, "calling find_or_create_ama twice must return the same conversation");
    }

    #[tokio::test]
    async fn test_delete_removes_conversation_and_messages() {
        let pool = seeded_pool().await;
        let deleted = delete_by_id(&pool, 1).await.unwrap();
        assert!(deleted);
        assert!(find_by_id(&pool, 1).await.unwrap().is_none());
        assert!(find_messages_by_conversation_id(&pool, 1).await.unwrap().is_empty());
    }

    #[tokio::test]
    async fn test_delete_nonexistent_returns_false() {
        let pool = seeded_pool().await;
        let deleted = delete_by_id(&pool, 999).await.unwrap();
        assert!(!deleted);
    }
}
