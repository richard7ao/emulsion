use axum::body::{to_bytes, Body};
use axum::http::{Request, StatusCode};
use serde_json::Value;
use tower::ServiceExt;

use crate::app_state::AppState;
use crate::cache::AppCache;
use crate::routes::create_router;
use crate::test_utils::{seeded_test_pool, test_pool};

async fn router_with_seed() -> axum::Router {
    let pool = seeded_test_pool().await;
    let state = AppState { pool, cache: AppCache::new() };
    create_router(state)
}

async fn router_with_conversation() -> axum::Router {
    let pool = seeded_test_pool().await;
    sqlx::query("INSERT INTO conversations (id, portfolio_id, participant_name, last_message) VALUES (1, 1, 'Alex', 'Hello')")
        .execute(&pool).await.unwrap();
    sqlx::query("INSERT INTO messages (conversation_id, sender, body) VALUES (1, 'Alex', 'Hello')")
        .execute(&pool).await.unwrap();
    let state = AppState { pool, cache: AppCache::new() };
    create_router(state)
}

async fn router_empty() -> axum::Router {
    let pool = test_pool().await;
    let state = AppState { pool, cache: AppCache::new() };
    create_router(state)
}

async fn body_json(resp: axum::response::Response) -> Value {
    let bytes = to_bytes(resp.into_body(), 1024 * 1024).await.unwrap();
    serde_json::from_slice(&bytes).unwrap()
}

#[tokio::test]
async fn health_returns_ok() {
    let app = router_empty().await;
    let resp = app.oneshot(Request::builder().uri("/health").body(Body::empty()).unwrap())
        .await.unwrap();
    assert_eq!(resp.status(), StatusCode::OK);
    let json = body_json(resp).await;
    assert_eq!(json["status"], "ok");
    assert_eq!(json["db"], "ok");
}

#[tokio::test]
async fn portfolio_not_found_returns_404() {
    let app = router_empty().await;
    let resp = app.oneshot(Request::builder().uri("/v1/portfolios/999").body(Body::empty()).unwrap())
        .await.unwrap();
    assert_eq!(resp.status(), StatusCode::NOT_FOUND);
}

#[tokio::test]
async fn portfolio_returns_typed_response() {
    let app = router_with_seed().await;
    let resp = app.oneshot(Request::builder().uri("/v1/portfolios/1").body(Body::empty()).unwrap())
        .await.unwrap();
    assert_eq!(resp.status(), StatusCode::OK);
    let json = body_json(resp).await;
    assert_eq!(json["portfolio"]["name"], "Richard");
    assert!(json["experiences"].is_array());
    assert!(json["skills"].is_array());
}

#[tokio::test]
async fn note_with_empty_message_returns_400() {
    let app = router_with_seed().await;
    let body = serde_json::to_vec(&serde_json::json!({
        "name": "Alice",
        "message": ""
    })).unwrap();
    let resp = app.oneshot(
        Request::builder()
            .uri("/v1/portfolios/1/notes")
            .method("POST")
            .header("content-type", "application/json")
            .body(Body::from(body))
            .unwrap()
    ).await.unwrap();
    assert_eq!(resp.status(), StatusCode::BAD_REQUEST);
}

#[tokio::test]
async fn list_notes_without_owner_token_returns_401() {
    let app = router_with_seed().await;
    let resp = app.oneshot(Request::builder().uri("/v1/portfolios/1/notes").body(Body::empty()).unwrap())
        .await.unwrap();
    assert_eq!(resp.status(), StatusCode::UNAUTHORIZED);
}

#[tokio::test]
async fn not_found_returns_json_error_body() {
    let app = router_empty().await;
    let resp = app.oneshot(Request::builder().uri("/v1/portfolios/999").body(Body::empty()).unwrap())
        .await.unwrap();
    assert_eq!(resp.status(), StatusCode::NOT_FOUND);
    let json = body_json(resp).await;
    assert_eq!(json["error"], "not found");
}

#[tokio::test]
async fn bad_request_returns_json_error_body() {
    let app = router_with_seed().await;
    let body = serde_json::to_vec(&serde_json::json!({
        "name": "",
        "message": "hello"
    })).unwrap();
    let resp = app.oneshot(
        Request::builder()
            .uri("/v1/portfolios/1/notes")
            .method("POST")
            .header("content-type", "application/json")
            .body(Body::from(body))
            .unwrap()
    ).await.unwrap();
    assert_eq!(resp.status(), StatusCode::BAD_REQUEST);
    let json = body_json(resp).await;
    assert!(json["error"].as_str().unwrap().contains("required"));
}

#[tokio::test]
async fn delete_conversation_without_owner_token_returns_401() {
    let app = router_with_seed().await;
    let resp = app.oneshot(
        Request::builder()
            .uri("/v1/conversations/1")
            .method("DELETE")
            .body(Body::empty())
            .unwrap()
    ).await.unwrap();
    assert_eq!(resp.status(), StatusCode::UNAUTHORIZED);
}

#[tokio::test]
async fn delete_conversation_with_token_returns_ok() {
    let app = router_with_conversation().await;
    let resp = app.oneshot(
        Request::builder()
            .uri("/v1/conversations/1")
            .method("DELETE")
            .header("X-Owner-Token", "owner")
            .body(Body::empty())
            .unwrap()
    ).await.unwrap();
    assert_eq!(resp.status(), StatusCode::OK);
    let json = body_json(resp).await;
    assert_eq!(json["status"], "ok");
}

#[tokio::test]
async fn delete_nonexistent_conversation_returns_404() {
    let app = router_with_seed().await;
    let resp = app.oneshot(
        Request::builder()
            .uri("/v1/conversations/999")
            .method("DELETE")
            .header("X-Owner-Token", "owner")
            .body(Body::empty())
            .unwrap()
    ).await.unwrap();
    assert_eq!(resp.status(), StatusCode::NOT_FOUND);
}
