CREATE INDEX IF NOT EXISTS idx_experiences_portfolio_id ON experiences(portfolio_id);
CREATE INDEX IF NOT EXISTS idx_projects_portfolio_id ON projects(portfolio_id);
CREATE INDEX IF NOT EXISTS idx_skills_portfolio_id ON skills(portfolio_id);
CREATE INDEX IF NOT EXISTS idx_qa_pairs_portfolio_id ON qa_pairs(portfolio_id);
CREATE INDEX IF NOT EXISTS idx_notes_portfolio_id ON notes(portfolio_id);
CREATE INDEX IF NOT EXISTS idx_conversations_portfolio_id ON conversations(portfolio_id);
-- Composite (conversation_id, created_at) supports both equality lookup
-- and the ORDER BY created_at scan. No separate single-column index needed.
CREATE INDEX IF NOT EXISTS idx_messages_conversation_created ON messages(conversation_id, created_at);
