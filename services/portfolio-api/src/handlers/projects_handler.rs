use axum::extract::{Path, State};
use axum::Json;
use serde_json::{json, Value};
use crate::app_state::AppState;
use crate::cache::keys;
use crate::error::AppError;
use crate::repositories::projects_repo;

pub async fn list_projects(
    State(state): State<AppState>,
    Path(portfolio_id): Path<i64>,
) -> Result<Json<Value>, AppError> {
    let cache_key = keys::projects_list(portfolio_id);
    if let Some(cached) = state.cache.get(&cache_key) {
        if let Ok(val) = serde_json::from_str::<Value>(&cached) {
            return Ok(Json(val));
        }
    }

    let projects = projects_repo::find_by_portfolio_id(&state.pool, portfolio_id).await?;
    let response = json!(projects);
    state.cache.set(cache_key, response.to_string());
    Ok(Json(response))
}

pub async fn get_project(
    State(state): State<AppState>,
    Path(id): Path<i64>,
) -> Result<Json<Value>, AppError> {
    let cache_key = keys::project_item(id);
    if let Some(cached) = state.cache.get(&cache_key) {
        if let Ok(val) = serde_json::from_str::<Value>(&cached) {
            return Ok(Json(val));
        }
    }

    let project = projects_repo::find_by_id(&state.pool, id)
        .await?
        .ok_or(AppError::NotFound)?;

    let response = json!(project);
    state.cache.set(cache_key, response.to_string());
    Ok(Json(response))
}

pub async fn post_project_view(
    State(state): State<AppState>,
    Path(id): Path<i64>,
) -> Result<Json<Value>, AppError> {
    projects_repo::increment_view_count(&state.pool, id).await?;
    state.cache.invalidate_prefix(keys::PROJECTS_PREFIX);
    Ok(Json(json!({"status": "ok"})))
}

pub async fn post_interested(
    State(state): State<AppState>,
    Path(id): Path<i64>,
) -> Result<Json<Value>, AppError> {
    projects_repo::increment_interested_count(&state.pool, id).await?;
    state.cache.invalidate_prefix(keys::PROJECTS_PREFIX);
    Ok(Json(json!({"status": "ok"})))
}
