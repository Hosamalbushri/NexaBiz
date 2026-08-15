from __future__ import annotations

from typing import Any

from fastapi import status

from app.core.exceptions import AppError


class PermissionDeniedError(AppError):
    def __init__(
        self,
        message: str = "Permission denied",
        details: dict[str, Any] | None = None,
    ) -> None:
        super().__init__(
            code="permission_denied",
            message=message,
            status_code=status.HTTP_403_FORBIDDEN,
            details=details,
        )
