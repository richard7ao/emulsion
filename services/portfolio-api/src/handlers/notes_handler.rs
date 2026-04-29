use axum::extract::{Path, State};
use axum::http::{HeaderMap, StatusCode};
use axum::Json;
use serde_json::{json, Value};
use crate::app_state::AppState;
use crate::error::AppError;
use crate::models::CreateNote;
use crate::repositories::{notes_repo, conversations_repo};

pub async fn create_note(
    State(state): State<AppState>,
    Path(portfolio_id): Path<i64>,
    Json(body): Json<CreateNote>,
) -> Result<(StatusCode, Json<Value>), AppError> {
    if body.name.trim().is_empty() || body.message.trim().is_empty() {
        return Err(AppError::BadRequest("name and message are required".into()));
    }

    let id = notes_repo::create(&state.pool, portfolio_id, &body).await?;

    conversations_repo::create_from_note(&state.pool, portfolio_id, &body.name, &body.message)
        .await?;

    Ok((StatusCode::CREATED, Json(json!({"id": id}))))
}

pub async fn list_notes(
    State(state): State<AppState>,
    Path(portfolio_id): Path<i64>,
    headers: HeaderMap,
) -> Result<Json<Value>, AppError> {
    if headers.get("X-Owner-Token").is_none() {
        return Err(AppError::Unauthorized);
    }

    let notes = notes_repo::find_by_portfolio_id(&state.pool, portfolio_id).await?;
    Ok(Json(json!(notes)))
}
