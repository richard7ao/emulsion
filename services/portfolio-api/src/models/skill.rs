use serde::Serialize;
use sqlx::FromRow;

#[derive(Debug, FromRow, Serialize)]
pub struct Skill {
    pub id: i64,
    pub portfolio_id: i64,
    pub category: String,
    pub items: String,
}

impl From<Skill> for emulsion_types::Skill {
    fn from(s: Skill) -> Self {
        Self {
            id: s.id,
            portfolio_id: s.portfolio_id,
            category: s.category,
            items: s.items,
        }
    }
}
