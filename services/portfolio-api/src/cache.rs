use dashmap::DashMap;
use std::sync::Arc;

pub mod keys {
    pub const PROJECTS_PREFIX: &str = "projects:";

    pub fn portfolio(id: i64) -> String {
        format!("portfolio:{}", id)
    }

    pub fn projects_list(portfolio_id: i64) -> String {
        format!("projects:list:{}", portfolio_id)
    }

    pub fn project_item(id: i64) -> String {
        format!("projects:item:{}", id)
    }
}

#[derive(Clone)]
pub struct AppCache {
    store: Arc<DashMap<String, String>>,
}

impl AppCache {
    pub fn new() -> Self {
        Self {
            store: Arc::new(DashMap::new()),
        }
    }

    pub fn get(&self, key: &str) -> Option<String> {
        self.store.get(key).map(|v| v.value().clone())
    }

    pub fn set(&self, key: String, value: String) {
        self.store.insert(key, value);
    }

    pub fn invalidate(&self, key: &str) {
        self.store.remove(key);
    }

    pub fn invalidate_prefix(&self, prefix: &str) {
        self.store.retain(|k, _| !k.starts_with(prefix));
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_cache_set_and_get() {
        let cache = AppCache::new();
        cache.set("portfolio:1".into(), "data".into());
        assert_eq!(cache.get("portfolio:1"), Some("data".into()));
    }

    #[test]
    fn test_cache_invalidate() {
        let cache = AppCache::new();
        cache.set("portfolio:1".into(), "data".into());
        cache.invalidate("portfolio:1");
        assert_eq!(cache.get("portfolio:1"), None);
    }

    #[test]
    fn test_cache_invalidate_prefix() {
        let cache = AppCache::new();
        cache.set("projects:1".into(), "a".into());
        cache.set("projects:2".into(), "b".into());
        cache.set("portfolio:1".into(), "c".into());
        cache.invalidate_prefix("projects:");
        assert_eq!(cache.get("projects:1"), None);
        assert_eq!(cache.get("projects:2"), None);
        assert_eq!(cache.get("portfolio:1"), Some("c".into()));
    }
}
