use serde::Serialize;
use sqlx::FromRow;

#[derive(Debug, FromRow, Serialize)]
pub struct Experience {
    pub id: i64,
    pub portfolio_id: i64,
    pub company: String,
    pub role: String,
    pub dates: String,
    pub bullets: String,
}

impl From<Experience> for emulsion_types::Experience {
    fn from(e: Experience) -> Self {
        Self {
            id: e.id,
            portfolio_id: e.portfolio_id,
            company: e.company,
            role: e.role,
            dates: e.dates,
            bullets: e.bullets,
        }
    }
}
