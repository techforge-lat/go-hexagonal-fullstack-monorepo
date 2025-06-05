package localconfig

import (
	"fmt"
	"os"
	"strconv"

	"github.com/joho/godotenv"
)

type Config struct {
	Database DatabaseConfig
	HTTP     HTTPConfig
	JWT      JWTConfig
	Logger   LoggerConfig
}

type DatabaseConfig struct {
	Host     string
	Port     int
	User     string
	Password string
	DBName   string
	SSLMode  string
}

type HTTPConfig struct {
	Port int
}

type JWTConfig struct {
	Secret string
}

type LoggerConfig struct {
	Level     string
	Format    string
	AddSource bool
}

func LoadConfig() (*Config, error) {
	_ = godotenv.Load()

	config := &Config{}

	dbPort, err := strconv.Atoi(getEnv("DB_PORT", "5432"))
	if err != nil {
		return nil, fmt.Errorf("invalid DB_PORT: %w", err)
	}

	httpPort, err := strconv.Atoi(getEnv("HTTP_PORT", "8080"))
	if err != nil {
		return nil, fmt.Errorf("invalid HTTP_PORT: %w", err)
	}

	config.Database = DatabaseConfig{
		Host:     getEnv("DB_HOST", "localhost"),
		Port:     dbPort,
		User:     getEnv("DB_USER", "postgres"),
		Password: getEnv("DB_PASSWORD", ""),
		DBName:   getEnv("DB_NAME", "hexagonal_db"),
		SSLMode:  getEnv("DB_SSL_MODE", "disable"),
	}

	config.HTTP = HTTPConfig{
		Port: httpPort,
	}

	config.JWT = JWTConfig{
		Secret: getEnv("JWT_SECRET", ""),
	}

	config.Logger = LoggerConfig{
		Level:     getEnv("LOG_LEVEL", "info"),
		Format:    getEnv("LOG_FORMAT", "text"),
		AddSource: getEnv("LOG_ADD_SOURCE", "false") == "true",
	}

	if config.JWT.Secret == "" {
		return nil, fmt.Errorf("JWT_SECRET is required")
	}

	return config, nil
}

func getEnv(key, defaultValue string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return defaultValue
}
