"""Read only one public-video guest row from an ignored local DB copy."""

import json
import sqlite3
import sys


def main():
    database, video, part = sys.argv[1:]
    with sqlite3.connect(database) as connection:
        row = connection.execute(
            "SELECT position_ms, duration_ms FROM watch_progress_rows "
            "WHERE owner_key = ? AND video_id = ? AND part_id = ?",
            ("guest", video, part),
        ).fetchone()
    print(json.dumps({"found": row is not None, **(
        {"positionMs": row[0], "durationMs": row[1]} if row else {}
    )}))


if __name__ == "__main__":
    main()
