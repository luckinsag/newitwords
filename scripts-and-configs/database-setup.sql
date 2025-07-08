-- IT Words Learning 数据库初始化脚本
-- 连接到RDS MySQL实例后执行此脚本

-- 创建数据库
CREATE DATABASE IF NOT EXISTS mysql_itwordslearning 
CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- 使用数据库
USE mysql_itwordslearning;

-- 创建用户表
CREATE TABLE IF NOT EXISTS users (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    email VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_username (username)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 创建单词表
CREATE TABLE IF NOT EXISTS words (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    word VARCHAR(100) NOT NULL,
    pronunciation VARCHAR(200),
    meaning TEXT,
    example_sentence TEXT,
    category VARCHAR(50),
    difficulty_level INT DEFAULT 1,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_word (word),
    INDEX idx_category (category)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 创建用户笔记表
CREATE TABLE IF NOT EXISTS user_notes (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT NOT NULL,
    word_id BIGINT NOT NULL,
    memo TEXT,
    is_important BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (word_id) REFERENCES words(id) ON DELETE CASCADE,
    UNIQUE KEY uk_user_word (user_id, word_id),
    INDEX idx_user_important (user_id, is_important)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 创建用户设置表
CREATE TABLE IF NOT EXISTS user_settings (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT NOT NULL,
    setting_key VARCHAR(50) NOT NULL,
    setting_value TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    UNIQUE KEY uk_user_setting (user_id, setting_key)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 创建测试会话表
CREATE TABLE IF NOT EXISTS user_test_sessions (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT NOT NULL,
    session_name VARCHAR(100),
    start_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    end_time TIMESTAMP NULL,
    total_questions INT DEFAULT 0,
    correct_answers INT DEFAULT 0,
    score DECIMAL(5,2) DEFAULT 0.00,
    status VARCHAR(20) DEFAULT 'IN_PROGRESS',
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_user_session (user_id, start_time)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 创建用户测试记录表
CREATE TABLE IF NOT EXISTS user_tests (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT NOT NULL,
    session_id BIGINT,
    end_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    score DECIMAL(5,2) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (session_id) REFERENCES user_test_sessions(id) ON DELETE SET NULL,
    INDEX idx_user_test_time (user_id, end_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 创建错题表
CREATE TABLE IF NOT EXISTS user_wrong_words (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT NOT NULL,
    word_id BIGINT NOT NULL,
    session_id BIGINT,
    wrong_count INT DEFAULT 1,
    last_wrong_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (word_id) REFERENCES words(id) ON DELETE CASCADE,
    FOREIGN KEY (session_id) REFERENCES user_test_sessions(id) ON DELETE SET NULL,
    UNIQUE KEY uk_user_word_wrong (user_id, word_id),
    INDEX idx_user_wrong_time (user_id, last_wrong_time)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 插入示例数据（可选）
-- 插入示例用户（密码需要加密）
INSERT INTO users (username, password, email) VALUES 
('demo_user', '$2a$10$example_encrypted_password', 'demo@example.com')
ON DUPLICATE KEY UPDATE username=username;

-- 插入示例单词数据
INSERT INTO words (word, pronunciation, meaning, example_sentence, category, difficulty_level) VALUES
('algorithm', '/ˈælɡərɪðəm/', '算法', 'The sorting algorithm is very efficient.', 'Lesson 1', 1),
('database', '/ˈdeɪtəbeɪs/', '数据库', 'We store all user information in the database.', 'Lesson 1', 1),
('framework', '/ˈfreɪmwɜːrk/', '框架', 'Vue.js is a popular JavaScript framework.', 'Lesson 1', 2),
('deployment', '/dɪˈplɔɪmənt/', '部署', 'The deployment process went smoothly.', 'Lesson 2', 2),
('authentication', '/ɔːˌθentɪˈkeɪʃn/', '认证', 'User authentication is required for this feature.', 'Lesson 2', 3)
ON DUPLICATE KEY UPDATE word=VALUES(word);

-- 创建数据库视图（用于统计）
CREATE OR REPLACE VIEW user_statistics AS
SELECT 
    u.id as user_id,
    u.username,
    COUNT(DISTINCT un.id) as total_notes,
    COUNT(DISTINCT CASE WHEN un.is_important = TRUE THEN un.id END) as important_words,
    COUNT(DISTINCT ut.id) as total_tests,
    IFNULL(AVG(ut.score), 0) as average_score,
    COUNT(DISTINCT uw.id) as wrong_words_count
FROM users u
LEFT JOIN user_notes un ON u.id = un.user_id
LEFT JOIN user_tests ut ON u.id = ut.user_id
LEFT JOIN user_wrong_words uw ON u.id = uw.user_id
GROUP BY u.id, u.username;

-- 创建索引优化查询性能
CREATE INDEX idx_words_category_difficulty ON words(category, difficulty_level);
CREATE INDEX idx_user_notes_important ON user_notes(user_id, is_important, updated_at);
CREATE INDEX idx_user_tests_score ON user_tests(user_id, score, end_at);

-- 显示表结构（用于验证）
SHOW TABLES;

-- 显示统计信息
SELECT 
    TABLE_NAME,
    TABLE_ROWS,
    DATA_LENGTH,
    INDEX_LENGTH
FROM information_schema.TABLES 
WHERE TABLE_SCHEMA = 'mysql_itwordslearning'
ORDER BY TABLE_NAME; 