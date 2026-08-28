"""
Axion Telemetry Query Service - Configuration
"""

import os
from dataclasses import dataclass

@dataclass
class Settings:
    # PostgreSQL connection string
    # Format: postgresql://<user>:<password>@<host>:<port>/<database>
    DATABASE_URL: str = os.getenv(
        "DATABASE_URL",
        "postgresql://postgres:root%40123@axiondatabase-service.default.svc.cluster.local:5432/axiondb",
    )
    # Allows configuring a different port, e.g., if we run multiple services
    PORT: int = int(os.getenv("PORT", "8000"))

settings = Settings()
