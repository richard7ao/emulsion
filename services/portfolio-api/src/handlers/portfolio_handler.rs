use axum::extract::{Path, State};
use axum::http::StatusCode;
use axum::Json;
use serde_json::{json, Value};
use crate::app_state::AppState;
use crate::cache::keys;
use crate::repositories::{portfolio_repo, experience_repo, skills_repo};

pub async fn post_view(
    State(state): State<AppState>,
    Path(id): Path<i64>,
) -> Result<Json<Value>, StatusCode> {
    portfolio_repo::increment_view_count(&state.pool, id)
        .await
        .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;
    state.cache.invalidate(&keys::portfolio(id));
    Ok(Json(json!({"status": "ok"})))
}

pub async fn post_interested(
    State(state): State<AppState>,
    Path(id): Path<i64>,
) -> Result<Json<Value>, StatusCode> {
    portfolio_repo::increment_interested_count(&state.pool, id)
        .await
        .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;
    state.cache.invalidate(&keys::portfolio(id));
    Ok(Json(json!({"status": "ok"})))
}

pub async fn get_portfolio(
    State(state): State<AppState>,
    Path(id): Path<i64>,
) -> Result<Json<emulsion_types::PortfolioResponse>, StatusCode> {
    let cache_key = keys::portfolio(id);
    if let Some(cached) = state.cache.get(&cache_key) {
        if let Ok(val) = serde_json::from_str::<emulsion_types::PortfolioResponse>(&cached) {
            return Ok(Json(val));
        }
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

    let response = emulsion_types::PortfolioResponse {
        portfolio: portfolio.into(),
        experiences: experiences.into_iter().map(Into::into).collect(),
        skills: skills.into_iter().map(Into::into).collect(),
    };

    if let Ok(serialized) = serde_json::to_string(&response) {
        state.cache.set(cache_key, serialized);
    }

    Ok(Json(response))
}
