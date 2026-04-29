use axum::extract::{Path, State};
use axum::http::StatusCode;
use axum::Json;
use serde_json::{json, Value};
use crate::app_state::AppState;
use crate::cache::keys;
use crate::repositories::projects_repo;

pub async fn list_projects(
    State(state): State<AppState>,
    Path(portfolio_id): Path<i64>,
) -> Result<Json<Value>, StatusCode> {
    let cache_key = keys::projects_list(portfolio_id);
    if let Some(cached) = state.cache.get(&cache_key) {
        let val: Value = serde_json::from_str(&cached).unwrap_or(Value::Null);
        return Ok(Json(val));
    }

    let projects = projects_repo::find_by_portfolio_id(&state.pool, portfolio_id)
        .await
        .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;

    let response = json!(projects);
    state.cache.set(cache_key, response.to_string());
    Ok(Json(response))
}

pub async fn get_project(
    State(state): State<AppState>,
    Path(id): Path<i64>,
) -> Result<Json<Value>, StatusCode> {
    let cache_key = keys::project_item(id);
    if let Some(cached) = state.cache.get(&cache_key) {
        let val: Value = serde_json::from_str(&cached).unwrap_or(Value::Null);
        return Ok(Json(val));
    }

    let project = projects_repo::find_by_id(&state.pool, id)
        .await
        .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?
        .ok_or(StatusCode::NOT_FOUND)?;

    let response = json!(project);
    state.cache.set(cache_key, response.to_string());
    Ok(Json(response))
}

pub async fn post_project_view(
    State(state): State<AppState>,
    Path(id): Path<i64>,
) -> Result<Json<Value>, StatusCode> {
    projects_repo::increment_view_count(&state.pool, id)
        .await
        .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;

    state.cache.invalidate_prefix(keys::PROJECTS_PREFIX);
    Ok(Json(json!({"status": "ok"})))
}

pub async fn post_interested(
    State(state): State<AppState>,
    Path(id): Path<i64>,
) -> Result<Json<Value>, StatusCode> {
    projects_repo::increment_interested_count(&state.pool, id)
        .await
        .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;

    state.cache.invalidate_prefix(keys::PROJECTS_PREFIX);
    Ok(Json(json!({"status": "ok"})))
}
