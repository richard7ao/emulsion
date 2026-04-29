use axum::extract::State;
use axum::Json;
use serde_json::{json, Value};
use crate::app_state::AppState;
use crate::error::AppError;

pub async fn health(State(state): State<AppState>) -> Result<Json<Value>, AppError> {
    sqlx::query("SELECT 1")
        .execute(&state.pool)
        .await
        .map_err(|e| AppError::Internal(format!("database unreachable: {}", e)))?;

    Ok(Json(json!({"status": "ok", "db": "ok"})))
}
