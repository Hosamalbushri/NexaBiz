from __future__ import annotations

import threading
import time


class SlidingWindowLimiter:
    """In-process sliding window limiter (per-process; fine behind one API replica)."""

    def __init__(self, max_requests: int, window_seconds: float = 60.0) -> None:
        self.max_requests = max_requests
        self.window_seconds = window_seconds
        self._hits: dict[str, list[float]] = {}
        self._lock = threading.Lock()

    def allow(self, key: str, max_requests: int | None = None) -> tuple[bool, int]:
        """Return (allowed, retry_after_seconds). ``max_requests <= 0`` disables."""
        limit = self.max_requests if max_requests is None else max_requests
        if limit <= 0:
            return True, 0
        now = time.monotonic()
        cutoff = now - self.window_seconds
        with self._lock:
            bucket = self._hits.setdefault(key, [])
            bucket[:] = [t for t in bucket if t > cutoff]
            if len(bucket) >= limit:
                oldest = bucket[0]
                retry = int(self.window_seconds - (now - oldest)) + 1
                return False, max(retry, 1)
            bucket.append(now)
            return True, 0

    def reset(self) -> None:
        with self._lock:
            self._hits.clear()
