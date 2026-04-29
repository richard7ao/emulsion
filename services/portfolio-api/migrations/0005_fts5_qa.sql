CREATE VIRTUAL TABLE IF NOT EXISTS qa_pairs_fts USING fts5(
    prompt, answer,
    content='qa_pairs',
    content_rowid='id',
    tokenize='porter'
);

CREATE TRIGGER IF NOT EXISTS qa_pairs_fts_insert AFTER INSERT ON qa_pairs BEGIN
    INSERT INTO qa_pairs_fts(rowid, prompt, answer) VALUES (new.id, new.prompt, new.answer);
END;

CREATE TRIGGER IF NOT EXISTS qa_pairs_fts_delete AFTER DELETE ON qa_pairs BEGIN
    INSERT INTO qa_pairs_fts(qa_pairs_fts, rowid, prompt, answer) VALUES ('delete', old.id, old.prompt, old.answer);
END;
