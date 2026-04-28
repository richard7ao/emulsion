use axum::extract::{Path, State};
use axum::http::StatusCode;
use axum::Json;
use serde_json::{json, Value};
use crate::app_state::AppState;
use crate::repositories::{portfolio_repo, experience_repo, skills_repo};

pub async fn get_portfolio(
    State(state): State<AppState>,
    Path(id): Path<i64>,
) -> Result<Json<Value>, StatusCode> {
    let cache_key = format!("portfolio:{}", id);
    if let Some(cached) = state.cache.get(&cache_key) {
        let val: Value = serde_json::from_str(&cached).unwrap_or(Value::Null);
        return Ok(Json(val));
    }

    let (portfolio, experiences, skills) = tokio::join!(
        portfolio_repo::find_by_id(&state.pool, id),
        experience_repo::find_by_portfolio_id(&state.pool, id),
        skills_repo::find_by_portfolio_id(&state.pool, id),
    );

    let portfolio = portfolio
        .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?
        .ok_or(StatusCode::NOT_FOUND)?;

    let experiences = experiences.map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;
    let skills = skills.map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;

    let response = json!({
        "portfolio": portfolio,
        "experiences": experiences,
        "skills": skills,
    });

    state.cache.set(cache_key, response.to_string());

    Ok(Json(response))
}
