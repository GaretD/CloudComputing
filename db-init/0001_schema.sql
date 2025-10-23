-- Creates example table for future dynamic pages
CREATE TABLE IF NOT EXISTS pages (
  id INT AUTO_INCREMENT PRIMARY KEY,
  slug VARCHAR(255) NOT NULL UNIQUE,
  title VARCHAR(255) NOT NULL,
  body MEDIUMTEXT NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO pages (slug, title, body) VALUES
('phase1', 'Phase 1', '<h1>Phase 1 (DB-backed)</h1><p>Hello from MariaDB!</p>')
ON DUPLICATE KEY UPDATE title=VALUES(title);
