PROWLER = """
- Default to this table 'prowler' if no table is specified.
- 'PROWLER' or 'prowler' can be used to refer to this table.
- Columns in the 'prowler' table follow this following format:
    timestamp VARCHAR(20),
    id VARCHAR(100),
    title VARCHAR(255),
    type VARCHAR(50),
    status VARCHAR(20),
    status_detail TEXT,
    service VARCHAR(50),
    subservice VARCHAR(50),
    severity VARCHAR(20),
    resource VARCHAR(50),
    resource_id VARCHAR(255),
    resource_name VARCHAR(255),
    resource_details TEXT,
    resource_tags TEXT,
    region VARCHAR(50),
    description TEXT,
    risk TEXT,
    related_url TEXT,
    remediation_text TEXT,
    remediation_url TEXT,
    remediation_code_other TEXT,
    compliance TEXT,
    categories TEXT,
    depends_on TEXT,
    related_to TEXT,
    notes TEXT
"""