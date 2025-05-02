SECURITY_HUB= """
- Default to this table 'security_hub' if no table is specified another.
- 'SECURITY_HUB' or 'security_hub' can be used to refer to this table.
- Columns in the 'security_hub' table follow this following format:
    resource_id VARCHAR(255),
    title VARCHAR(255),
    description TEXT,
    timestamp DATETIME,
    severity VARCHAR(20),
    compliance_status VARCHAR(20),
    status VARCHAR(20),
    product VARCHAR(50),
    resource_type VARCHAR(100),
    arn VARCHAR(255),
    generator_id VARCHAR(100),
    finding_id VARCHAR(255),
    PRIMARY KEY (finding_id)
"""

PROWLER = """
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