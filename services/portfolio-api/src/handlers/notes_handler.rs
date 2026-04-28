use axum::extract::{Path, State};
use axum::http::{HeaderMap, StatusCode};
use axum::Json;
use serde_json::{json, Value};
use crate::app_state::AppState;
use crate::models::CreateNote;
use crate::repositories::notes_repo;

pub async fn create_note(
    State(state): State<AppState>,
    Path(portfolio_id): Path<i64>,
    Json(body): Json<CreateNote>,
) -> Result<(StatusCode, Json<Value>), StatusCode> {
    if body.name.trim().is_empty() || body.email.trim().is_empty() || body.message.trim().is_empty() {
        return Err(StatusCode::BAD_REQUEST);
    }

    let id = notes_repo::create(&state.pool, portfolio_id, &body)
        .await
        .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;

    Ok((StatusCode::CREATED, Json(json!({"id": id}))))
}

pub async fn list_notes(
    State(state): State<AppState>,
    Path(portfolio_id): Path<i64>,
    headers: HeaderMap,
) -> Result<Json<Value>, StatusCode> {
    if headers.get("X-Owner-Token").is_none() {
        return Err(StatusCode::UNAUTHORIZED);
    }

    let notes = notes_repo::find_by_portfolio_id(&state.pool, portfolio_id)
        .await
        .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;

    Ok(Json(json!(notes)))
}
