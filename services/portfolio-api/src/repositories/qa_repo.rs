use sqlx::{Pool, Sqlite};
use crate::models::QaPair;

pub async fn find_canned_by_portfolio_id(pool: &Pool<Sqlite>, portfolio_id: i64) -> Result<Vec<QaPair>, sqlx::Error> {
    sqlx::query_as::<_, QaPair>("SELECT * FROM qa_pairs WHERE portfolio_id = ? AND is_canned = 1")
        .bind(portfolio_id)
        .fetch_all(pool)
        .await
}

pub async fn fuzzy_match(pool: &Pool<Sqlite>, portfolio_id: i64, query: &str) -> Result<Option<QaPair>, sqlx::Error> {
    let keywords: Vec<&str> = query.split_whitespace()
        .filter(|w| w.len() >= 3)
        .collect();

    if keywords.is_empty() {
        return Ok(None);
    }

    let all = find_canned_by_portfolio_id(pool, portfolio_id).await?;
    let lower_keywords: Vec<String> = keywords.iter().map(|kw| kw.to_lowercase()).collect();

    let mut best: Option<(usize, &QaPair)> = None;
    for pair in &all {
        let prompt = pair.prompt.to_lowercase();
        let answer = pair.answer.to_lowercase();
        let hits = lower_keywords.iter()
            .filter(|kw| prompt.contains(kw.as_str()) || answer.contains(kw.as_str()))
            .count();
        if hits > 0 && best.map_or(true, |(prev, _)| hits > prev) {
            best = Some((hits, pair));
        }
    }

    Ok(best.map(|(_, pair)| pair.clone()))
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::test_utils::test_pool;

    async fn seeded_pool() -> Pool<Sqlite> {
        let pool = test_pool().await;
        sqlx::query("INSERT INTO portfolios (id, name, bio, summary) VALUES (1, 'T', 'B', 'S')")
            .execute(&pool).await.unwrap();
        sqlx::query("INSERT INTO qa_pairs (portfolio_id, prompt, answer, is_canned) VALUES (1, 'What are you working on?', 'Building at Serac', 1)")
            .execute(&pool).await.unwrap();
        pool
    }

    #[tokio::test]
    async fn test_fuzzy_match_found() {
        let pool = seeded_pool().await;
        let result = fuzzy_match(&pool, 1, "working").await.unwrap();
        assert!(result.is_some());
        assert_eq!(result.unwrap().prompt, "What are you working on?");
    }

    #[tokio::test]
    async fn test_fuzzy_match_not_found() {
        let pool = seeded_pool().await;
        let result = fuzzy_match(&pool, 1, "xyzzy_no_match").await.unwrap();
        assert!(result.is_none());
    }

    #[tokio::test]
    async fn test_fuzzy_match_searches_answer_too() {
        let pool = seeded_pool().await;
        let result = fuzzy_match(&pool, 1, "Serac").await.unwrap();
        assert!(result.is_some(), "should match keywords found in the answer text");
    }

    #[tokio::test]
    async fn test_fuzzy_match_short_words_ignored() {
        let pool = seeded_pool().await;
        let result = fuzzy_match(&pool, 1, "at on").await.unwrap();
        assert!(result.is_none(), "words under 3 chars should be filtered out");
    }
}
