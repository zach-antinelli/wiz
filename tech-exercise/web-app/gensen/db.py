import mysql.connector


class MySQLDB:
    """MySQL database connection and handler."""

    def __init__(
        self,
        config,
        ssl_disabled: bool = True,
    ) -> None:
        """Initialize environment variables for DB connection."""
        self.logger = config.logger
        self.host = config.mysql_host
        self.user = config.mysql_user
        self.password = config.mysql_pw
        self.database = config.mysql_db
        self.ssl_disabled = ssl_disabled
        self.connection = None

    def connect(self) -> None:
        """Establish database connection."""
        try:
            self.connection = mysql.connector.connect(
                host=self.host,
                user=self.user,
                password=self.password,
                database=self.database,
                ssl_disabled=self.ssl_disabled,
                connection_timeout=10,
            )
        except mysql.connector.Error as e:
            self.logger.error(f"Database connection error: {e}")
            self.connection = None
            raise

    def disconnect(self) -> None:
        """Close database connection."""
        if self.connection and self.connection.is_connected():
            self.connection.close()

    def execute_query(self, query: str, params: tuple | None = None) -> list[dict]:
        """Execute a SQL query and return results."""
        cursor = None
        try:
            if not self.connection or not self.connection.is_connected():
                try:
                    self.connect()
                except Exception as e:
                    msg = f"Failed to connect to database: {e}"
                    self.logger.error(msg)
                    return [{"error": msg}]

            self.logger.info("Connected to database: %s", self.database)
            cursor = self.connection.cursor(dictionary=True)

            self.logger.info("Executing query: %s", query)
            cursor.execute(query, params)

            if cursor.description:
                results = cursor.fetchall()
                return results

            self.connection.commit()
            return [{"affected_rows": cursor.rowcount}]
        except Exception as e:
            self.logger.error(f"Database error: {e}")
            return [{"error": str(e)}]
        finally:
            if cursor:
                cursor.close()
