mod db;
mod models;
mod repositories;

use axum::{routing::get, Json, Router};
use serde_json::{json, Value};
use tokio::net::TcpListener;

async fn health() -> Json<Value> {
    Json(json!({"status": "ok"}))
}

#[tokio::main]
async fn main() {
    let _pool = db::init_pool().await;

    let app = Router::new().route("/health", get(health));
    let listener = TcpListener::bind("0.0.0.0:8080").await.unwrap();
    println!("listening on http://0.0.0.0:8080");
    axum::serve(listener, app).await.unwrap();
}
