CREATE UNIQUE INDEX IF NOT EXISTS idx_conversations_ama
    ON conversations(portfolio_id, participant_name);
