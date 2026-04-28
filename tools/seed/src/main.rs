use anyhow::Result;
use serde::Deserialize;
use sqlx::sqlite::SqlitePoolOptions;
use sqlx::{Pool, Sqlite};
use std::str::FromStr;

#[derive(Deserialize)]
struct CvData {
    portfolio: PortfolioData,
    experiences: Vec<ExperienceData>,
    projects: Vec<ProjectData>,
    skills: Vec<SkillData>,
    qa_pairs: Vec<QaPairData>,
    conversations: Vec<ConversationData>,
}

#[derive(Deserialize)]
struct PortfolioData {
    id: i64,
    name: String,
    bio: String,
    summary: String,
    photo_path: String,
}

#[derive(Deserialize)]
struct ExperienceData {
    company: String,
    role: String,
    dates: String,
    bullets: Vec<String>,
}

#[derive(Deserialize)]
struct ProjectData {
    title: String,
    role: String,
    writeup: String,
    #[serde(default)]
    screenshots: Vec<String>,
}

#[derive(Deserialize)]
struct SkillData {
    category: String,
    items: Vec<String>,
}

#[derive(Deserialize)]
struct QaPairData {
    prompt: String,
    answer: String,
}

#[derive(Deserialize)]
struct ConversationData {
    participant_name: String,
    messages: Vec<MessageData>,
}

#[derive(Deserialize)]
struct MessageData {
    sender: String,
    body: String,
}

async fn seed(pool: &Pool<Sqlite>, data: &CvData) -> Result<()> {
    sqlx::query("DELETE FROM messages").execute(pool).await?;
    sqlx::query("DELETE FROM conversations").execute(pool).await?;
    sqlx::query("DELETE FROM qa_pairs").execute(pool).await?;
    sqlx::query("DELETE FROM notes").execute(pool).await?;
    sqlx::query("DELETE FROM skills").execute(pool).await?;
    sqlx::query("DELETE FROM projects").execute(pool).await?;
    sqlx::query("DELETE FROM experiences").execute(pool).await?;
    sqlx::query("DELETE FROM portfolios").execute(pool).await?;

    sqlx::query("INSERT INTO portfolios (id, name, bio, summary, photo_path) VALUES (?, ?, ?, ?, ?)")
        .bind(data.portfolio.id)
        .bind(&data.portfolio.name)
        .bind(&data.portfolio.bio)
        .bind(&data.portfolio.summary)
        .bind(&data.portfolio.photo_path)
        .execute(pool).await?;

    for exp in &data.experiences {
        let bullets_json = serde_json::to_string(&exp.bullets)?;
        sqlx::query("INSERT INTO experiences (portfolio_id, company, role, dates, bullets) VALUES (?, ?, ?, ?, ?)")
            .bind(data.portfolio.id)
            .bind(&exp.company)
            .bind(&exp.role)
            .bind(&exp.dates)
            .bind(&bullets_json)
            .execute(pool).await?;
    }

    for proj in &data.projects {
        let screenshots_json = serde_json::to_string(&proj.screenshots)?;
        sqlx::query("INSERT INTO projects (portfolio_id, title, role, writeup, screenshots) VALUES (?, ?, ?, ?, ?)")
            .bind(data.portfolio.id)
            .bind(&proj.title)
            .bind(&proj.role)
            .bind(&proj.writeup)
            .bind(&screenshots_json)
            .execute(pool).await?;
    }

    for skill in &data.skills {
        let items_json = serde_json::to_string(&skill.items)?;
        sqlx::query("INSERT INTO skills (portfolio_id, category, items) VALUES (?, ?, ?)")
            .bind(data.portfolio.id)
            .bind(&skill.category)
            .bind(&items_json)
            .execute(pool).await?;
    }

    for qa in &data.qa_pairs {
        sqlx::query("INSERT INTO qa_pairs (portfolio_id, prompt, answer, is_canned) VALUES (?, ?, ?, 1)")
            .bind(data.portfolio.id)
            .bind(&qa.prompt)
            .bind(&qa.answer)
            .execute(pool).await?;
    }

    for convo in &data.conversations {
        let last_msg = convo.messages.last().map(|m| m.body.as_str()).unwrap_or("");
        let result = sqlx::query("INSERT INTO conversations (portfolio_id, participant_name, last_message) VALUES (?, ?, ?)")
            .bind(data.portfolio.id)
            .bind(&convo.participant_name)
            .bind(last_msg)
            .execute(pool).await?;
        let convo_id = result.last_insert_rowid();

        for msg in &convo.messages {
            sqlx::query("INSERT INTO messages (conversation_id, sender, body) VALUES (?, ?, ?)")
                .bind(convo_id)
                .bind(&msg.sender)
                .bind(&msg.body)
                .execute(pool).await?;
        }
    }

    println!("seeded successfully");
    Ok(())
}

#[tokio::main]
async fn main() -> Result<()> {
    let database_url = std::env::var("DATABASE_URL")
        .unwrap_or_else(|_| "sqlite:./dev.db".to_string());

    let opts = sqlx::sqlite::SqliteConnectOptions::from_str(&database_url)?
        .create_if_missing(true);
    let pool = SqlitePoolOptions::new()
        .connect_with(opts)
        .await?;
    sqlx::migrate!("../../services/portfolio-api/migrations")
        .run(&pool)
        .await?;

    let cv_json = include_str!("../data/cv.json");
    let data: CvData = serde_json::from_str(cv_json)?;
    seed(&pool, &data).await?;

    Ok(())
}
